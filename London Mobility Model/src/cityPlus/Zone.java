package cityPlus;

import java.util.List;
import java.util.ArrayList;

import repast.simphony.engine.schedule.ScheduledMethod;

import org.opengis.feature.simple.SimpleFeature;

import tech.tablesaw.api.Table;

public class Zone {
	String id;

	String name;

	List<Human> residents;
	List<Human> workers;

	Table travelCosts;

	SimpleFeature feature;

//	int numDrivers_; // For display purpose only.

	double carModeShare_; // For display purpose only.

	Zone(String id, String name) {
		this.id = id;

		this.name = name;

		residents = new ArrayList<Human>();

		workers = new ArrayList<Human>();
	}

	public String toString() {
		return id;
	}

	public String getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getIdName() {
		return id + " (" + name + ")";
	}

	public SimpleFeature getFeature() {
		return feature;
	}

	public void setFeature(SimpleFeature feature) {
		this.feature = feature;
	}

	public Table getTravelCosts() {
		return travelCosts;
	}

	public int getNumDrivers() {
		int numDrivers = 0;

		for (Human h : residents)
			if (h.getDriving())
				++numDrivers;

		return numDrivers;
	}

//	public int getNumDrivers_() {
//		return numDrivers_;
//	}

//	At tick -1, carModeShare_ == 0 because of Zone.step() starts at tick 1.
	public double getCarModeShare_() {
		return carModeShare_;
	}

	public double getCarModeShare() {
		return (double) getNumDrivers() / getNumResidents();
	}

	@ScheduledMethod(start = 1, interval = 1, shuffle = false, priority = CityBuilder.PRIORITY_ZONE)
	public void step() {
		int numResidents = getNumResidents();

		if (numResidents > 0) {
			int numDrivers = getNumDrivers();

			carModeShare_ = (double) numDrivers / numResidents;

			System.out.println(getIdName() + ": " + numDrivers + " / " + numResidents + " = "
					+ CityBuilder.DF.format(carModeShare_ * 100) + "%");
		} else
			System.out.println(getIdName() + ": " + "no residents.");
	}

	public void initTravelCosts(Table cityTravelCosts) {
		travelCosts = cityTravelCosts.where(cityTravelCosts.stringColumn("BoroughID_O").isEqualTo(id));

//		This line can be dropped since travelCosts has been sorted. The returned object is a copy.
		travelCosts = travelCosts.sortAscendingOn("BoroughID_D");
	}

	public void addResident(Human h) {
		residents.add(h);
	}

	public List<Human> getResidents() {
		return residents;
	}

	public int getNumResidents() {
		return residents.size();
	}

	public void addWorker(Human h) {
		workers.add(h);
	}

	public List<Human> getWorkers() {
		return workers;
	}

	public int getNumWorkers() {
		return workers.size();
	}

	public double getAverageEA() {
		double sum = 0;

		for (Human h : residents)
			sum += h.getEA();

		return sum / getNumResidents();
	}

	// This may lead to 0 / 0.
	public double getAverageEA_E() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.EGALITARIAN) {
				sum += h.getEA();

				++n;
			}

		return sum / n;
	}

	public double getAverageEA_H() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.HIERARCHIST) {
				sum += h.getEA();

				++n;
			}

		return sum / n;
	}

	public double getAverageEA_I() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.INDIVIDUALIST) {
				sum += h.getEA();

				++n;
			}

		return sum / n;
	}

	public double getAverageSN() {
		double sum = 0;

		for (Human h : residents)
			sum += h.getSN();

		return sum / getNumResidents();
	}

	public double getAverageSN_E() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.EGALITARIAN) {
				sum += h.getSN();

				++n;
			}

		return sum / n;
	}

	public double getAverageSN_H() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.HIERARCHIST) {
				sum += h.getSN();

				++n;
			}

		return sum / n;
	}

	public double getAverageSN_I() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.INDIVIDUALIST) {
				sum += h.getSN();

				++n;
			}

		return sum / n;
	}

	public double getAverageBC() {
		double sum = 0;

		for (Human h : residents)
			sum += h.getBC();

		return sum / getNumResidents();
	}

	public double getAverageBC_E() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.EGALITARIAN) {
				sum += h.getBC();

				++n;
			}

		return sum / n;
	}

	public double getAverageBC_H() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.HIERARCHIST) {
				sum += h.getBC();

				++n;
			}

		return sum / n;
	}

	public double getAverageBC_I() {
		double sum = 0;

		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.INDIVIDUALIST) {
				sum += h.getBC();

				++n;
			}

		return sum / n;
	}

	public int getNumEgalitarian() {
		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.EGALITARIAN)
				++n;

		return n;
	}

	public int getNumHierarchist() {
		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.HIERARCHIST)
				++n;

		return n;
	}

	public int getNumIndividualist() {
		int n = 0;

		for (Human h : residents)
			if (h.getWorldview() == Worldview.INDIVIDUALIST)
				++n;

		return n;
	}

	public void listPopulation() {
		System.out.println("Human: " + getNumResidents());

		System.out.println("Egalitarian: " + getNumEgalitarian());

		System.out.println("Hierarchist: " + getNumHierarchist());

		System.out.println("Individualist: " + getNumIndividualist());
	}
}
