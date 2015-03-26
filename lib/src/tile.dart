library Tile;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

class Tile {
  static final int
    WOOD_FLOOR = 65,
    GROUND = 66,
    TALL_GRASS = 97,
    WALL = 67,
    PLAYER = 145,
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
  
  final bool layered;
  Sprite topSprite;
  Tile topTile;
  
  // TODO: maybe take sprite id as argument instead of sprite
  Tile(this.solid, this.sprite, [this.layered]) {
    if(layered == true) {
      topSprite = new Sprite(sprite.id + 32, sprite.posX, sprite.posY);
      topTile = new Tile(solid, topSprite);
    }
  }
  
  void enter() {}
  
  void render() {
    sprite.render();
    
    if(layered == true) {
      // Make sure the top tile is only rendered when appropriate
      // TODO: make this apply to all characters, not just the player?
      if(
          (
            ( // Player is walking down into the tile
              (Main.player.y/Sprite.scaledSpriteSize).ceil() == topSprite.posY &&
              Main.player.mapY <= topSprite.posY &&
              Main.player.direction == Character.DOWN
            ) || ( // Player is walking down out of the tile
              (Main.player.y/Sprite.scaledSpriteSize).ceil() == topSprite.posY &&
              Main.player.mapY >= topSprite.posY &&
              Main.player.direction == Character.DOWN
            ) || (
              (Main.player.y/Sprite.scaledSpriteSize).ceil() == topSprite.posY
            )
          ) &&
          (
            Main.player.x/Sprite.scaledSpriteSize - topSprite.posX <= 1.0
          )
      ) {
        Main.world.maps[Main.world.curMap]
          .tiles[topSprite.posY.round()][topSprite.posX.round()][World.LAYER_ABOVE] = topTile;
      } else {
        Main.world.maps[Main.world.curMap]
          .tiles[topSprite.posY.round()][topSprite.posX.round()][World.LAYER_ABOVE] = null;
      }
    }
  }
}