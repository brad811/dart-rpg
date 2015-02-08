library Battle;

import 'dart:math' as math;

import 'package:dart_rpg/src/animation_game_event.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
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
  AnimationGameEvent exit;
  Battler friendly, enemy;
  Sprite friendlySprite, enemySprite;
  
  AnimationGameEvent attackEvent;
  
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
    
    exit = new AnimationGameEvent((callback) {
      Main.focusObject = Main.player;
      Gui.windows.removeRange(0, Gui.windows.length);
      Main.inBattle = false;
    });
    
    fight = new ChoiceGameEvent.custom(
      this,
      friendly.attackNames,
      [
        [new AnimationGameEvent((callback) { attack(friendly, 0); })],
        [new AnimationGameEvent((callback) { attack(friendly, 1); })],
        [new AnimationGameEvent((callback) { attack(friendly, 2); })],
        [new AnimationGameEvent((callback) { attack(friendly, 3); })]
      ],
      5, 14, 10, 2
    );
    fight.remove = true;
    
    main = new ChoiceGameEvent.custom(
      this,
      ["Fight", "Powers", "Bag", "Run"],
      [[fight], [fight], [fight], [exit]],
      15, 14, 5, 2
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
      if(receiver.health <= 0) {
        // TODO: receiver dies
        exit.trigger();
      } else {
        callback();
      }
    });
  }
  
  void tick() {
    
  }
  
  void render() {
    // background
    for(int y=0; y<Main.world.viewYSize; y++) {
      for(int x=0; x<Main.world.viewXSize; x++) {
        tiles[y][x].sprite.renderStatic();
      }
    }
    
    friendlySprite.renderStaticSized(3,3);
    enemySprite.renderStaticSized(3,3);
    
    // enemy health bar
    Main.ctx.fillRect(
      1*Sprite.scaledSpriteSize, 1*Sprite.scaledSpriteSize,
      8*(enemy.health/enemy.baseHealth)*Sprite.scaledSpriteSize, 4*Sprite.spriteScale
    );
    
    // friendly health bar
    Main.ctx.fillRect(
      11*Sprite.scaledSpriteSize, 10*Sprite.scaledSpriteSize,
      8*(friendly.health/friendly.baseHealth)*Sprite.scaledSpriteSize, 4*Sprite.spriteScale
    );
  }
}