package cityPlus;

public class SocialNetworkEdgeOrig extends SocialNetworkEdge {
	public SocialNetworkEdgeOrig(Human source, Human target, ModeChoice mc) {
		super(source, target);

		this.mc = mc;
	}
}
