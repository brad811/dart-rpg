library dart_rpg.warp_tile;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class WarpTile extends Tile {
  String destMap;
  int destX, destY;
  
  WarpTile(bool solid, Sprite sprite, this.destMap, this.destX, this.destY) : super(solid, sprite);
  
  void enter(Character character) {
    Main.player.inputEnabled = false;
    Gui.fadeDarkAction(() {
      Main.world.curMap = destMap;
      
      character.warp(destMap, destX, destY, character.layer, character.direction);
      
      character.motionX = 0;
      character.motionY = 0;
    }, () {
      Main.player.inputEnabled = true;

      try {
        Main.world.maps[destMap].tiles[destY][destX][0].enter(character);
      } on RangeError catch(_) {
        // do nothing
      }
    });
  }
}