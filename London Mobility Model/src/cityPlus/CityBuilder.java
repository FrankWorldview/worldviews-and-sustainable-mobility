package cityPlus;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.text.DecimalFormat;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.SortedMap;
import java.util.TreeMap;

import repast.simphony.context.Context;
import repast.simphony.context.space.gis.GeographyFactoryFinder;
import repast.simphony.context.space.graph.NetworkBuilder;
import repast.simphony.dataLoader.ContextBuilder;
import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.parameter.Parameters;
import repast.simphony.util.collections.IndexedIterable;
import repast.simphony.random.RandomHelper;
import repast.simphony.gis.util.GeometryUtil;
import repast.simphony.space.gis.Geography;
import repast.simphony.space.gis.GeographyParameters;
import repast.simphony.space.graph.Network;
// import repast.simphony.space.gis.FeatureAgentFactory;
// import repast.simphony.space.gis.FeatureAgentFactoryFinder;

import org.geotools.data.shapefile.ShapefileDataStore;
import org.geotools.data.simple.SimpleFeatureIterator;
// import org.geotools.referencing.crs.DefaultGeographicCRS;

import org.opengis.feature.simple.SimpleFeature;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.MultiPolygon;
import com.vividsolutions.jts.geom.Point;
// import com.vividsolutions.jts.geom.Polygon;

import tech.tablesaw.api.Table;

/**
 * @author Frank Chuang
 *
 */

public class CityBuilder implements ContextBuilder<Object> {
	public static final boolean IS_NETWORK_DIRECTED = true;

	public static final double HUMAN_PERCENTAGE = 0.006;

	public static enum ShowHumanMode {
		ALL, PART, NONE
	}

	public static final ShowHumanMode SHOW_HUMAN_MODE = ShowHumanMode.ALL;

	public static final boolean IS_SHOW_MOVE_MIGRANTS = true;

	public static final double PRIORITY_CITY = 70;
	public static final double PRIORITY_ZONE = 80;
	public static final double PRIORITY_HUMAN = 90;
	public static final double PRIORITY_MIGRATION = 100; // 95 is reserved for writing migration data.

	public static final String DIR_MICROSIM = "D:/Google/MicroSim";

	public static final String FILE_AGENT = DIR_MICROSIM + "/batch/Agent_";
	public static final String FILE_AGENT1 = DIR_MICROSIM + "/Agent_SingleRun.csv";
	public static final String FILE_FLOW_DIST = DIR_MICROSIM + "/batch/FlowDist_1.csv";
	public static final String FILE_FLOW_DIST1 = DIR_MICROSIM + "/FlowDist_SingleRun.csv";

	public static final String FILE_TRAVEL_COST = "data/TravelCost.csv";
	public static final String FILE_CITY_SHPAE = "data/London/London.shp";

	public static final double WARMUP_START_TIME = 3;
	public static final double WARMUP_PRE_START_TIME = WARMUP_START_TIME - 1;
	public static final double WARMUP_DURATION = 120;
	public static final double WARMUP_END_TIME = WARMUP_START_TIME + WARMUP_DURATION - 1; // Tick 122.

	public static final double ENV_ATTITUDE_CHANGE_START_TIME = WARMUP_END_TIME + 1;
	public static final double ENV_ATTITUDE_CHANGE_DURATION = 10000; // A very big value.
	public static final double ENV_ATTITUDE_CHANGE_END_TIME = ENV_ATTITUDE_CHANGE_START_TIME
			+ ENV_ATTITUDE_CHANGE_DURATION - 1;
	public static final double ENV_ATTITUDE_CHANGE_FREQUENCY = 1.0d / 12; // Every 12 months.

	public static final double POLICY_START_TIME = WARMUP_END_TIME + 1;
//	public static final double POLICY_DURATION = 24;
//	public static final double POLICY_END_TIME = POLICY_START_TIME + POLICY_DURATION - 1;

//	public static final boolean IS_MIGRATION_FROM_ALL_ZONES = true;

	public static final DecimalFormat DF = new DecimalFormat("#.###");

	static double NUM_TICKS_PER_BATCH_RUN;

	static int NUM_ZONAL_FRIENDS;

	static boolean IS_MIGRATION_MODE;

	static String MIGRATION_TARGET; // E09000017: Hillingdon; E09000012: Hackney.
	static Worldview MIGRATION_WORLDVIEW;
	static double MIGRATION_SOCIAL_INTEGRATION_RATE;
	static int NUM_MIGRANTS;

	static double MIGRATION_START_TIME;
	static double MIGRATION_DURATION;
	static double MIGRATION_END_TIME;

	static boolean IS_MIGRATION_ONE_OFF;
	static boolean IS_MIGRATION_WITH_DEST;
	static boolean IS_MIGRATION_DEST_REDISTRIBUTED;

	static double ENV_ATTITUDE_CHANGE;
	static double PUBLIC_TRANSPORT_TIME_CHANGE;
	static double DEST_PARKING_CHARGE_CHANGE;

	static boolean IS_SENSITIVITY_ANALYSIS_MODE;
	static int SENSITIVITY_ANALYSIS_TYPE;
	static double SENSITIVITY_CHANGE_EA;
	static double SENSITIVITY_CHANGE_SN;
	static double SENSITIVITY_CHANGE_BC;

	@Override
	public Context<Object> build(Context<Object> context) {
		System.out.println("\nCityPlus Model Ver 1.0");

		System.out.println("\nStarting to build a city.");

		context.setId("CityPlus");

		System.out.println("\nInitializing global parameters.");

		// Correct import: repast.simphony.parameters.Parameters.
		Parameters params = RunEnvironment.getInstance().getParameters();

		System.out.println("\nDefault random seed = " + RandomHelper.getSeed());

		RandomHelper.registerGenerator("GISRandomGen", RandomHelper.getSeed());

		System.out.println("\nGIS random seed = " + RandomHelper.getSeed("GISRandomGen"));

		NUM_TICKS_PER_BATCH_RUN = (double) params.getValue("NUM_TICKS_PER_BATCH_RUN");
		System.out.println("\nNUM_TICKS_PER_BATCH_RUN = " + NUM_TICKS_PER_BATCH_RUN);

		Human.WEIGHT_EA = (double) params.getValue("WEIGHT_EA");
		System.out.println("\nWEIGHT_EA = " + Human.WEIGHT_EA);

		Human.WEIGHT_SN = (double) params.getValue("WEIGHT_SN");
		System.out.println("\nWEIGHT_SN = " + Human.WEIGHT_SN);

		Human.WEIGHT_BC = (double) params.getValue("WEIGHT_BC");
		System.out.println("\nWEIGHT_BC = " + Human.WEIGHT_BC);

		Human.WEIGHT_SN_ORIG = (double) params.getValue("WEIGHT_SN_ORIG");
		System.out.println("\nWEIGHT_SN_ORIG = " + Human.WEIGHT_SN_ORIG);

		NUM_ZONAL_FRIENDS = (int) params.getValue("NUM_ZONAL_FRIENDS");

		// To make network links fewer and thus visuals clearer.
		if (SHOW_HUMAN_MODE == ShowHumanMode.PART)
			NUM_ZONAL_FRIENDS = NUM_ZONAL_FRIENDS / 4;

		System.out.println("\nNUM_ZONAL_FRIENDS = " + NUM_ZONAL_FRIENDS);

		IS_MIGRATION_MODE = (boolean) params.getValue("IS_MIGRATION_MODE");
		System.out.println("\nIS_MIGRATION_MODE = " + IS_MIGRATION_MODE);

		MIGRATION_TARGET = (String) params.getValue("MIGRATION_TARGET");
		System.out.println("\nMIGRATION_TARGET = " + MIGRATION_TARGET);

		int mw = (int) params.getValue("MIGRATION_WORLDVIEW");

		if (mw == 1)
			MIGRATION_WORLDVIEW = Worldview.EGALITARIAN;
		else if (mw == 2)
			MIGRATION_WORLDVIEW = Worldview.HIERARCHIST;
		else if (mw == 3)
			MIGRATION_WORLDVIEW = Worldview.INDIVIDUALIST;
		else
			throw new IllegalArgumentException("Invalid value of worldview.");

		System.out.println("\nMIGRATION_WORLDVIEW = " + MIGRATION_WORLDVIEW);

		MIGRATION_SOCIAL_INTEGRATION_RATE = (double) params.getValue("MIGRATION_SOCIAL_INTEGRATION_RATE");
		System.out.println("\nMIGRATION_SOCIAL_INTEGRATION_RATE = " + MIGRATION_SOCIAL_INTEGRATION_RATE);

		NUM_MIGRANTS = (int) params.getValue("NUM_MIGRANTS");
		System.out.println("\nNUM_MIGRANTS = " + NUM_MIGRANTS);

		MIGRATION_START_TIME = (double) params.getValue("MIGRATION_START_TIME");
		System.out.println("\nMIGRATION_START_TIME = " + MIGRATION_START_TIME);

		MIGRATION_DURATION = (double) params.getValue("MIGRATION_DURATION");
		System.out.println("\nMIGRATION_DURATION = " + MIGRATION_DURATION);

		MIGRATION_END_TIME = MIGRATION_START_TIME + MIGRATION_DURATION - 1;

		IS_MIGRATION_ONE_OFF = (boolean) params.getValue("IS_MIGRATION_ONE_OFF");
		System.out.println("\nIS_MIGRATION_ONE_OFF = " + IS_MIGRATION_ONE_OFF);

		IS_MIGRATION_WITH_DEST = (boolean) params.getValue("IS_MIGRATION_WITH_DEST");
		System.out.println("\nIS_MIGRATION_WITH_DEST = " + IS_MIGRATION_WITH_DEST);

		IS_MIGRATION_DEST_REDISTRIBUTED = (boolean) params.getValue("IS_MIGRATION_DEST_REDISTRIBUTED");
		System.out.println("\nIS_MIGRATION_DEST_REDISTRIBUTED = " + IS_MIGRATION_DEST_REDISTRIBUTED);

		ENV_ATTITUDE_CHANGE = (double) params.getValue("ENV_ATTITUDE_CHANGE");
		System.out.println("\nENV_ATTITUDE_CHANGE = " + ENV_ATTITUDE_CHANGE);

		PUBLIC_TRANSPORT_TIME_CHANGE = (double) params.getValue("PUBLIC_TRANSPORT_TIME_CHANGE");
		System.out.println("\nPUBLIC_TRANSPORT_TIME_CHANGE = " + PUBLIC_TRANSPORT_TIME_CHANGE);

		DEST_PARKING_CHARGE_CHANGE = (double) params.getValue("DEST_PARKING_CHARGE_CHANGE");
		System.out.println("\nDEST_PARKING_CHARGE_CHANGE = " + DEST_PARKING_CHARGE_CHANGE);

		IS_SENSITIVITY_ANALYSIS_MODE = (boolean) params.getValue("IS_SENSITIVITY_ANALYSIS_MODE");
		System.out.println("\nIS_SENSITIVITY_ANALYSIS_MODE = " + IS_SENSITIVITY_ANALYSIS_MODE);

		SENSITIVITY_ANALYSIS_TYPE = (int) params.getValue("SENSITIVITY_ANALYSIS_TYPE");
		System.out.println("\nSENSITIVITY_ANALYSIS_TYPE = " + SENSITIVITY_ANALYSIS_TYPE);

		SENSITIVITY_CHANGE_EA = (double) params.getValue("SENSITIVITY_CHANGE_EA");
		System.out.println("\nSENSITIVITY_CHANGE_EA = " + SENSITIVITY_CHANGE_EA);

		SENSITIVITY_CHANGE_SN = (double) params.getValue("SENSITIVITY_CHANGE_SN");
		System.out.println("\nSENSITIVITY_CHANGE_SN = " + SENSITIVITY_CHANGE_SN);

		SENSITIVITY_CHANGE_BC = (double) params.getValue("SENSITIVITY_CHANGE_BC");
		System.out.println("\nSENSITIVITY_CHANGE_BC = " + SENSITIVITY_CHANGE_BC);

		if (CityBuilder.IS_SENSITIVITY_ANALYSIS_MODE && (CityBuilder.SENSITIVITY_ANALYSIS_TYPE == 1)) {
			System.out.println("\nUpdating the weights of the three behavioral constructs.");

			Human.WEIGHT_EA = Human.WEIGHT_EA * (1 + SENSITIVITY_CHANGE_EA);
			System.out.println("\nNew WEIGHT_EA = " + Human.WEIGHT_EA);

			Human.WEIGHT_SN = Human.WEIGHT_SN * (1 + SENSITIVITY_CHANGE_SN);
			System.out.println("\nNew WEIGHT_SN = " + Human.WEIGHT_SN);

			Human.WEIGHT_BC = Human.WEIGHT_BC * (1 + SENSITIVITY_CHANGE_BC);
			System.out.println("\nNew WEIGHT_BC = " + Human.WEIGHT_BC);
		}

		GeographyParameters<Object> geoParams = new GeographyParameters<Object>();

//		geoParams.setCrs("EPSG:27700");

		Geography<Object> geography = GeographyFactoryFinder.createGeographyFactory(null)
				.createGeography("CityGeography", context, geoParams);

		GeometryFactory geomFactory = new GeometryFactory();

		List<SimpleFeature> cityFeatures = loadFeaturesFromShapefile(FILE_CITY_SHPAE);

		System.out.println("\nCity features:");

		for (SimpleFeature f : cityFeatures)
			System.out.println(f.getAttribute("GSS_CODE"));

		Collections.sort(cityFeatures, new Comparator<SimpleFeature>() {
			@Override
			public int compare(SimpleFeature lhs, SimpleFeature rhs) {
				return lhs.getAttribute("GSS_CODE").toString().compareTo(rhs.getAttribute("GSS_CODE").toString());
			}
		});

		System.out.println("\nCity features (sorted):");

		for (SimpleFeature f : cityFeatures)
			System.out.println(f.getAttribute("GSS_CODE"));

		NetworkBuilder<Object> netBuilder_O = new NetworkBuilder<Object>("SocialNetwork_O", context,
				IS_NETWORK_DIRECTED);

		Network<Object> network_O = netBuilder_O.buildNetwork();

		NetworkBuilder<Object> netBuilder_D = new NetworkBuilder<Object>("SocialNetwork_D", context,
				IS_NETWORK_DIRECTED);

		Network<Object> network_D = netBuilder_D.buildNetwork();

		City city = new City("London");

		context.add(city);

		city.setGeography(geography, geomFactory);

		System.out.println("\nImporting travel costs in the city.");

		city.initTravelCosts();

		System.out.println("\nImporting travel flow distribution of the migration target zone.");

		city.initNewFlowDist();

		System.out.println("\nNetworks initial status:");

		city.setNetworks(network_O, network_D);

		city.listNetworksInfo();

		System.out.println("\nImporting zones (boroughs).");

		SortedMap<String, Zone> zones = new TreeMap<String, Zone>();

//		List<SimpleFeature> newCityFeatures = new ArrayList<SimpleFeature>();

//		CoordinateReferenceSystem sourceCRS = null;
//		try {
//			sourceCRS = CRS.decode("EPSG:27700");
//		} catch (Exception e) {
//			System.err.println("No CRS.");
//		}

//		FeatureAgentFactory feaFactory = FeatureAgentFactoryFinder.getInstance().getFeatureAgentFactory(Zone.class,
//				Polygon.class, DefaultGeographicCRS.WGS84);

		for (SimpleFeature f : cityFeatures) {
			String zoneId = f.getAttribute("GSS_CODE").toString();

			String zoneName = f.getAttribute("NAME").toString();

			System.out.println("Processing zone: " + zoneId + " (" + zoneName + ")");

			Zone zone = new Zone(zoneId, zoneName);

			context.add(zone);

			zones.put(zone.getId(), zone);

			zone.initTravelCosts(city.getTravelCosts());

//			SimpleFeature newCityFeature = feaFactory.getFeature(zone, geography);
//
//			if (((MultiPolygon) f.getDefaultGeometry()).getNumGeometries() > 1)
//				newCityFeature.setDefaultGeometry(((MultiPolygon) f.getDefaultGeometry()).getGeometryN(1));
//			else
//				newCityFeature.setDefaultGeometry(((MultiPolygon) f.getDefaultGeometry()).getGeometryN(0));
//
//			zone.setFeature(newCityFeature);

			zone.setFeature(f);

//			Polygon boundary = (Polygon) newCityFeature.getDefaultGeometry();
			MultiPolygon boundary = (MultiPolygon) zone.getFeature().getDefaultGeometry();

			geography.move(zone, boundary);

//			newCityFeatures.add(newCityFeature);
		}

		city.setZones(zones);

		System.out.println("\nNetworks status before adding humans agents:");

		city.listNetworksInfo(); // 34: London + 33 boroughs.

		System.out.println("\nNetworks nodes before adding humans agents:");

		city.listNetworksNodes();

		System.out.println("\nImporting agents.");

		Table agents = null;
		String agentFile = CityBuilder.FILE_AGENT + RandomHelper.getSeed() + ".csv";

		System.out.println("\nAgent file: " + agentFile);

		try {
			try {
				agents = Table.read().csv(agentFile);
			} catch (Exception e) {
				System.out.println(
						"The random seed has no corresponding agent file. Use the default agent file instead.");

				agentFile = CityBuilder.FILE_AGENT1;

				System.out.println("\nAgent file: " + agentFile);

				agents = Table.read().csv(agentFile);
			}
		} catch (Exception e) {
			throw new UnsupportedOperationException(e);
		}

		System.out.println(agents);
		System.out.println(agents.shape());

		System.out.println("\nAllocating human agents.");

		int totalPeople = 0;

//		for (SimpleFeature f : newCityFeatures) {
//		for (SimpleFeature f : cityFeatures) {
		for (Map.Entry<String, Zone> entry : zones.entrySet()) {
//			String zoneId = (String) f.getAttribute("id");
//			String zoneId = f.getAttribute("GSS_CODE").toString();

			Zone zone = entry.getValue();

			String zoneId = zone.getId();

			System.out.println("Allocating agents to zone: " + zoneId);

			Table zoneAgents = agents.where(agents.stringColumn("Orig").isEqualTo(zoneId));

			int n = zoneAgents.rowCount();

			MultiPolygon boundary = (MultiPolygon) zone.getFeature().getDefaultGeometry();

			// Generate random coordinates for agents.
			List<Coordinate> agentCoords = GeometryUtil.generateRandomPointsInPolygon(boundary, n,
					RandomHelper.getGenerator("GISRandomGen"));

			for (int i = 0; i < n; ++i) {
				if ((SHOW_HUMAN_MODE == ShowHumanMode.PART) && (RandomHelper.nextDoubleFromTo(0, 1) > HUMAN_PERCENTAGE))
					continue;

				int w = zoneAgents.row(i).getInt("Worldview");
				Human h = null;

				if (w == 1)
					h = new Egalitarian(++totalPeople, zoneAgents.row(i).getString("ID"), Worldview.EGALITARIAN,
							zones.get(zoneAgents.row(i).getString("Orig")),
							zones.get(zoneAgents.row(i).getString("Dest")),
							zoneAgents.row(i).getInt("ReduceCarTravel"));
				else if (w == 2)
					h = new Hierarchist(++totalPeople, zoneAgents.row(i).getString("ID"), Worldview.HIERARCHIST,
							zones.get(zoneAgents.row(i).getString("Orig")),
							zones.get(zoneAgents.row(i).getString("Dest")),
							zoneAgents.row(i).getInt("ReduceCarTravel"));
				else if (w == 3)
					h = new Individualist(++totalPeople, zoneAgents.row(i).getString("ID"), Worldview.INDIVIDUALIST,
							zones.get(zoneAgents.row(i).getString("Orig")),
							zones.get(zoneAgents.row(i).getString("Dest")),
							zoneAgents.row(i).getInt("ReduceCarTravel"));
				else
					throw new IllegalArgumentException("Invalid value of worldview.");

				context.add(h);

				h.setNetworks(network_O, network_D);

				h.getOrig().addResident(h); // Better to use a function.

				h.getDest().addWorker(h);

				if ((SHOW_HUMAN_MODE == ShowHumanMode.ALL) || (SHOW_HUMAN_MODE == ShowHumanMode.PART)) {
					Point geom = geomFactory.createPoint(agentCoords.get(i));

					// If only part of the agents are moved, then all the agents will not be shown.
					geography.move(h, geom);
				}
			}
		}

		System.out.println("\nGIS layers: " + geography.getLayerNames());

		System.out.println("\nNumber of people = " + totalPeople);

		System.out.println("\nCreating social networks.");

		IndexedIterable<Object> humanCollection = context.getObjects(Human.class);

		double tick = RunEnvironment.getInstance().getCurrentSchedule().getTickCount();

		System.out.println("Current tick: " + tick); // -1.0. There is no tick 0 in Repast Symphony.

		// Order: E / H / I.
		for (Object o : humanCollection) {
			// System.out.println(o.getClass());

			((Human) o).makeFriends();
		}

		System.out.println("\nNetworks status:");

		city.listNetworksInfo();

		System.out.println("\nSetting each agent's default intention/propensity to drive.");

		for (Object o : humanCollection)
			((Human) o).initBC();

		System.out.println("\nAll zones:");

		IndexedIterable<Object> zoneCollection = context.getObjects(Zone.class);

		for (Object o : zoneCollection)
			System.out.println(((Zone) o).getIdName());

		if (RunEnvironment.getInstance().isBatch())
			RunEnvironment.getInstance().endAt(NUM_TICKS_PER_BATCH_RUN);

		System.out.println("\nThe city has been built successfully.\n");

		return context;
	}

	private List<SimpleFeature> loadFeaturesFromShapefile(String file) {
		URL url = null;

		try {
			url = new File(file).toURI().toURL();
		} catch (MalformedURLException e) {
			throw new UnsupportedOperationException(e);
		}

		List<SimpleFeature> features = new ArrayList<SimpleFeature>();

		// Load the shape file.
		ShapefileDataStore store = null;
		SimpleFeatureIterator feaIter = null;

		store = new ShapefileDataStore(url);

		try {
			feaIter = store.getFeatureSource().getFeatures().features();

			while (feaIter.hasNext())
				features.add(feaIter.next());
		} catch (Exception e) {
			throw new UnsupportedOperationException(e);
		} finally {
			if (feaIter != null)
				feaIter.close();

			if (store != null)
				store.dispose();
		}

		return features;
	}
}
