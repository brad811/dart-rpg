library Tile;

import 'package:dart_rpg/src/sprite.dart';

class Tile {
  static final int
    WOOD_FLOOR = 65,
    GROUND = 66,
    TALL_GRASS = 97,
    WALL = 67,
    PLAYER = 128,
    SIGN = 192,
    
    TREE = 69,
    TREE_BOTTOM = 101,
    TREES = 71,
    TREES_BOTTOM = 103,
    
    FENCE = 108,
    FENCE_TOP = 109,
    FENCE_RIGHT = 110,
    FENCE_TOP_RIGHT = 111,
    
    FENCE_BOTTOM = 140,
    FENCE_TOP_BOTTOM = 141,
    FENCE_RIGHT_BOTTOM = 142,
    FENCE_TOP_RIGHT_BOTTOM = 143,
    
    FENCE_LEFT = 172,
    FENCE_TOP_LEFT = 173,
    FENCE_RIGHT_LEFT = 174,
    FENCE_TOP_RIGHT_LEFT = 175,
    
    FENCE_BOTTOM_LEFT = 204,
    FENCE_TOP_BOTTOM_LEFT = 205,
    FENCE_RIGHT_BOTTOM_LEFT = 206,
    FENCE_ALL = 207,
    
    HOUSE = 224;
  
  final bool solid;
  final Sprite sprite;
  
  Tile(this.solid, this.sprite);
  
  void enter() {}
  
  void render() {
    sprite.render();
  }
}