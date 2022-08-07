package cityPlus;

import java.awt.Color;

import repast.simphony.space.graph.RepastEdge;
import repast.simphony.visualization.gis3D.style.NetworkStyleGIS;

import gov.nasa.worldwind.render.SurfacePolyline;

public class SocialNetworkEdgeStyle implements NetworkStyleGIS {
	@Override
	public SurfacePolyline getSurfaceShape(RepastEdge edge, SurfacePolyline shape) {
		return new SurfacePolyline();
	}

	@Override
	public Color getLineColor(RepastEdge edge) {
		if (edge instanceof SocialNetworkEdgeOrig)
			return Color.ORANGE;
		else
			return Color.LIGHT_GRAY;
	}

	@Override
	public double getLineOpacity(RepastEdge edge) {
		return 0.8;
	}

	@Override
	public double getLineWidth(RepastEdge edge) {
		return 3.0;
	}
}
