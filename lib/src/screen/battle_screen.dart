library dart_rpg.battle_screen;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/screen/screen.dart';

class BattleScreen extends Screen {
  Sprite friendlySprite, enemySprite;
  
  BattleScreen(Battler friendly, Battler enemy) {
    for(int y=0; y<Main.world.viewYSize; y++) {
      backgroundTiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        backgroundTiles[y].add(new Tile(false, new Sprite.int(66, x, y)));
      }
    }
    
    friendlySprite = new Sprite.int(friendly.battlerType.spriteId, 3, 7);
    enemySprite = new Sprite.int(enemy.battlerType.spriteId, 14, 1);
  }
  
  @override
  void render() {
    super.render();
    
    friendlySprite.renderStaticSized(3,3);
    enemySprite.renderStaticSized(3,3);
    
    // enemy health bar
    Main.ctx.setFillColorRgb(255, 255, 255);
    Main.ctx.fillRect(
      15*Sprite.spriteScale, 0*Sprite.scaledSpriteSize,
      130*Sprite.spriteScale, 1*Sprite.scaledSpriteSize
    );
    
    // friendly health bar
    Main.ctx.setFillColorRgb(255, 255, 255);
    Main.ctx.fillRect(
      175*Sprite.spriteScale, 8.125*Sprite.scaledSpriteSize,
      130*Sprite.spriteScale, 2*Sprite.scaledSpriteSize
    );
  }
}