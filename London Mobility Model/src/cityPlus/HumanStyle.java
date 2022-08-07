package cityPlus;

import java.awt.Color;
import java.awt.Font;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import repast.simphony.visualization.gis3D.PlaceMark;
import repast.simphony.visualization.gis3D.style.MarkStyle;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.render.BasicWWTexture;
import gov.nasa.worldwind.render.Material;
import gov.nasa.worldwind.render.Offset;
import gov.nasa.worldwind.render.WWTexture;

public class HumanStyle implements MarkStyle<Human> {
	private Map<String, WWTexture> textureMap;

	public HumanStyle() {
		/**
		 * Use of a map to store textures significantly reduces CPU and memory use since
		 * the same texture can be reused. Textures can be created for different agent
		 * states and re-used when needed.
		 */
		textureMap = new HashMap<String, WWTexture>();

		String file_E = "icons/Egalitarian.png";
		String file_H = "icons/Hierarchist.png";
		String file_I = "icons/Individualist.png";

		URL localUrl = WorldWind.getDataFileStore().requestFile(file_E);

		if (localUrl != null)
			textureMap.put("egalitarian", new BasicWWTexture(localUrl, true /* false */));

		localUrl = WorldWind.getDataFileStore().requestFile(file_H);

		if (localUrl != null)
			textureMap.put("hierarchist", new BasicWWTexture(localUrl, true /* false */));

		localUrl = WorldWind.getDataFileStore().requestFile(file_I);

		if (localUrl != null)
			textureMap.put("individualist", new BasicWWTexture(localUrl, true /* false */));
	}

	/**
	 * The PlaceMark is a WWJ PointPlacemark implementation with a different texture
	 * handling mechanism. All other standard WWJ PointPlacemark attributes can be
	 * changed here. PointPlacemark label attributes could be set here, but are also
	 * available through the MarkStyle interface.
	 * 
	 * @see gov.nasa.worldwind.render.PointPlacemark for more info.
	 */
	@Override
	public PlaceMark getPlaceMark(Human agent, PlaceMark mark) {

		// PlaceMark is null on first call.
		if (mark == null)
			mark = new PlaceMark();

		/**
		 * The Altitude mode determines how the mark appears using the elevation.
		 * WorldWind.ABSOLUTE places the mark at elevation relative to sea level
		 * WorldWind.RELATIVE_TO_GROUND places the mark at elevation relative to ground
		 * elevation WorldWind.CLAMP_TO_GROUND places the mark at ground elevation
		 */
		mark.setAltitudeMode(WorldWind.RELATIVE_TO_GROUND);
		mark.setLineEnabled(false);

		return mark;
	}

	/**
	 * Here we set the appearance of the TowerAgent using a non-changing icon.
	 */
	@Override
	public WWTexture getTexture(Human agent, WWTexture currentTexture) {

		// If the texture is already defined, then just return the same texture since
		// we don't want to update the agent appearance. The only time the
		// below code will actually be used is on the initialization of the display
		// when the icons are created.

		if (currentTexture != null)
			return currentTexture;
		else
			return textureMap.get(agent.getWorldviewStr());
	}

	@Override
	public double getElevation(Human agent) {
		return 0.0;
	}

	@Override
	public double getScale(Human agent) {
		return 0.1;
	}

	@Override
	public double getHeading(Human agent) {
		return 0.0;
	}

	@Override
	public String getLabel(Human agent) {
		return null;
	}

	@Override
	public Color getLabelColor(Human agent) {
		return null;
	}

	@Override
	public Font getLabelFont(Human agent) {
		return null;
	}

	@Override
	public Offset getLabelOffset(Human agent) {
		return null;
	}

	@Override
	public double getLineWidth(Human agent) {
		return 0.0;
	}

	@Override
	public Material getLineMaterial(Human agent, Material lineMaterial) {
		return null;
	}

	@Override
	public Offset getIconOffset(Human agent) {
		return Offset.CENTER;
	}
}
