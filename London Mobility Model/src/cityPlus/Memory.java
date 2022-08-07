package cityPlus;

import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.random.RandomHelper;

public class Memory {
	Human owner;

	int numFriendsPublic_O;
	int numFriendsPublic_D;

	int numFriendsValid_O;
	int numFriendsValid_D;

	double weightSN_O;
	double weightSN_D;

	Memory(Human h) {
		this.owner = h;

		if (Human.WEIGHT_SN_ORIG == 2) {
			weightSN_O = RandomHelper.nextDoubleFromTo(0, 1);

			weightSN_D = 1 - weightSN_O;
		} else {
			// Assertion.
			if ((Human.WEIGHT_SN_ORIG < 0) || (Human.WEIGHT_SN_ORIG > 1))
				new IllegalArgumentException("Invalid value of weight of social norm at the origin.");

			weightSN_O = Human.WEIGHT_SN_ORIG;

			weightSN_D = 1 - weightSN_O;
		}
	}

	void refresh() {
		numFriendsPublic_O = 0;

		numFriendsPublic_D = 0;

		numFriendsValid_O = 0;

		numFriendsValid_D = 0;

		for (SocialNetworkEdgeOrig link : owner.links_O) {
			if (link.getModeChoice() == ModeChoice.PUBLIC)
				++numFriendsPublic_O;

			if (link.getModeChoice() != ModeChoice.NA)
				++numFriendsValid_O;
		}

		for (SocialNetworkEdgeDest link : owner.links_D) {
			if (link.getModeChoice() == ModeChoice.PUBLIC)
				++numFriendsPublic_D;

			if (link.getModeChoice() != ModeChoice.NA)
				++numFriendsValid_D;
		}
	}

	// Pay attention: double & integer.
	double calculateSN() {
		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

//		Assertion.
//		At ticks -1 and 1, the method returns NaN.
//		At tick CityBuilder.WARMUP_PRE_START_TIME, numFriends* variables are updated by Human.updateMemory(UpdateMemoryOption.FIRST_TIME).
		if ((tick >= CityBuilder.WARMUP_START_TIME) && ((numFriendsValid_O <= 0) || (numFriendsValid_D <= 0)))
			throw new IllegalStateException("No valid friend.");

//		return ((double) numFriendsPublic_O / numFriendsValid_O * weightSN_O)
//				+ ((double) numFriendsPublic_D / numFriendsValid_D * weightSN_D);

		return (weightSN_O * numFriendsPublic_O / numFriendsValid_O)
				+ (weightSN_D * numFriendsPublic_D / numFriendsValid_D);
	}

	public String getDetails_O() {
		String str = "Orig (" + owner.links_O.size() + "):";

		for (SocialNetworkEdgeOrig link : owner.links_O)
			str = str + " " + link.getModeChoice();

		return str;
	}

	public String getDetails_D() {
		String str = "Dest (" + owner.links_D.size() + "):";

		for (SocialNetworkEdgeDest link : owner.links_D)
			str = str + " " + link.getModeChoice();

		return str;
	}

//	public String toString() {
//		return getDetails_O() + " " + getDetails_D();
//	}
}
