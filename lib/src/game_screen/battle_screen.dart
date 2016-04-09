library dart_rpg.battle_screen;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/game_screen/game_screen.dart';

class BattleScreen extends GameScreen {
  Battler friendly, enemy;
  Sprite friendlySprite, enemySprite;
  
  BattleScreen(this.friendly, this.enemy) {
    // TODO: move to editor
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
    
    double levelTextAdjust = 0.75 * (enemy.level.toString().length - 1);
    Font.renderStaticText(14.6 - levelTextAdjust, 0.8, "Lv ${enemy.level}");
    
    Font.renderStaticText(2.3, 0.8, "${enemy.battlerType.name}");
    drawHealthBar(1, 1, enemy.displayHealth/enemy.startingHealth);
    
    Font.renderStaticText(22.25, 17.0, "${friendly.battlerType.name}");
        
    levelTextAdjust = 0.75 * (friendly.level.toString().length - 1);
    Font.renderStaticText(34.6 - levelTextAdjust, 17.0, "Lv ${friendly.level}");
    
    Font.renderStaticText(22.25, 18.75, "${friendly.displayHealth}");
    Font.renderStaticText(37.6 - ("${friendly.startingHealth}".length)*0.75, 18.75, "${friendly.startingHealth}");
    
    drawHealthBar(11, 10, friendly.displayHealth/friendly.startingHealth);
    
    drawExperienceBar();
  }
  
  void drawHealthBar(int x, int y, double health) {
    Main.ctx.setFillColorRgb(0, 0, 0);
    Main.ctx.fillRect(
      x*Sprite.scaledSpriteSize - Sprite.spriteScale, y*Sprite.scaledSpriteSize - Sprite.spriteScale,
      8*Sprite.scaledSpriteSize + Sprite.spriteScale*2, 4*Sprite.spriteScale + Sprite.spriteScale*2
    );
    
    Main.ctx.setFillColorRgb(255, 255, 255);
    Main.ctx.fillRect(
      x*Sprite.scaledSpriteSize, y*Sprite.scaledSpriteSize,
      8*Sprite.scaledSpriteSize, 4*Sprite.spriteScale
    );
    
    if(health < 0.2)
      Main.ctx.setFillColorRgb(85, 85, 85);
    else
      Main.ctx.setFillColorRgb(170, 170, 170);
    
    Main.ctx.fillRect(
      x*Sprite.scaledSpriteSize, y*Sprite.scaledSpriteSize,
      (8*health*Sprite.pixelsPerSprite).round()*Sprite.spriteScale, 4*Sprite.spriteScale
    );
  }
  
  void drawExperienceBar() {
    Main.ctx.setFillColorRgb(85, 85, 85);
    double ratio =
      (Main.player.getCurCharacter().battler.displayExperience - friendly.curLevelExperience()) /
      (friendly.nextLevelExperience() - friendly.curLevelExperience());
    Main.ctx.fillRect(
      11*Sprite.scaledSpriteSize - Sprite.spriteScale, 10.5*Sprite.scaledSpriteSize,
      ratio*(8*Sprite.scaledSpriteSize + Sprite.spriteScale*2), 2*Sprite.spriteScale + Sprite.spriteScale*2
    );
  }
}