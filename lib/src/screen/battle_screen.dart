library dart_rpg.battle_screen;

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/screen/screen.dart';

class BattleScreen extends Screen {
  BattleScreen() {
    for(int y=0; y<Main.world.viewYSize; y++) {
      backgroundTiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        backgroundTiles[y].add(new Tile(false, new Sprite.int(66, x, y)));
      }
    }
    
    Main.battle.friendlySprite.posX = 3.0;
    Main.battle.friendlySprite.posY = 7.0;
    
    Main.battle.enemySprite.posX = 14.0;
    Main.battle.enemySprite.posY = 1.0;
  }
  
  @override
  void render() {
    super.render();
    
    Main.battle.friendlySprite.renderStaticSized(3,3);
    Main.battle.enemySprite.renderStaticSized(3,3);
  }
}