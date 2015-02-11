library Battle;

import 'dart:math' as math;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/delayed_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class Battle implements InteractableInterface {
  GameEvent gameEvent;
  List<List<Tile>> tiles = [];
  
  ChoiceGameEvent main, fight, powers, bag, run;
  GameEvent exit;
  Battler friendly, enemy;
  Sprite friendlySprite, enemySprite;
  
  GameEvent attackEvent;
  
  math.Random rand = new math.Random();
  
  Battle(this.friendly, this.enemy) {
    friendlySprite = new Sprite.int(friendly.spriteId, 3, 7);
    enemySprite = new Sprite.int(enemy.spriteId, 14, 1);
    
    for(int y=0; y<Main.world.viewYSize; y++) {
      tiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        tiles[y].add(new Tile(false, new Sprite.int(Tile.GROUND, x, y)));
      }
    }
    
    exit = new GameEvent((callback) {
      Main.focusObject = Main.player;
      Gui.windows.removeRange(0, Gui.windows.length);
      Main.inBattle = false;
    });
    
    fight = new ChoiceGameEvent.custom(
      this,
      friendly.attackNames,
      [
        [new GameEvent((callback) { attack(friendly, 0); })],
        [new GameEvent((callback) { attack(friendly, 1); })],
        [new GameEvent((callback) { attack(friendly, 2); })],
        [new GameEvent((callback) { attack(friendly, 3); })]
      ],
      5, 11, 10, 5
    );
    fight.remove = true;
    
    main = new ChoiceGameEvent.custom(
      this,
      ["Fight", "Powers", "Bag", "Run"],
      [[fight], [fight], [fight], [exit]],
      15, 11, 5, 5
    );
    main.remove = false;
    
    // go back to the main screen from the fight screen
    fight.cancelEvent = main;
  }
  
  void start() {
    Main.inBattle = true;
    main.trigger();
  }
  
  void attack(Battler user, int attackNum) {
    Gui.windows = [];
    
    Function callback = () {
      Gui.windows.removeRange(0, Gui.windows.length);
      main.trigger();
    };
    
    // TODO: enemy decide action
    if(
        friendly.speed > enemy.speed || // friendly is faster
        (friendly.speed == enemy.speed && rand.nextBool()) // speed tie breaker
    ) {
      doAttack(friendly, enemy, false, attackNum, () {
        doAttack(enemy, friendly, true, rand.nextInt(enemy.attacks.length), callback);
      });
    } else {
      doAttack(enemy, friendly, true, rand.nextInt(enemy.attacks.length), () {
        doAttack(friendly, enemy, false, attackNum, callback);
      });
    }
  }
  
  void doAttack(Battler attacker, Battler receiver, bool enemy, int attackNum, Function callback) {
    Gui.windows.removeRange(0, Gui.windows.length);
    
    attacker.attacks[attackNum].use(attacker, receiver, enemy, () {
      if(receiver.health < 0)
        receiver.health = 0;
      
      List<DelayedGameEvent> healthDrains = [];
      for(int i=0; i<(receiver.displayHealth - receiver.health).abs(); i++) {
        healthDrains.add(
          new DelayedGameEvent(Main.timeDelay, () {
            if(receiver.displayHealth > receiver.health)
              receiver.displayHealth--;
            else
              receiver.displayHealth++;
          })
        );
      }
      
      healthDrains.add(
        new DelayedGameEvent(200, () {
          if(receiver.health <= 0) {
            // TODO: receiver dies
            exit.trigger();
          } else {
            callback();
          }
        })
      );
      
      DelayedGameEvent.executeDelayedEvents(healthDrains);
    });
  }
  
  void tick() {
    
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
    
    Main.ctx.setFillColorRgb(170, 170, 170);
    Main.ctx.fillRect(
      x*Sprite.scaledSpriteSize, y*Sprite.scaledSpriteSize,
      (8*health*Sprite.pixelsPerSprite).round()*Sprite.spriteScale, 4*Sprite.spriteScale
    );
  }
  
  void render() {
    // background
    for(int y=0; y<tiles.length; y++) {
      for(int x=0; x<tiles[0].length; x++) {
        tiles[y][x].sprite.renderStatic();
      }
    }
    
    friendlySprite.renderStaticSized(3,3);
    enemySprite.renderStaticSized(3,3);
    
    // enemy health bar
    drawHealthBar(1, 1, enemy.displayHealth/enemy.baseHealth);
    
    // friendly health bar
    Main.ctx.setFillColorRgb(255, 255, 255);
    Main.ctx.fillRect(
      175*Sprite.spriteScale, 145*Sprite.spriteScale,
      130*Sprite.spriteScale, 14*Sprite.spriteScale
    );
    
    Font.renderStaticText(22.25, 18.75, "${friendly.displayHealth}");
    Font.renderStaticText(37.6 - ("${friendly.baseHealth}".length)*0.75, 18.75, "${friendly.baseHealth}");
    
    drawHealthBar(11, 10, friendly.displayHealth/friendly.baseHealth);
  }
}