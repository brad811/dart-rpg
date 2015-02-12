library Tile;

import 'package:dart_rpg/src/sprite.dart';

class Tile {
  static final int
    WOOD_FLOOR = 66,
    GROUND = 67,
    TALL_GRASS = 98,
    WALL = 68,
    PLAYER = 129,
    SIGN = 193,
    
    TREE = 70,
    TREE_BOTTOM = 102,
    TREES = 72,
    TREES_BOTTOM = 104,
    
    FENCE = 109,
    FENCE_TOP = 110,
    FENCE_RIGHT = 111,
    FENCE_TOP_RIGHT = 112,
    
    FENCE_BOTTOM = 141,
    FENCE_TOP_BOTTOM = 142,
    FENCE_RIGHT_BOTTOM = 143,
    FENCE_TOP_RIGHT_BOTTOM = 144,
    
    FENCE_LEFT = 173,
    FENCE_TOP_LEFT = 174,
    FENCE_RIGHT_LEFT = 175,
    FENCE_TOP_RIGHT_LEFT = 176,
    
    FENCE_BOTTOM_LEFT = 205,
    FENCE_TOP_BOTTOM_LEFT = 206,
    FENCE_RIGHT_BOTTOM_LEFT = 207,
    FENCE_ALL = 208,
    
    HOUSE = 225;
  
  final bool solid;
  final Sprite sprite;
  
  Tile(this.solid, this.sprite);
  
  void enter() {}
  
  void render() {
    sprite.render();
  }
}