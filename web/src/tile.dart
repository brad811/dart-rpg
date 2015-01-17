library Tile;

import 'sprite.dart';

class Tile {
  static final int
    GROUND = 67,
    WALL = 68,
    PLAYER = 129,
    HOUSE = 225;
  
  final bool solid;
  final Sprite sprite;
  
  Tile(this.solid, this.sprite);
}