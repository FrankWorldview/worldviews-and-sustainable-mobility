package cityPlus;

import repast.simphony.parameter.StringConverter;

public class WorldviewConverter implements StringConverter<Worldview> {

	public String toString(Worldview worldview) {
		if (worldview == Worldview.EGALITARIAN)
			return "egalitarian";
		else if (worldview == Worldview.HIERARCHIST)
			return "hierarchist";
		else if (worldview == Worldview.INDIVIDUALIST)
			return "individualist";
		else
			throw new IllegalArgumentException("Invalid value of worldview.");
	}

	public Worldview fromString(String str) {
		if (str.equals("egalitarian"))
			return Worldview.EGALITARIAN;
		else if (str.equals("hierarchist"))
			return Worldview.HIERARCHIST;
		else if (str.equals("individualist"))
			return Worldview.INDIVIDUALIST;
		else
			throw new IllegalArgumentException("Invalid value of worldview string.");
	}
}
