package cityPlus;

import repast.simphony.space.graph.RepastEdge;

public class SocialNetworkEdge extends RepastEdge<Object> {

	ModeChoice mc;

	public SocialNetworkEdge(Human source, Human target) {
		super(source, target, CityBuilder.IS_NETWORK_DIRECTED);
	}

	public ModeChoice getModeChoice() {
		return mc;
	}

	public void setModeChoice(ModeChoice mc) {
		this.mc = mc;
	}
}
