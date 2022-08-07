package cityPlus;

public class SocialNetworkEdgeDest extends SocialNetworkEdge {
	public SocialNetworkEdgeDest(Human source, Human target, ModeChoice mc) {
		super(source, target);

		this.mc = mc;
	}
}
