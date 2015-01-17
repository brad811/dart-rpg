library Tile;

class Tile {
  static final int
    GROUND = 67,
    WALL = 68,
    PLAYER = 129,
    HOUSE = 225;
  
  final int type;
  final bool solid;
  
  Tile(int type, bool solid)
    : this.type = type,
      this.solid = solid;
}