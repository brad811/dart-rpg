library Tile;

import 'package:dart_rpg/src/sprite.dart';

class Tile {
  static final int
    WOOD_FLOOR = 66,
    GROUND = 67,
    WALL = 68,
    PLAYER = 129,
    SIGN = 193,
    HOUSE = 225;
  
  final bool solid;
  final Sprite sprite;
  
  Tile(this.solid, this.sprite);
  
  void enter() {}
  
  void render() {
    sprite.render();
  }
}