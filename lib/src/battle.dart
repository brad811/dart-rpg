library dart_rpg.battle;

import 'dart:async';
import 'dart:math' as math;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/delayed_game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class Battle implements InteractableInterface {
  String gameEventChain;
  List<List<Tile>> tiles = [];
  
  ChoiceGameEvent main, fight;
  GameEvent exit;
  Battler friendly, enemy;
  Sprite friendlySprite, enemySprite;
  
  GameEvent attackEvent;
  GameEvent postBattleCallback;
  
  math.Random rand = new math.Random();
  
  Battle(this.friendly, this.enemy, [this.postBattleCallback]) {
    friendlySprite = new Sprite.int(friendly.battlerType.spriteId, 3, 7);
    enemySprite = new Sprite.int(enemy.battlerType.spriteId, 14, 1);
    
    for(int y=0; y<Main.world.viewYSize; y++) {
      tiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        // TODO: move this to the editor
        tiles[y].add(new Tile(false, new Sprite.int(66, x, y)));
      }
    }
    
    exit = new GameEvent((callback) {
      Gui.clear();
      Main.inBattle = false;
      
      if(this.postBattleCallback != null) {
        this.postBattleCallback.trigger(this);
      } else {
        Main.focusObject = Main.player;
      }
    });
    
    // TODO: rebuild after leveling up
    Map<String, List<GameEvent>> attackChoices = new Map<String, List<GameEvent>>();
    for(int i=0; i<friendly.attacks.length; i++) {
      // create a game event that uses the current attack
      List<GameEvent> attackGameEventChain = [new GameEvent((callback) { attack(friendly, i); })];
      
      // add the generated game event chain name to the options in the choice game event
      attackChoices[friendly.attacks.keys.elementAt(i)] = attackGameEventChain;
    }
    
    fight = new ChoiceGameEvent.custom(
      this,
      ChoiceGameEvent.generateChoiceMap("battle_friendly_attack", attackChoices),
      5, 11, 10, 5
    );
    fight.remove = true;
    
    Function itemsConfirm = (Item selectedItem) {
      GameEvent itemUseConfirm = new GameEvent((Function callback) {
        selectedItem.use(friendly, new GameEvent((_) {
          // TODO: only show health change if health-changing item was used?
          Gui.clear();
          showHealthChange(friendly, () {
            attack(friendly, -1);
          });
        })).trigger(this);
      });
      
      Gui.clear();
      if(selectedItem != null) {
        new TextGameEvent.choice(237, "Use 1 ${selectedItem.name}?",
          new ChoiceGameEvent(
            ChoiceGameEvent.generateChoiceMap("battle_item_use", {
                "Yes": [itemUseConfirm],
                "No": []
              }
            )
          )
        ).trigger(this);
      } else {
        main.trigger(this);
      }
    };
    
    GameEvent items = new GameEvent((Function callback) {
      Gui.clear();
      GuiItemsMenu.trigger(Main.player, itemsConfirm);
    });
    
    // TODO: make it so that some battles cannot be run from
    // TODO: make running possibly fail
    main = new ChoiceGameEvent.custom(
      this,
      ChoiceGameEvent.generateChoiceMap("battle", {
        "Fight": [fight],
        "Powers": [fight],
        "Items": [items],
        "Run": [exit]
      }),
      15, 11, 5, 5
    );
    main.remove = false;
    
    // go back to the main screen from the fight screen
    fight.cancelEvent = main;
  }
  
  void start() {
    Main.inBattle = true;
    main.trigger(this);
  }
  
  void attack(Battler user, int attackNum) {
    Gui.clear();
    
    Function callback = () {
      Gui.clear();
      main.trigger(this);
    };
    
    // TODO: enemy decide action
    if(attackNum == -1) { // an item was used
      doAttack(enemy, friendly, true, rand.nextInt(enemy.attacks.length), callback);
    } else if(
        friendly.curSpeed > enemy.curSpeed || // friendly is faster
        (friendly.curSpeed == enemy.curSpeed && rand.nextBool()) // speed tie breaker
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
    Gui.clear();
    
    attacker.attacks.values.elementAt(attackNum).use(attacker, receiver, enemy, () {
      showHealthChange(receiver, callback);
    });
  }
  
  void showHealthChange(Battler battler, Function callback) {
    // make sure health stays in bounds
    if(battler.curHealth < 0)
      battler.curHealth = 0;
    
    if(battler.curHealth > battler.startingHealth)
      battler.curHealth = battler.startingHealth;
    
    List<DelayedGameEvent> healthDrains = [];
    for(int i=0; i<(battler.displayHealth - battler.curHealth).abs(); i++) {
      healthDrains.add(
        new DelayedGameEvent(Main.timeDelay, () {
          if(battler.displayHealth > battler.curHealth)
            battler.displayHealth--;
          else
            battler.displayHealth++;
        })
      );
    }
    
    healthDrains.add(
      new DelayedGameEvent(200, () {
        if(battler.curHealth <= 0) {
          if(battler == friendly)
            friendlyDie();
          else
            enemyDie();
        } else {
          callback();
        }
      })
    );
    
    DelayedGameEvent.executeDelayedEvents(healthDrains);
  }
  
  void friendlyDie() {
    Gui.fadeDarkAction(() {
      Main.inBattle = false;
      new HealGameEvent(Main.player, 9999, () {
        Gui.clear();
        Main.world.curMap = Main.player.startMap;
        Main.player.warp(Main.player.startMap, Main.player.startX, Main.player.startY, World.LAYER_PLAYER, Character.DOWN);
        Main.focusObject = Main.player;
      }).trigger(Main.player);
    });
  }
  
  void enemyDie() {
    friendly.experience += enemy.experiencePayout;
    TextGameEvent victory =
      new TextGameEvent(240, "${friendly.name} gained ${enemy.experiencePayout} experience points!");
    
    victory.callback = () {
      showExperienceGain(friendly.displayExperience, () {
        fadeOutExit();
      });
    };
    
    victory.trigger(this);
  }
  
  void fadeOutExit() {
    Gui.fadeDarkAction(() {
      exit.trigger(this);
    });
  }
  
  void tick() {
    
  }
  
  void showExperienceGain(int originalExperience, callback) {
    if(friendly.displayExperience < friendly.experience) {
      friendly.displayExperience += math.max(1, ((friendly.experience - originalExperience) / (1000 / Main.timeDelay)).round());
      
      // don't go over
      if(friendly.displayExperience > friendly.experience) {
        friendly.displayExperience = friendly.experience;
      }
      
      if(friendly.displayExperience >= friendly.nextLevelExperience()) {
        // TODO: show stat gains
        new TextGameEvent(240, "${friendly.battlerType.name} grew to level ${ friendly.level + 1 }!", () {
          friendly.levelUp(() {
            new Timer(new Duration(milliseconds: Main.timeDelay), () => showExperienceGain(originalExperience, callback));
          });
        }).trigger(this);
      } else {
        new Timer(new Duration(milliseconds: Main.timeDelay), () => showExperienceGain(originalExperience, callback));
      }
    } else {
      new Timer(new Duration(seconds: 1), () => callback());
    }
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
      (Main.player.battler.displayExperience - friendly.curLevelExperience()) /
      (friendly.nextLevelExperience() - friendly.curLevelExperience());
    Main.ctx.fillRect(
      11*Sprite.scaledSpriteSize - Sprite.spriteScale, 10.5*Sprite.scaledSpriteSize,
      ratio*(8*Sprite.scaledSpriteSize + Sprite.spriteScale*2), 2*Sprite.spriteScale + Sprite.spriteScale*2
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
    Main.ctx.setFillColorRgb(255, 255, 255);
    Main.ctx.fillRect(
      15*Sprite.spriteScale, 0*Sprite.scaledSpriteSize,
      130*Sprite.spriteScale, 1*Sprite.scaledSpriteSize
    );
    
    
    double levelTextAdjust = 0.75 * (enemy.level.toString().length - 1);
    Font.renderStaticText(14.6 - levelTextAdjust, 0.8, "Lv ${enemy.level}");
    
    Font.renderStaticText(2.3, 0.8, "${enemy.battlerType.name}");
    drawHealthBar(1, 1, enemy.displayHealth/enemy.startingHealth);
    
    // friendly health bar
    Main.ctx.setFillColorRgb(255, 255, 255);
    Main.ctx.fillRect(
      175*Sprite.spriteScale, 8.125*Sprite.scaledSpriteSize,
      130*Sprite.spriteScale, 2*Sprite.scaledSpriteSize
    );
    
    Font.renderStaticText(22.25, 17.0, "${friendly.battlerType.name}");
    
    levelTextAdjust = 0.75 * (friendly.level.toString().length - 1);
    Font.renderStaticText(34.6 - levelTextAdjust, 17.0, "Lv ${friendly.level}");
    
    Font.renderStaticText(22.25, 18.75, "${friendly.displayHealth}");
    Font.renderStaticText(37.6 - ("${friendly.startingHealth}".length)*0.75, 18.75, "${friendly.startingHealth}");
    
    drawHealthBar(11, 10, friendly.displayHealth/friendly.startingHealth);
    
    drawExperienceBar();
  }
}