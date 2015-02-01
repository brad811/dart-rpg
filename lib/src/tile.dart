library Tile;

import 'package:dart_rpg/src/sprite.dart';

class Tile {
  static final int
    WOOD_FLOOR = 66,
    GROUND = 67,
    WALL = 68,
    PLAYER = 129,
    SIGN = 193,
    
    FENCE_POST = 204,
    FENCE_TOP_POST = 144,
    FENCE_BOTTOM_POST = 174,
    
    FENCE_TOP_LEFT = 141,
    FENCE_TOP_MIDDLE = 142,
    FENCE_TOP_RIGHT = 143,
    FENCE_MIDDLE_LEFT = 173,
    FENCE_MIDDLE_RIGHT = 175,
    FENCE_BOTTOM_LEFT = 205,
    FENCE_BOTTOM_MIDDLE = 206,
    FENCE_BOTTOM_RIGHT = 207,
    
    HOUSE = 225;
  
  final bool solid;
  final Sprite sprite;
  
  Tile(this.solid, this.sprite);
  
  void enter() {}
  
  void render() {
    sprite.render();
  }
}