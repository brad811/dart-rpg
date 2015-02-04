library WarpTile;

import 'package:dart_rpg/src/delayed_game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class WarpTile extends Tile {
  int destX, destY;
  
  WarpTile(bool solid, Sprite sprite, this.destX, this.destY) : super(solid, sprite);
  
  void enter() {
    Main.timeScale = 0.0;
    Gui.fadeOutLevel = Gui.FADE_BLACK_LOW;
    
    DelayedGameEvent.executeDelayedEvents([
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = Gui.FADE_BLACK_MED;
      }),
      
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = Gui.FADE_BLACK_FULL;
        
        Main.player.x = destX * Sprite.pixelsPerSprite * Sprite.spriteScale;
        Main.player.y = destY * Sprite.pixelsPerSprite * Sprite.spriteScale;
        Main.player.mapX = destX;
        Main.player.mapY = destY;
      }),
      
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = Gui.FADE_BLACK_MED;
      }),
      
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = Gui.FADE_BLACK_LOW;
      }),
      
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = Gui.FADE_NORMAL;
        Main.timeScale = 1.0;
      })
    ]);
  }
}