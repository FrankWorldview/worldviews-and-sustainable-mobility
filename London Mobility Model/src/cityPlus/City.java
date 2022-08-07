package cityPlus;

import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;
import java.util.SortedMap;
import java.util.Iterator;

import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.schedule.ScheduledMethod;
import repast.simphony.gis.util.GeometryUtil;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.gis.Geography;
import repast.simphony.space.graph.Network;
import repast.simphony.util.ContextUtils;
import repast.simphony.util.SimUtilities;
import repast.simphony.util.collections.IndexedIterable;
import repast.simphony.context.Context;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.MultiPolygon;
import com.vividsolutions.jts.geom.Point;

import tech.tablesaw.api.Table;
import tech.tablesaw.api.DoubleColumn;

import cityPlus.CityBuilder.ShowHumanMode;

public class City {
	String name;

	SortedMap<String, Zone> zones;

	Table travelCosts;

	Table newFlowDist;

	Network<Object> network_O;
	Network<Object> network_D;

	// double carModeShare_;

	Geography<Object> geography;

	GeometryFactory geomFactory;

	City(String name) {
		this.name = name;
	}

	public String toString() {
		return name;
	}

	public String getName() {
		return name;
	}

	public void setZones(SortedMap<String, Zone> zones) {
		this.zones = zones;
	}

	public void setGeography(Geography<Object> geography, GeometryFactory geomFactory) {
		this.geography = geography;

		this.geomFactory = geomFactory;
	}

	public void initTravelCosts() {
		try {
			travelCosts = Table.read().csv(CityBuilder.FILE_TRAVEL_COST);
		} catch (Exception e) {
			throw new UnsupportedOperationException(e);
		}

		System.out.println(travelCosts);
		System.out.println(travelCosts.shape());
	}

//	Only "Pct" is used. Therefore, the same flow distribution file can be used for all random seeds.
	public void initNewFlowDist() {
		String flowFile = CityBuilder.FILE_FLOW_DIST;

		System.out.println("\nFlow distribution file: " + flowFile);

		try {
			try {
				newFlowDist = Table.read().csv(flowFile);
			} catch (Exception e) {
				System.out.println("The flow distribution file is not found. Use the default file instead.");

				flowFile = CityBuilder.FILE_FLOW_DIST1;

				System.out.println("\nFlow distribution file: " + flowFile);

				newFlowDist = Table.read().csv(flowFile);
			}
		} catch (Exception e) {
			throw new UnsupportedOperationException(e);
		}

		newFlowDist = newFlowDist
				.where(newFlowDist.stringColumn("BoroughID_O").isEqualTo(CityBuilder.MIGRATION_TARGET));

//		This line can be dropped since newFlowDist has been sorted. The returned object is a copy.
		newFlowDist = newFlowDist.sortAscendingOn("BoroughID_D");

		System.out.println(newFlowDist);
		System.out.println(newFlowDist.shape());

		DoubleColumn pct = newFlowDist.doubleColumn("FlowPct");

		DoubleColumn accPct = pct.copy();

		accPct.setName("AccFlowPct");

		newFlowDist.addColumns(accPct);

//		accPct = newFlowsDist.doubleColumn("AccFlowPct"); // No need of this line, because the two references are identical.

		int n = newFlowDist.rowCount();

		for (int i = 1; i < n; ++i)
			accPct.set(i, accPct.getDouble(i - 1) + accPct.getDouble(i));

		accPct.set(n - 1, 1.0d); // Set the last row to 1.0.

		// System.out.println(newFlowDist);

		System.out.println(newFlowDist.printAll());
		System.out.println(newFlowDist.shape());
	}

	public String newDestId() {
		DoubleColumn accPct = newFlowDist.doubleColumn("AccFlowPct");

		double rn = RandomHelper.nextDoubleFromTo(0, 1);

		int pos = -1;

		for (int i = 0; i < newFlowDist.rowCount(); ++i)
			if (rn <= accPct.getDouble(i)) {
				pos = i;

				break;
			}

//		Zones start with 1.
//		String str = new String("E090000") + String.format("%02d", pos + 1);

		String destId = newFlowDist.stringColumn("BoroughID_D").get(pos);

		if (Human.IS_SHOW_NEW_DESTINATION)
			System.out.println("New destination: " + destId + " (" + rn + ")");

		return destId;
	}

	public int getNumResidents() {
		int numResidents = 0;

		// Set<Map.Entry<String, Zone>> entries = zones.entrySet();

		for (Map.Entry<String, Zone> entry : zones.entrySet()) {
			Zone zone = entry.getValue();

			// Test if keys are sorted: yes.
			// System.out.println(entry.getKey() + ": test key");

			numResidents += zone.getNumResidents();
		}

		return numResidents;
	}

	public int getNumWorkers() {
		int numWorkers = 0;

		// Set<Map.Entry<String, Zone>> entries = zones.entrySet();

		for (Map.Entry<String, Zone> entry : zones.entrySet()) {
			Zone zone = entry.getValue();

			// Test if keys are sorted.
			// System.out.println(entry.getKey() + ": test key");

			numWorkers += zone.getNumWorkers();
		}

		return numWorkers;
	}

	public int getNumDrivers() {
		int numDrivers = 0;

		// Set<Map.Entry<String, Zone>> entries = zones.entrySet();

		for (Map.Entry<String, Zone> entry : zones.entrySet()) {
			Zone zone = entry.getValue();

			numDrivers += zone.getNumDrivers(); // Both City and Zone call it!
			// numDrivers += zone.getNumDrivers_();
		}

		return numDrivers;
	}

	@ScheduledMethod(start = 1, interval = 1, shuffle = false, priority = CityBuilder.PRIORITY_CITY)
	public void step() {
		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		if ((tick == 1) || (tick == CityBuilder.WARMUP_END_TIME) || (tick == (CityBuilder.MIGRATION_START_TIME - 1))) {
			listPopulation();

			listAverageEA();

			listAverageSN();

			listAverageBC();

			listNetworksInfo();
		}

		if (CityBuilder.IS_MIGRATION_MODE && (tick >= CityBuilder.MIGRATION_START_TIME))
			listNetworksInfo();

		int numResidents = getNumResidents();

		if (numResidents > 0) {
			int numDrivers = getNumDrivers();

			double carModeShare = (double) numDrivers / numResidents;

			if (RunEnvironment.getInstance().isBatch())
				System.out.println(RandomHelper.getSeed() + ": " + tick + ": Car mode share: " + numDrivers + " / "
						+ numResidents + " = " + CityBuilder.DF.format(carModeShare * 100) + "%\n");
			else
				System.out.println(tick + ": Car mode share: " + numDrivers + " / " + numResidents + " = "
						+ CityBuilder.DF.format(carModeShare * 100) + "%\n");
		} else
			System.out.println(name + ": " + "no residents.");

		// Assertion.
		if (tick % 50 == 0) {
			int numWorkers = getNumWorkers();

			int numHuman = getNumHuman();

			if ((numResidents != numWorkers) || (numResidents != numHuman))
				throw new IllegalStateException("The number of residents is not equal to that of workers or humans.");
		}
	}

	public void listAverageEA() {
		System.out.println("Avg EA of Human = " + getAverageEA());

		System.out.println("Avg EA of Egalitarian = " + getAverageEA_E());

		System.out.println("Avg EA of Hierarchist = " + getAverageEA_H());

		System.out.println("Avg EA of Individualist = " + getAverageEA_I());
	}

	public double getAverageEA() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Human.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getEA();

		return sum / humanCollection.size();
	}

	public double getAverageEA_E() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Egalitarian.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getEA();

		return sum / humanCollection.size();
	}

	public double getAverageEA_H() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Hierarchist.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getEA();

		return sum / humanCollection.size();
	}

	public double getAverageEA_I() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Individualist.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getEA();

		return sum / humanCollection.size();
	}

	public void listAverageSN() {
		System.out.println("Avg SN of Human = " + getAverageSN());

		System.out.println("Avg SN of Egalitarian = " + getAverageSN_E());

		System.out.println("Avg SN of Hierarchist = " + getAverageSN_H());

		System.out.println("Avg SN of Individualist = " + getAverageSN_I());
	}

	public double getAverageSN() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Human.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getSN();

		return sum / humanCollection.size();
	}

	public double getAverageSN_E() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Egalitarian.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getSN();

		return sum / humanCollection.size();
	}

	public double getAverageSN_H() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Hierarchist.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getSN();

		return sum / humanCollection.size();
	}

	public double getAverageSN_I() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Individualist.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getSN();

		return sum / humanCollection.size();
	}

	public void listAverageBC() {
		System.out.println("Avg BC of Human = " + getAverageBC());

		System.out.println("Avg BC of Egalitarian = " + getAverageBC_E());

		System.out.println("Avg BC of Hierarchist = " + getAverageBC_H());

		System.out.println("Avg BC of Individualist = " + getAverageBC_I());
	}

	public double getAverageBC() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Human.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getBC();

		return sum / humanCollection.size();
	}

	public double getAverageBC_E() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Egalitarian.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getBC();

		return sum / humanCollection.size();
	}

	public double getAverageBC_H() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Hierarchist.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getBC();

		return sum / humanCollection.size();
	}

	public double getAverageBC_I() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Individualist.class);

		double sum = 0;

		for (Object o : humanCollection)
			sum += ((Human) o).getBC();

		return sum / humanCollection.size();
	}

//	public double getCarModeShare_() {
//		return carModeShare_;
//	}

	public double getCarModeShare() {
		return (double) getNumDrivers() / getNumResidents();
	}

	public double getCarModeShare_E() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Egalitarian.class);

		int numDrivers = 0;

		for (Object o : humanCollection)
			if (((Human) o).getDriving())
				++numDrivers;

		return (double) numDrivers / humanCollection.size();
	}

	public double getCarModeShare_H() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Hierarchist.class);

		int numDrivers = 0;

		for (Object o : humanCollection)
			if (((Human) o).getDriving())
				++numDrivers;

		return (double) numDrivers / humanCollection.size();
	}

	public double getCarModeShare_I() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Individualist.class);

		int numDrivers = 0;

		for (Object o : humanCollection)
			if (((Human) o).getDriving())
				++numDrivers;

		return (double) numDrivers / humanCollection.size();
	}

	public void setNetworks(Network<Object> network_O, Network<Object> network_D) {
		this.network_O = network_O;

		this.network_D = network_D;
	}

	public void listNetworksInfo() {
		System.out.println("Network O size: " + network_O.size());
		System.out.println("Network O degree: " + network_O.getDegree());
		System.out.println("Network O edges: " + network_O.numEdges());

		System.out.println("Network D size: " + network_D.size());
		System.out.println("Network D degree: " + network_D.getDegree());
		System.out.println("Network D edges: " + network_D.numEdges());
	}

	public void listNetworksNodes() {
		Iterator<Object> iter = network_O.getNodes().iterator();

		System.out.println("Network_O nodes:");

		while (iter.hasNext())
			System.out.println(iter.next());

		iter = network_D.getNodes().iterator();

		System.out.println("\nNetwork_D nodes:");

		while (iter.hasNext())
			System.out.println(iter.next());
	}

	@ScheduledMethod(start = 1, interval = 1, shuffle = false, priority = CityBuilder.PRIORITY_MIGRATION)
	public void runMigration() {
		if (!CityBuilder.IS_MIGRATION_MODE)
			return;

		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		if (CityBuilder.IS_MIGRATION_ONE_OFF && (tick != CityBuilder.MIGRATION_START_TIME))
			return;

		if ((tick < CityBuilder.MIGRATION_START_TIME) || (tick > CityBuilder.MIGRATION_END_TIME))
			return;

		if (tick == CityBuilder.MIGRATION_START_TIME)
			System.out.println("Starting migration.");

		if (tick == CityBuilder.MIGRATION_END_TIME)
			System.out.println("Ending migration.");

		Zone newOrig = zones.get(CityBuilder.MIGRATION_TARGET);

		System.out.println(newOrig.getIdName());

		newOrig.listPopulation();

		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = null;

		if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.EGALITARIAN)
			humanCollection = context.getObjects(Egalitarian.class);
		else if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.HIERARCHIST)
			humanCollection = context.getObjects(Hierarchist.class);
		else if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.INDIVIDUALIST)
			humanCollection = context.getObjects(Individualist.class);
		else
			throw new IllegalArgumentException("Invalid value of worldview.");

		List<Human> migrantPool = new ArrayList<Human>();

		for (Object o : humanCollection) {
			Human h = (Human) o;

			if (h.getOrig() != newOrig)
				migrantPool.add(h);
		}

		// Assertion.
		if (migrantPool.size() < CityBuilder.NUM_MIGRANTS)
			throw new IllegalStateException("Size of the migrant poll is too small.");

		double[] randIndexes = new double[migrantPool.size()];

		for (int i = 0; i < randIndexes.length; ++i)
			randIndexes[i] = i;

		// System.out.println("randIndexes: " + Arrays.toString(randIndexes));

		System.out.println("Size of all agents holding the migrant worldview (" + CityBuilder.MIGRATION_WORLDVIEW
				+ "): " + humanCollection.size());

		System.out.println("Size of potential migrants (randIndexes): " + randIndexes.length);

		SimUtilities.shuffle(randIndexes, RandomHelper.getUniform());

		// System.out.println("randIndexes: " + Arrays.toString(randIndexes));

		double[] migrantIndexes = Arrays.copyOf(randIndexes, CityBuilder.NUM_MIGRANTS);

		// System.out.println("migrantIndexes: " + Arrays.toString(migrantIndexes));

		// Assertion.
		if (migrantIndexes.length != CityBuilder.NUM_MIGRANTS)
			throw new IllegalStateException("Wrong size of the migrant index array.");

		MultiPolygon boundary = null;
		List<Coordinate> agentCoords = null;

		if (CityBuilder.IS_SHOW_MOVE_MIGRANTS) {
			boundary = (MultiPolygon) newOrig.getFeature().getDefaultGeometry();

			agentCoords = GeometryUtil.generateRandomPointsInPolygon(boundary, migrantIndexes.length,
					RandomHelper.getGenerator("GISRandomGen"));
		}

		for (int i = 0; i < migrantIndexes.length; ++i) {
			Human h = migrantPool.get((int) migrantIndexes[i]);

			if (Human.IS_SHOW_MIGRATION_DETAILS) {
				System.out.println("----------");

				System.out.println("New migrant: " + h.getId() + " " + h.getWorldview() + " " + h.getOrig() + " "
						+ h.getDest() + " " + h.getDegree_O() + " " + h.getDegree_D());

				System.out.println(h.getFriendsDetails_O());

				System.out.println(h.getFriendsDetails_D());

				System.out.println("\nNew origin: " + newOrig);
			}

			h.getOrig().getResidents().remove(h);

			h.setOrig(newOrig);

			// Assertion.
			if (h.getOrig() == null)
				throw new IllegalStateException(h.getId() + " has no valid new origin.");

			h.getOrig().getResidents().add(h);

			h.setMigrant(true);

			h.setMigrationTime(tick);

			int numFriendsToChange = (int) (h.getDegree_O() * CityBuilder.MIGRATION_SOCIAL_INTEGRATION_RATE);

//			Just for testing the correctness of migration.
//			int numFriendsToChange = (int) (CityBuilder.NUM_ZONAL_FRIENDS * CityBuilder.MIGRATION_SOCIAL_INTEGRATION_RATE);

			// Assertion.
			h.checkLinkIntegrity();

			if (Human.IS_SHOW_MIGRATION_DETAILS)
				System.out.println("\nDropping friends at the old origin.");

			h.dropFriendsUponMigration(numFriendsToChange, true);

			if (Human.IS_SHOW_MIGRATION_DETAILS)
				System.out.println("\nAdding friends at the new origin.");

			h.addFriendsUponMigration(numFriendsToChange, true);

			if (CityBuilder.IS_MIGRATION_WITH_DEST) {
				Zone newDest = null;

				if (CityBuilder.IS_MIGRATION_DEST_REDISTRIBUTED)
					newDest = zones.get(newDestId());
				else
					newDest = newOrig;

				// Assertion.
				if (newDest == null)
					throw new IllegalStateException("New destination is null");

				if (h.getDest() == newDest) {
					if (Human.IS_SHOW_MIGRATION_DETAILS)
						System.out.println("\nNew destination (the same as the old): " + newDest);
				} else { // If the migrant's old and new destinations are different.
					if (Human.IS_SHOW_MIGRATION_DETAILS)
						System.out.println("\nNew destination: " + newDest);

					h.getDest().getWorkers().remove(h);

					h.setDest(newDest);

					// Assertion.
					if (h.getDest() == null)
						throw new IllegalStateException(h.getId() + " has no valid new destination.");

					h.getDest().getWorkers().add(h);

					numFriendsToChange = (int) (h.getDegree_D() * CityBuilder.MIGRATION_SOCIAL_INTEGRATION_RATE);

					// Assertion.
					h.checkLinkIntegrity();

					if (Human.IS_SHOW_MIGRATION_DETAILS)
						System.out.println("\nDropping friends at the old destination.");

					h.dropFriendsUponMigration(numFriendsToChange, false);

					if (Human.IS_SHOW_MIGRATION_DETAILS)
						System.out.println("\nAdding friends at the new destination.");

					h.addFriendsUponMigration(numFriendsToChange, false);
				}
			}

			h.updateBC();

			h.updateMemoryUponMigration();

			if (Human.IS_SHOW_MIGRATION_DETAILS) {
				System.out.println("\nNew migrant updated: " + h.getId() + " " + h.getWorldview() + " " + h.getOrig()
						+ " " + h.getDest() + " " + h.getDegree_O() + " " + h.getDegree_D());

				System.out.println(h.getFriendsDetails_O());

				System.out.println(h.getFriendsDetails_D());

				System.out.println("----------");
			}

			if (((CityBuilder.SHOW_HUMAN_MODE == ShowHumanMode.ALL)
					|| (CityBuilder.SHOW_HUMAN_MODE == ShowHumanMode.PART)) && CityBuilder.IS_SHOW_MOVE_MIGRANTS) {
				Point geom = geomFactory.createPoint(agentCoords.get(i));

				geography.move(h, geom);
			}
		}
	}

	public double getAverageMigrantEA() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = null;

		if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.EGALITARIAN)
			humanCollection = context.getObjects(Egalitarian.class);
		else if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.HIERARCHIST)
			humanCollection = context.getObjects(Hierarchist.class);
		else if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.INDIVIDUALIST)
			humanCollection = context.getObjects(Individualist.class);
		else
			throw new IllegalArgumentException("Invalid value of worldview.");

		double ea = 0;

		int n = 0;

		for (Object o : humanCollection) {
			Human h = (Human) o;

			if (h.getMigrant()) {
				ea += h.getEA();

				++n;
			}
		}

		return ea / n;
	}

	public double getAverageMigrantCarModeShare() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = null;

		if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.EGALITARIAN)
			humanCollection = context.getObjects(Egalitarian.class);
		else if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.HIERARCHIST)
			humanCollection = context.getObjects(Hierarchist.class);
		else if (CityBuilder.MIGRATION_WORLDVIEW == Worldview.INDIVIDUALIST)
			humanCollection = context.getObjects(Individualist.class);
		else
			throw new IllegalArgumentException("Invalid value of worldview.");

		int numDrivers = 0;

		int n = 0;

		for (Object o : humanCollection) {
			Human h = (Human) o;

			if (h.getMigrant()) {
				++n;

				if (h.getDriving())
					++numDrivers;
			}
		}

		return (double) numDrivers / n;
	}

	public Table getTravelCosts() {
		return travelCosts;
	}

	public int getNumHuman() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Human.class);

		return humanCollection.size();
	}

	public int getNumEgalitarian() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Egalitarian.class);

		return humanCollection.size();
	}

	public int getNumHierarchist() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Hierarchist.class);

		return humanCollection.size();
	}

	public int getNumIndividualist() {
		Context<Object> context = ContextUtils.getContext(this);

		IndexedIterable<Object> humanCollection = context.getObjects(Individualist.class);

		return humanCollection.size();
	}

	public void listPopulation() {
		System.out.println("Human: " + getNumHuman());

		System.out.println("Egalitarian: " + getNumEgalitarian());

		System.out.println("Hierarchist: " + getNumHierarchist());

		System.out.println("Individualist: " + getNumIndividualist());
	}
}
