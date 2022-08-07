package cityPlus;

import java.lang.Math;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.schedule.ScheduledMethod;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.graph.Network;
import repast.simphony.space.graph.RepastEdge;

import tech.tablesaw.api.Table;

public abstract class Human {
	public static final double LAMBDA_INTERCEPT1 = -2.44270757;
	public static final double LAMBDA_DIFF_TIME1 = 0.08501263;
	public static final double LAMBDA_FUEL1 = -1.00067979;
	public static final double LAMBDA_CONGESTION1 = -0.06351866;
	public static final double LAMBDA_PARKING1_O = 0;
	public static final double LAMBDA_PARKING1_D = -0.13706262;

	public static final double LAMBDA_INTERCEPT2 = 0.25066461;
	public static final double LAMBDA_DIFF_TIME2 = 0.00278822;
	public static final double LAMBDA_FUEL2 = 0.44501964;
	public static final double LAMBDA_CONGESTION2 = -0.09880226;
	public static final double LAMBDA_PARKING2_O = 0;
	public static final double LAMBDA_PARKING2_D = -0.22318002;

	public static enum UpdateMemoryOption {
		FIRST_TIME, WARMUP, USUAL
	}

	public static enum ChooseModeOption {
		WARMUP, USUAL
	}

	public static final boolean IS_SHOW_NEW_DESTINATION = false;
	public static final boolean IS_SHOW_FRIEND_CHANGE = false;
	public static final boolean IS_SHOW_MIGRATION_DETAILS = false;

	public static final int SHOW_INTERVAL = 50000;

	public static final int MAX_TIME_TO_FIND_FRIEND = 10000;

	public static final double UPDATE_MEMORY_FREQUENCY_WARMUP = 1.0d / 2; // Every 2 months.
	public static final double CHOOSE_MODE_FREQUENCY_WARMUP = 1.0d / 2; // Every 2 months.

	public static final double UPDATE_MEMORY_FREQUENCY_USUAL = 1.0d / 12; // Every 12 months.
	public static final double CHOOSE_MODE_FREQUENCY_USUAL = 1.0d / 12; // Every 12 months.

	static double WEIGHT_EA;
	static double WEIGHT_SN;
	static double WEIGHT_BC;
	static double WEIGHT_SN_ORIG;

	int id;

	String typeId;

	Worldview worldview;

	Zone orig;
	Zone dest;

	double reduceCarTravel;

	Memory memory;

	double score_EA;
	double score_SN;
	double score_BC;

	Network<Object> network_O;
	Network<Object> network_D;

	List<SocialNetworkEdgeOrig> links_O;
	List<SocialNetworkEdgeDest> links_D;

	boolean isDriving = false; // Actually there is no need to initialize it.
	boolean isMigrant = false;
	boolean isPolicyInfluenced = false;

	double migrationTime;

	Human(int id, String typeId, Worldview worldview, Zone orig, Zone dest, double reduceCarTravel) {
		this.id = id;

		this.typeId = typeId;

		if ((worldview == Worldview.EGALITARIAN) || (worldview == Worldview.HIERARCHIST)
				|| (worldview == Worldview.INDIVIDUALIST))
			this.worldview = worldview;
		else
			throw new IllegalArgumentException("Invalid value of worldview.");

		this.orig = orig;
		this.dest = dest;

		this.reduceCarTravel = reduceCarTravel;

		memory = new Memory(this);

		// Both limits are exclusive.
		score_EA = RandomHelper.nextDoubleFromTo((reduceCarTravel - 1) / 5, reduceCarTravel / 5);

		// Assertion.
		if ((score_EA < 0) || (score_EA > 1))
			throw new IllegalStateException("Invalid value of environmental attitude.");

		// Sensitivity analysis.
		if (CityBuilder.IS_SENSITIVITY_ANALYSIS_MODE && (CityBuilder.SENSITIVITY_ANALYSIS_TYPE == 2)) {
			score_EA = score_EA * (1 + CityBuilder.SENSITIVITY_CHANGE_EA);

			if (score_EA < 0)
				score_EA = 0;
			else if (score_EA > 1)
				score_EA = 1;

			// Assertion.
			if ((score_EA < 0) || (score_EA > 1))
				throw new IllegalStateException("Invalid value of environmental attitude.");
		}

		links_O = new ArrayList<SocialNetworkEdgeOrig>();
		links_D = new ArrayList<SocialNetworkEdgeDest>();
	}

	public String toString() {
		return String.valueOf(id);
	}

	public void setNetworks(Network<Object> network_O, Network<Object> network_D) {
		this.network_O = network_O;

		this.network_D = network_D;
	}

//	@Parameter(usageName = "worldview", displayName = "Worldview", converter = "WorldviewConverter")
	public Worldview getWorldview() {
		return worldview;
	}

	public String getWorldviewStr() {
		return worldview.toString();
	}

	public int getId() {
		return id;
	}

	public String getTypeId() {
		return typeId;
	}

	public String getOrigIdName() {
		return orig.getIdName();
	}

	public String getDestIdName() {
		return dest.getIdName();
	}

	public double getEA() {
		return score_EA;
	}

	public double getSN() {
		return score_SN;
	}

	public double getBC() {
		return score_BC;
	}

//	score_SN and memory.getScoreFriendsPublic() does not have to be consistent because of chooseMode().
	public String getModeChoiceDetails() {
		return CityBuilder.DF.format(score_EA) + ", " + CityBuilder.DF.format(score_SN) + ", "
				+ CityBuilder.DF.format(score_BC) + " Mem: (" + CityBuilder.DF.format(memory.calculateSN()) + ")" + " ("
				+ CityBuilder.DF.format(memory.weightSN_O) + ", " + CityBuilder.DF.format(memory.weightSN_D) + ") "
				+ CityBuilder.DF.format(memory.numFriendsPublic_O) + "/"
				+ CityBuilder.DF.format(memory.numFriendsValid_O) + ", "
				+ CityBuilder.DF.format(memory.numFriendsPublic_D) + "/"
				+ CityBuilder.DF.format(memory.numFriendsValid_D);
	}

	public String getMemoryDetails_O() {
		return memory.getDetails_O();
	}

	public String getMemoryDetails_D() {
		return memory.getDetails_D();
	}

	public String getFriendsDetails_O() {
		String str = "Orig (" + links_O.size() + "):";

		for (SocialNetworkEdge link : links_O) {
			Human f = (Human) (link.getTarget());

			str = str + " " + f.getId() + " (" + f.getOrig() + ", " + f.getDest() + ")";
		}

		return str;
	}

	public String getFriendsDetails_D() {
		String str = "Dest (" + links_D.size() + "):";

		for (SocialNetworkEdge link : links_D) {
			Human f = (Human) (link.getTarget());

			str = str + " " + f.getId() + " (" + f.getOrig() + ", " + f.getDest() + ")";
		}

		return str;
	}

	public void updateMemory(UpdateMemoryOption option) {
		if (getDegree_O() == 0)
			throw new IllegalStateException("updateMemory(): " + id + " has no friends at the origin.");

		if (getDegree_D() == 0)
			throw new IllegalStateException("updateMemory(): " + id + " has no friends at the destination.");

		double ump = 0; // Update memory period.

		if (option == UpdateMemoryOption.WARMUP)
			ump = UPDATE_MEMORY_FREQUENCY_WARMUP;
		else if (option == UpdateMemoryOption.USUAL)
			ump = UPDATE_MEMORY_FREQUENCY_USUAL;

		if ((option != UpdateMemoryOption.FIRST_TIME) && (RandomHelper.nextDoubleFromTo(0, 1) > ump))
			return;

		if (option != UpdateMemoryOption.FIRST_TIME) {
			final int numProbing = 1;

			for (int i = 0; i < numProbing; ++i) {
				int fi = getRandomFriendIndex(true); // Maybe probe the same friend.

				Human f = getFriendByIndex(fi, true);

				SocialNetworkEdge link = getLinkByIndex(fi, true);

//				if (id % SHOW_INTERVAL == 0) {
//					System.out.println(id + ": " + link.getSource());
//					System.out.println(id + ": " + link.getTarget());
//				}

//				Too slow.
//				Human f = network_O.getRandomSuccessor(this);
//				SocialNetworkEdge link = (SocialNetworkEdge) (network_O.getEdge(this, f));

				if (f.getDriving())
					link.setModeChoice(ModeChoice.CAR);
				else
					link.setModeChoice(ModeChoice.PUBLIC);

				fi = getRandomFriendIndex(false); // Maybe probe the same friend.

				f = getFriendByIndex(fi, false);

				link = getLinkByIndex(fi, false);

//				Too slow.
//				f = network_D.getRandomSuccessor(this);
//				link = (SocialNetworkEdge) (network_D.getEdge(this, f));

				if (f.getDriving())
					link.setModeChoice(ModeChoice.CAR);
				else
					link.setModeChoice(ModeChoice.PUBLIC);
			}
		} else {
			for (int i = 0; i < getDegree_O(); ++i) {
				Human f = getFriendByIndex(i, true);

				SocialNetworkEdge link = getLinkByIndex(i, true);

				if (f.getDriving())
					link.setModeChoice(ModeChoice.CAR);
				else
					link.setModeChoice(ModeChoice.PUBLIC);
			}

			for (int i = 0; i < getDegree_D(); ++i) {
				Human f = getFriendByIndex(i, false);

				SocialNetworkEdge link = getLinkByIndex(i, false);

				if (f.getDriving())
					link.setModeChoice(ModeChoice.CAR);
				else
					link.setModeChoice(ModeChoice.PUBLIC);
			}
		}

		memory.refresh();
	}

	public void addFriend(Human f, boolean isOrigin) {
		// Assertion.
		if (hasFriendAlready(f, isOrigin))
			throw new IllegalArgumentException("Trying to add an exisiting friend.");

		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		if (isOrigin) {
			SocialNetworkEdgeOrig link = (SocialNetworkEdgeOrig) (network_O
					.addEdge(new SocialNetworkEdgeOrig(this, f, ModeChoice.NA)));

			links_O.add(link);

			if ((Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0)) || (Human.IS_SHOW_MIGRATION_DETAILS
					&& (tick >= CityBuilder.MIGRATION_START_TIME) && (tick <= CityBuilder.MIGRATION_END_TIME))) {
				System.out.print("\nS = " + link.getSource());
				System.out.print(", T = " + link.getTarget() + " ");
				System.out.print(network_O.getEdge(this, f) + " / ");
				System.out.println(network_O.getEdge(f, this));
			}

			link = (SocialNetworkEdgeOrig) (network_O.addEdge(new SocialNetworkEdgeOrig(f, this, ModeChoice.NA)));

			f.links_O.add(link);

			if ((Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0)) || (Human.IS_SHOW_MIGRATION_DETAILS
					&& (tick >= CityBuilder.MIGRATION_START_TIME) && (tick <= CityBuilder.MIGRATION_END_TIME))) {
				System.out.print("S = " + link.getSource());
				System.out.print(", T = " + link.getTarget() + " ");
				System.out.print(network_O.getEdge(this, f) + " / ");
				System.out.println(network_O.getEdge(f, this));
			}
		} else {
			SocialNetworkEdgeDest link = (SocialNetworkEdgeDest) (network_D
					.addEdge(new SocialNetworkEdgeDest(this, f, ModeChoice.NA)));

			links_D.add(link);

			if ((Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0)) || (Human.IS_SHOW_MIGRATION_DETAILS
					&& (tick >= CityBuilder.MIGRATION_START_TIME) && (tick <= CityBuilder.MIGRATION_END_TIME))) {
				System.out.print("\nS = " + link.getSource());
				System.out.print(", T = " + link.getTarget() + " ");
				System.out.print(network_D.getEdge(this, f) + " / ");
				System.out.println(network_D.getEdge(f, this));
			}

			link = (SocialNetworkEdgeDest) (network_D.addEdge(new SocialNetworkEdgeDest(f, this, ModeChoice.NA)));

			f.links_D.add(link);

			if ((Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0)) || (Human.IS_SHOW_MIGRATION_DETAILS
					&& (tick >= CityBuilder.MIGRATION_START_TIME) && (tick <= CityBuilder.MIGRATION_END_TIME))) {
				System.out.print("S = " + link.getSource());
				System.out.print(", T = " + link.getTarget() + " ");
				System.out.print(network_D.getEdge(this, f) + " / ");
				System.out.println(network_D.getEdge(f, this));
			}
		}

		if ((Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0)) || (Human.IS_SHOW_MIGRATION_DETAILS
				&& (tick >= CityBuilder.MIGRATION_START_TIME) && (tick <= CityBuilder.MIGRATION_END_TIME))) {
			System.out.println(id + " (" + orig + ", " + dest + ") adds a friend: " + f.getId() + " (" + f.getOrig()
					+ ", " + f.getDest() + ") isOrigin: " + isOrigin + ".");

			if (isOrigin)
				System.out.println(getFriendsDetails_O());
			else
				System.out.println(getFriendsDetails_D());

			System.out.println(f.getId() + " (" + f.getOrig() + ", " + f.getDest() + ") reversely adds a friend: " + id
					+ " (" + orig + ", " + dest + ") isOrigin: " + isOrigin + ".");

			if (isOrigin)
				System.out.println(f.getFriendsDetails_O());
			else
				System.out.println(f.getFriendsDetails_D());
		}
	}

//	Make (CityBuilder.NUM_ZONAL_FRIENDS / 2) friends at first and wait for others to make friends.
//	This function works well if numResidents_O and numResidents_D are much bigger than CityBuilder.NUM_ZONAL_FRIENDS.
	public void makeFriends() {
		if (!Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0))
			System.out.print(id + ":");

		int numResidents_O = orig.getNumResidents();

		if ((numResidents_O - 1) < CityBuilder.NUM_ZONAL_FRIENDS)
			throw new IllegalStateException("Residents at " + orig.getId() + " are too few (" + numResidents_O + ").");

		int numFriends = 0;

		if (CityBuilder.NUM_ZONAL_FRIENDS == 1)
			numFriends = 1;
		else if (CityBuilder.NUM_ZONAL_FRIENDS > 1)
			numFriends = CityBuilder.NUM_ZONAL_FRIENDS / 2;
		else
			throw new IllegalArgumentException("Invalid value of CityBuilder.NUM_ZONAL_FRIENDS.");

		if (numResidents_O > 1) {
			for (int i = 0; i < numFriends; ++i) {
				Human f = null;

				int count = 0;

				do {
					++count;

					/*
					 * There are only 3 people, and (CityBuilder.NUM_ZONAL_FRIENDS / 2) == 1. 1
					 * links with 3, and 2 also links with 3. Then, 3 cannot have new friends
					 * anymore.
					 */
					if (count > MAX_TIME_TO_FIND_FRIEND)
						throw new IllegalStateException("Cannot find a new origin friend within a given time ("
								+ getId() + ": " + orig.getName() + ": " + orig.getNumResidents() + ").");

					int rn = RandomHelper.nextIntFromTo(0, numResidents_O - 1);

					f = orig.getResidents().get(rn);
				} while ((f == this) || hasFriendAlready(f, true));
				// } while ((f.getId() == id) || hasFriendAlready(f, true));
				// Note: Don't write: (rn == id).

				addFriend(f, true);

//				if (orig.getName().equals("City of London"))
//					System.out.println(getId() + ": " + getFriendsDetails_O());

				if (!Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0))
					System.out.print(" " + f.getId());
			}
		}

		if (!Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0))
			System.out.print(" |");

		int numWorkers_D = dest.getNumWorkers();

		if ((numWorkers_D - 1) < CityBuilder.NUM_ZONAL_FRIENDS)
			throw new IllegalStateException("Workers at " + dest.getId() + " are too few (" + numWorkers_D + ").");

		if (numWorkers_D > 1) {
			for (int i = 0; i < numFriends; ++i) {
				Human f = null;

				int count = 0;

				do {
					++count;

					if (count > MAX_TIME_TO_FIND_FRIEND)
						throw new IllegalStateException("Cannot find a new destintion friend within a given time ("
								+ getId() + ": " + dest.getName() + ": " + dest.getNumWorkers() + ").");

					int rn = RandomHelper.nextIntFromTo(0, numWorkers_D - 1);

					f = dest.getWorkers().get(rn);
				} while ((f == this) || hasFriendAlready(f, false));
				// } while ((f.getId() == id) || hasFriendAlready(f, false));

				addFriend(f, false);

				if (!Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0))
					System.out.print(" " + f.getId());
			}
		}

		if (!Human.IS_SHOW_FRIEND_CHANGE && (id % SHOW_INTERVAL == 0))
			System.out.print("\n");
	}

	public boolean hasFriendAlready(Human friend, boolean isOrigin) {
		if (isOrigin) {
			if (network_O.isAdjacent(this, friend)) // Regardless of edge directionality.
				return true;
		} else {
			if (network_D.isAdjacent(this, friend)) // Regardless of edge directionality.
				return true;
		}

		return false;
	}

	public void changeEA() {
		if (RandomHelper.nextDoubleFromTo(0, 1) > CityBuilder.ENV_ATTITUDE_CHANGE_FREQUENCY)
			return;

//		score_EA += CityBuilder.ENV_ATTITUDE_CHANGE;

		score_EA = score_EA * (1 + CityBuilder.ENV_ATTITUDE_CHANGE);

		if (score_EA < 0)
			score_EA = 0;
		else if (score_EA > 1)
			score_EA = 1;

		// Assertion.
		if ((score_EA < 0) || (score_EA > 1))
			throw new IllegalStateException("Invalid value of environmental attitude.");
	}

	@ScheduledMethod(start = CityBuilder.WARMUP_PRE_START_TIME, interval = 1, shuffle = true, priority = CityBuilder.PRIORITY_HUMAN)
	public void step() {
		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		// Assertion.
		if (tick < CityBuilder.WARMUP_PRE_START_TIME) // Tick < 2. (This line can be dropped.)
			throw new IllegalStateException("Tick error.");

		// Assertion.
		checkLinkIntegrity();

		if ((CityBuilder.ENV_ATTITUDE_CHANGE != 0) && (tick >= CityBuilder.ENV_ATTITUDE_CHANGE_START_TIME)
				&& (tick <= CityBuilder.ENV_ATTITUDE_CHANGE_END_TIME))
			changeEA();

//		if ((tick == CityBuilder.POLICY_START_TIME)
//				&& ((CityBuilder.PUBLIC_TRANSPORT_TIME_CHANGE != 0) || (CityBuilder.DEST_PARKING_CHARGE_CHANGE != 0)))
//			updateBC();

		// The first time to call updateMemory() is fixed (tick == 2).
		if (tick == CityBuilder.WARMUP_PRE_START_TIME)
			updateMemory(UpdateMemoryOption.FIRST_TIME);
		else if (tick <= CityBuilder.WARMUP_END_TIME)
			updateMemory(UpdateMemoryOption.WARMUP);
		else
			updateMemory(UpdateMemoryOption.USUAL);

		// The first time to call chooseMode() is random (tick >= 3).
		if (tick >= CityBuilder.WARMUP_START_TIME) // Choose mode in the warm-up stage or later.
		{
			if (tick <= CityBuilder.WARMUP_END_TIME)
				chooseMode(ChooseModeOption.WARMUP);
			else
				chooseMode(ChooseModeOption.USUAL);
		}

		// Assertion.
		if ((tick % 50) == 0)
			checkLinkConsistency();
	}

	public void checkLinkIntegrity() {
		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		if (getDegree_O() < (CityBuilder.NUM_ZONAL_FRIENDS / 2))
			throw new IllegalStateException(tick + ": " + id + ": Network links at the origin are too few.");

		if (getDegree_D() < (CityBuilder.NUM_ZONAL_FRIENDS / 2))
			throw new IllegalStateException(tick + ": " + id + ": Network links at the destination are too few.");
	}

	public void checkLinkConsistency() {
		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		// Check if locally saved out-edges align with the edges in the global network.
		if (!getLinksStr_O().equals(getOutEdgesStr_O()))
			throw new IllegalStateException(tick + ": " + id + ": Network links are inconsistent at the origin.");

		if (!getLinksStr_D().equals(getOutEdgesStr_D()))
			throw new IllegalStateException(tick + ": " + id + ": Network links are inconsistent at the destination.");

		String strOut = "[";
		String strIn = "[";

		Iterator<RepastEdge<Object>> iterOut = network_O.getOutEdges(this).iterator();
		Iterator<RepastEdge<Object>> iterIn = network_O.getInEdges(this).iterator();

		// Check if out-nodes are the same as in-nodes globally.
		while (iterOut.hasNext()) {
			strOut += iterOut.next().getTarget(); // This will call Human.toString().

			if (iterOut.hasNext())
				strOut += ", ";
		}

		while (iterIn.hasNext()) {
			strIn += iterIn.next().getSource();

			if (iterIn.hasNext())
				strIn += ", ";
		}

		strOut += "]";
		strIn += "]";

//		if (id % SHOW_INTERVAL == 0) {
//			System.out.println(id + ": out nodes at orig: " + strOut);
//			System.out.println(id + ": in nodes at orig: " + strIn);
//		}

		if (!strOut.equals(strIn))
			throw new IllegalStateException(tick + ": " + id + ": Out and in links are inconsistent at the origin.");

		strOut = "[";
		strIn = "[";

		iterOut = network_D.getOutEdges(this).iterator();
		iterIn = network_D.getInEdges(this).iterator();

		// Check if out-nodes are the same as in-nodes globally.
		while (iterOut.hasNext()) {
			strOut += iterOut.next().getTarget();

			if (iterOut.hasNext())
				strOut += ", ";
		}

		while (iterIn.hasNext()) {
			strIn += iterIn.next().getSource();

			if (iterIn.hasNext())
				strIn += ", ";
		}

		strOut += "]";
		strIn += "]";

//		if (id % SHOW_INTERVAL == 0) {
//			System.out.println(id + ": out nodes at dest: " + strOut);
//			System.out.println(id + ": in nodes at dest: " + strIn);
//		}

		if (!strOut.equals(strIn))
			throw new IllegalStateException(
					tick + ": " + id + ": Out and in links are inconsistent at the destination.");
	}

	public Zone getOrig() {
		return orig;
	}

	public void setOrig(Zone zone) {
		orig = zone;
	}

	public Zone getDest() {
		return dest;
	}

	public void setDest(Zone zone) {
		dest = zone;
	}

	public String getOrigId() {
		return orig.getId();
	}

	public String getDestId() {
		return dest.getId();
	}

	public void updateSN() {
		score_SN = memory.calculateSN();

		// Assertion.
		if (Double.isInfinite(score_SN) || Double.isNaN(score_SN) || (score_SN < 0) || (score_SN > 1))
			throw new IllegalStateException("Invalid value of social norm.");

		// Sensitivity analysis.
		if (CityBuilder.IS_SENSITIVITY_ANALYSIS_MODE && (CityBuilder.SENSITIVITY_ANALYSIS_TYPE == 2)) {
			score_SN = score_SN * (1 + CityBuilder.SENSITIVITY_CHANGE_SN);

			if (score_SN < 0)
				score_SN = 0;
			else if (score_SN > 1)
				score_SN = 1;

			// Assertion.
			if (Double.isInfinite(score_SN) || Double.isNaN(score_SN) || (score_SN < 0) || (score_SN > 1))
				throw new IllegalStateException("Invalid value of social norm (in sensitivity analysis).");
		}
	}

	// Tick == -1.
	public void initBC() {
		updateBC();

		// Assertion.
		if ((score_BC < 0) || (score_BC > 1))
			throw new IllegalStateException("Invalid value of behavior control.");

		if (RandomHelper.nextDoubleFromTo(0, 1) < score_BC) // < or <= should be fine.
			setDriving(true);
	}

	public void updateBC() {
		score_BC = calculateBC();

		// Assertion.
		if ((score_BC < 0) || (score_BC > 1))
			throw new IllegalStateException("Invalid value of behavior control.");

		// Sensitivity analysis.
		if (CityBuilder.IS_SENSITIVITY_ANALYSIS_MODE && (CityBuilder.SENSITIVITY_ANALYSIS_TYPE == 2)) {
			score_BC = score_BC * (1 + CityBuilder.SENSITIVITY_CHANGE_BC);

			if (score_BC < 0)
				score_BC = 0;
			else if (score_BC > 1)
				score_BC = 1;

			// Assertion.
			if ((score_BC < 0) || (score_BC > 1))
				throw new IllegalStateException("Invalid value of behavior control.");
		}
	}

	public double calculateBC() {
		double publicTransportTimeChange = 0;

		double destParkingChargeChange = 0;

		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		if (tick >= CityBuilder.POLICY_START_TIME) {
			publicTransportTimeChange = CityBuilder.PUBLIC_TRANSPORT_TIME_CHANGE;

			destParkingChargeChange = CityBuilder.DEST_PARKING_CHARGE_CHANGE;
		}

		Table travelCost = orig.getTravelCosts()
				.where(orig.getTravelCosts().stringColumn("BoroughID_D").isEqualTo(dest.getId()));

		if (travelCost.rowCount() != 1)
			throw new IllegalStateException("Travel cost row number error: " + id + " " + orig + " " + dest);
		else {
			double bc = 0;

			if (travelCost.row(0).getDouble("Diff_Time") >= 30) { // Long distance (Diff_Time >= 30).
				bc = 1.0d / (1 + Math.exp(-(LAMBDA_INTERCEPT1
						+ (LAMBDA_DIFF_TIME1 * (travelCost.row(0).getDouble("Diff_Time") + publicTransportTimeChange))
						+ LAMBDA_FUEL1 * travelCost.row(0).getDouble("FuelCost")
						+ LAMBDA_CONGESTION1 * travelCost.row(0).getDouble("CongestionCharge")
						+ LAMBDA_PARKING1_O * travelCost.row(0).getDouble("ParkingCharge_O") + LAMBDA_PARKING1_D
								* (travelCost.row(0).getDouble("ParkingCharge_D") + destParkingChargeChange))));
			} else { // Short distance (Diff_Time < 30).
				bc = 1.0d / (1 + Math.exp(-(LAMBDA_INTERCEPT2
						+ (LAMBDA_DIFF_TIME2 * (travelCost.row(0).getDouble("Diff_Time") + publicTransportTimeChange))
						+ LAMBDA_FUEL2 * travelCost.row(0).getDouble("FuelCost")
						+ LAMBDA_CONGESTION2 * travelCost.row(0).getDouble("CongestionCharge")
						+ LAMBDA_PARKING2_O * travelCost.row(0).getDouble("ParkingCharge_O") + LAMBDA_PARKING2_D
								* (travelCost.row(0).getDouble("ParkingCharge_D") + destParkingChargeChange))));
			}

			if (id % SHOW_INTERVAL == 0)
				System.out.println(id + ": " + orig.getId() + " " + dest.getId() + " "
						+ CityBuilder.DF.format(travelCost.row(0).getDouble("Diff_Time")) + " "
						+ CityBuilder.DF.format(travelCost.row(0).getDouble("FuelCost")) + " "
						+ CityBuilder.DF.format(travelCost.row(0).getDouble("CongestionCharge")) + " "
						+ CityBuilder.DF.format(travelCost.row(0).getDouble("ParkingCharge_D")) + " "
						+ CityBuilder.DF.format(bc));

			return bc;
		}
	}

	public void chooseMode(ChooseModeOption option) {
		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		if (tick < CityBuilder.WARMUP_START_TIME) // Ticks 1 and 2.
			throw new IllegalStateException("chooseMode() should be called in the warm-up stage or later.");

		double cmp = 0; // Choose mode period.

		if (option == ChooseModeOption.WARMUP)
			cmp = CHOOSE_MODE_FREQUENCY_WARMUP;
		else
			cmp = CHOOSE_MODE_FREQUENCY_USUAL;

		if (RandomHelper.nextDoubleFromTo(0, 1) > cmp)
			return;

		if ((tick >= CityBuilder.POLICY_START_TIME) && (!isPolicyInfluenced)
				&& ((CityBuilder.PUBLIC_TRANSPORT_TIME_CHANGE != 0) || (CityBuilder.DEST_PARKING_CHARGE_CHANGE != 0))) {
			isPolicyInfluenced = true;

			updateBC();
		}

		// Assertion.
		if ((score_EA < 0) || (score_EA > 1))
			throw new IllegalStateException("Invalid value of environmental attitude.");

		// Assertion.
		if ((score_BC < 0) || (score_BC > 1))
			throw new IllegalStateException("Invalid value of behavior control.");

		updateSN();

		boolean willGoPublic = (WEIGHT_EA * score_EA + WEIGHT_SN * score_SN >= WEIGHT_BC * score_BC);

		setDriving(!willGoPublic);
	}

	public boolean getDriving() {
		return isDriving;
	}

	public void setDriving(boolean isDriving) {
		this.isDriving = isDriving;
	}

	public int getDegree_O() {
		return links_O.size();
	}

	public int getDegree_D() {
		return links_D.size();
	}

	int getRandomFriendIndex(boolean isOrigin) {
		if (isOrigin)
			return RandomHelper.nextIntFromTo(0, links_O.size() - 1);
		else
			return RandomHelper.nextIntFromTo(0, links_D.size() - 1);
	}

	SocialNetworkEdge getLinkByIndex(int index, boolean isOrigin) {
		if (isOrigin)
			return (SocialNetworkEdgeOrig) (links_O.get(index));
		else
			return (SocialNetworkEdgeDest) (links_D.get(index));
	}

	Human getFriendByIndex(int index, boolean isOrigin) {
		if (isOrigin)
			return (Human) (links_O.get(index).getTarget());
		else
			return (Human) (links_D.get(index).getTarget());
	}

	public void dropFriendsUponMigration(int numFriendsToDrop, boolean isOrigin) {
		if (numFriendsToDrop <= 0) {
			// System.out.println("No friends to drop (isOrigin: " + isOrigin + ").");

			return;
		}

		// Assertion.
		if (isOrigin && (getDegree_O() < numFriendsToDrop))
			throw new IllegalStateException("Too many friends to drop at the origin.");

		// Assertion.
		if (!isOrigin && (getDegree_D() < numFriendsToDrop))
			throw new IllegalStateException("Too many friends to drop at the destination.");

		for (int i = 0; i < numFriendsToDrop; ++i) {
			int ri = getRandomFriendIndex(isOrigin);

			Human friendToDrop = dropFriendByIndex(ri, isOrigin);

			friendToDrop.addAnotherFriend(isOrigin);
		}
	}

	public Human dropFriendByIndex(int index, boolean isOrigin) {
		SocialNetworkEdge link = getLinkByIndex(index, isOrigin);

		Human friendToDrop = getFriendByIndex(index, isOrigin);

		if (isOrigin) {
			network_O.removeEdge(link);

			links_O.remove(index);
		} else {
			network_D.removeEdge(link);

			links_D.remove(index);
		}

		if (Human.IS_SHOW_MIGRATION_DETAILS) {
			System.out.println("\n" + id + " (" + orig + ", " + dest + ") drops a friend: " + friendToDrop.getId()
					+ " (" + friendToDrop.getOrig() + ", " + friendToDrop.getDest() + ") isOrigin: " + isOrigin + ".");

			if (isOrigin)
				System.out.println(getFriendsDetails_O());
			else
				System.out.println(getFriendsDetails_D());
		}

		friendToDrop.dropFriendReversely(this, isOrigin); // Reverse drop.

		return friendToDrop;
	}

	public void dropFriendReversely(Human f, boolean isOrigin) {
		List<? extends SocialNetworkEdge> links;

		Network<Object> network;

		if (isOrigin) {
			links = links_O;

			network = network_O;
		} else {
			links = links_D;

			network = network_D;
		}

		// Network.getEdge(source, target) can be used here instead. But it is slow.
		// Pay attention to the trap of List.remove().
		Iterator<? extends SocialNetworkEdge> iter = links.iterator();

		while (iter.hasNext()) {
//		for (int i = 0; i < links.size(); ++i) {
//			SocialNetworkEdge link = links.get(i);
			SocialNetworkEdge link = iter.next();

			Human friendToTest = (Human) (link.getTarget());

			// if (friendToTest.getId() == f.getId()) {
			if (friendToTest == f) {
				network.removeEdge(link);

//				links.remove(i);
				iter.remove();

				if (Human.IS_SHOW_MIGRATION_DETAILS) {
					System.out.println(id + " (" + orig + ", " + dest + ") drops a friend reversely: "
							+ friendToTest.getId() + " (" + friendToTest.getOrig() + ", " + friendToTest.getDest()
							+ ") isOrigin: " + isOrigin + ".");

					if (isOrigin)
						System.out.println(getFriendsDetails_O());
					else
						System.out.println(getFriendsDetails_D());
				}

				break; // Ok.
			}
		}
	}

	void addAnotherFriend(boolean isOrigin) {
		int numPeople = 0;

//		String place = "";

		if (isOrigin) {
			numPeople = orig.getNumResidents();

//			place = orig.getIdName();
		} else {
			numPeople = dest.getNumWorkers();

//			place = dest.getIdName();
		}

		// Only myself is left.
		if (numPeople <= 1)
			throw new IllegalStateException("Too few people (" + numPeople + ").");

//		Assertion.
//		If local people become fewer and fewer, this needs to be checked.
//		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();		
//		if (hasMadeAllAvailableFriends(isOrigin)) // Can be skipped if numPeople is large.
//			throw new IllegalStateException("Tick " + tick + ": " + id + " has made all available friends at " + place
//					+ " (isOrigin: " + isOrigin + ").");

		Human f = null;

		int count = 0;

		do {
			++count;

			if (count > MAX_TIME_TO_FIND_FRIEND)
				throw new IllegalStateException("Cannot find a new friend within a given time.");

			int rn = RandomHelper.nextIntFromTo(0, numPeople - 1);

			if (isOrigin)
				f = orig.getResidents().get(rn);
			else
				f = dest.getWorkers().get(rn);
		} while ((f == this) || hasFriendAlready(f, isOrigin));
		// } while ((f.getId() == id) || hasFriendAlready(f, isOrigin));
		// Note: Don't write: (rn == id).

		addFriend(f, isOrigin);
	}

//	public boolean hasMadeAllAvailableFriends(boolean isOrigin) {
//		int numFriendsHere = 0;
//
//		List<? extends SocialNetworkEdge> links;
//
//		if (isOrigin)
//			links = links_O;
//		else
//			links = links_D;
//
//		for (SocialNetworkEdge link : links) {
//			if (isOrigin) {
//				if (((Human) link.getTarget()).getOrig() == orig) // Either "==" or equals() is ok. The equals() of
//																	// java.lang.Object just check if the two references
//																	// refer to the same object.
//					++numFriendsHere;
//			} else {
//				if (((Human) link.getTarget()).getDest() == dest) // Either "==" or equals() is ok.
//					++numFriendsHere;
//			}
//		}
//
//		int maxFriendsHere;
//
//		if (isOrigin)
//			maxFriendsHere = orig.getResidents().size() - 1;
//		else
//			maxFriendsHere = dest.getWorkers().size() - 1;
//
//		return (numFriendsHere >= maxFriendsHere);
//	}

	public void addFriendsUponMigration(int numFriendsToAdd, boolean isOrigin) {
		if (numFriendsToAdd <= 0) {
			// System.out.println("No friends to add (isOrigin: " + isOrigin + ").");

			return;
		}

		int numPeople;

		if (isOrigin)
			numPeople = orig.getNumResidents();
		else
			numPeople = dest.getNumWorkers();

		// Exclude myself.
		if ((numPeople - 1) < numFriendsToAdd)
			throw new IllegalStateException("Too few people (" + numPeople + ").");

		// Only myself is left.
		if (numPeople <= 1)
			throw new IllegalStateException("Too few people (" + numPeople + ").");

		for (int i = 0; i < numFriendsToAdd; ++i) {
			Human f = null;

			int count = 0;

			do {
				++count;

				if (count > MAX_TIME_TO_FIND_FRIEND)
					throw new IllegalStateException("Cannot find a new friend within a given time.");

				int rn = RandomHelper.nextIntFromTo(0, numPeople - 1);

				if (isOrigin)
					f = orig.getResidents().get(rn);
				else
					f = dest.getWorkers().get(rn);
			} while ((f == this) || hasFriendAlready(f, isOrigin));
			// } while ((f.getId() == id) || hasFriendAlready(f, isOrigin));
			// Note: Don't write: (rn == id).

			if (isOrigin && (f.getDegree_O() == 0))
				System.out.println(f.getId() + " has no exisiting friends at the origin.");
			else if (!isOrigin && (f.getDegree_D() == 0))
				System.out.println(f.getId() + " has no exisiting friends at the destination.");

			addFriend(f, isOrigin);
		}
	}

	public void updateMemoryUponMigration() {
		updateMemory(UpdateMemoryOption.FIRST_TIME);
	}

	public String getLinksStr_O() {
		return links_O.toString();
	}

	public String getLinksStr_D() {
		return links_D.toString();
	}

//	This method is used for checking consistency between links_O and network_O.getOutEdges().
	public String getOutEdgesStr_O() {
		String str = "[";

		Iterator<RepastEdge<Object>> iter = network_O.getOutEdges(this).iterator();

		while (iter.hasNext()) {
			str += iter.next();

			if (iter.hasNext())
				str += ", ";
		}

		str += "]";

		return str;
	}

//	This method is used for checking consistency between links_D and network_D.getOutEdges().
	public String getOutEdgesStr_D() {
		String str = "[";

		Iterator<RepastEdge<Object>> iter = network_D.getOutEdges(this).iterator();

		while (iter.hasNext()) {
			str += iter.next();

			if (iter.hasNext())
				str += ", ";
		}

		str += "]";

		return str;
	}

	public boolean getMigrant() {
		return isMigrant;
	}

	public void setMigrant(boolean isMigrant) {
		this.isMigrant = isMigrant;
	}

	public double getMigrationTime() {
		return migrationTime;
	}

	public void setMigrationTime(double tick) {
		migrationTime = tick;
	}
}
