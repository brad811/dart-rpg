library WarpTile;

import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class WarpTile extends Tile {
  int destX, destY;
  
  WarpTile(solid, sprite, this.destX, this.destY) : super(solid, sprite);
  
  void enter() {
    Player.x = destX * Sprite.pixelsPerSprite * Sprite.spriteScale;
    Player.y = destY * Sprite.pixelsPerSprite * Sprite.spriteScale;
    Player.mapX = destX;
    Player.mapY = destY;
  }
}