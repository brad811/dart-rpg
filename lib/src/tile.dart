library dart_rpg.tile;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

class Tile {
  final bool solid;
  final Sprite sprite;
  
  final bool layered;
  Sprite topSprite;
  Tile topTile;
  
  // TODO: maybe take sprite id as argument instead of sprite
  Tile(this.solid, this.sprite, [this.layered]) {
    if(layered == true) {
      topSprite = new Sprite(sprite.id + Sprite.spriteSheetWidth, sprite.posX, sprite.posY);
      topTile = new Tile(solid, topSprite);
    }
  }
  
  void enter(Character character) {}
  
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