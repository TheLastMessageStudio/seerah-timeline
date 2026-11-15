enum Side { player, ai }

extension SideX on Side {
  Side get other => this == Side.player ? Side.ai : Side.player;
}
