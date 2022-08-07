package cityPlus;

import java.awt.Color;

import repast.simphony.visualization.gis3D.style.SurfaceShapeStyle;

import gov.nasa.worldwind.render.SurfaceShape;
import gov.nasa.worldwind.render.SurfacePolyline;
// import gov.nasa.worldwind.render.SurfacePolygon;
// import gov.nasa.worldwind.render.SurfaceMultiPolygon;

public class ZoneStyle implements SurfaceShapeStyle<Zone> {
	static final int MAX_COLOR_INDEX = 10;

	static Color[] whiteRedColorScale = new Color[MAX_COLOR_INDEX];

	static {
		// White to red scale.
		for (int i = 0; i < whiteRedColorScale.length; ++i) {
			int greenBlue = (int) (255d / MAX_COLOR_INDEX * (MAX_COLOR_INDEX - i));

			whiteRedColorScale[i] = new Color(255, greenBlue, greenBlue);
		}
	}

	@Override
	public SurfaceShape getSurfaceShape(Zone zone, SurfaceShape shape) {
		// return new SurfacePolygon();
		return new SurfacePolyline();
	}

	@Override
	public Color getFillColor(Zone zone) {
		// return Color.CYAN;

		if (zone.getCarModeShare_() < 1)
			return whiteRedColorScale[(int) (zone.getCarModeShare_() * MAX_COLOR_INDEX)];
		else // 100%: All people are car drivers.
			return whiteRedColorScale[whiteRedColorScale.length - 1];
	}

	@Override
	public double getFillOpacity(Zone zone) {
		return 1.0;
	}

	@Override
	public Color getLineColor(Zone zone) {
		return Color.DARK_GRAY;
	}

	@Override
	public double getLineOpacity(Zone zone) {
		return 1.0;
	}

	@Override
	public double getLineWidth(Zone zone) {
		return 6.0;
	}
}
