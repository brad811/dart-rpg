library dart_rpg.battle;

import 'dart:async';
import 'dart:math' as math;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/delayed_game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

import 'package:dart_rpg/src/screen/battle_screen.dart';

class Battle extends Interactable {
  String gameEventChain;
  BattleScreen battleScreen;
  
  ChoiceGameEvent main, fight;
  GameEvent run, exit;
  Battler friendly, enemy;
  bool canRun;
  
  GameEvent attackEvent;
  GameEvent postBattleCallback;
  
  math.Random rand = new math.Random();
  
  Battle(this.friendly, this.enemy, [this.postBattleCallback, this.canRun = true]) {
    battleScreen = new BattleScreen(this.friendly, this.enemy);
    
    exit = new GameEvent((callback) {
      Gui.clear();
      Main.inBattle = false;
      
      if(this.postBattleCallback != null) {
        this.postBattleCallback.trigger(this);
      } else {
        Main.focusObject = Main.player;
      }
    });
    
    run = new GameEvent((callback) {
      if(this.canRun) {
        Gui.clear();
        new TextGameEvent(240, "You were able to escape!", () { exit.trigger(this); }).trigger(this);
      } else {
        Gui.clear();
        new TextGameEvent(240, "You cannot run away from this battle!", () { main.trigger(this); }).trigger(this);
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
      GuiItemsMenu.trigger(Main.player.character, itemsConfirm);
    });
    
    // TODO: make running possibly fail
    main = new ChoiceGameEvent.custom(
      this,
      ChoiceGameEvent.generateChoiceMap("battle", {
        "Fight": [fight],
        "Powers": [fight],
        "Items": [items],
        "Run": [run]
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
      new HealGameEvent(Main.player.character, 9999, () {
        Gui.clear();
        Main.world.curMap = Main.player.character.startMap;
        Main.player.character.warp(
          Main.player.character.startMap, Main.player.character.startX, Main.player.character.startY, World.LAYER_PLAYER, Character.DOWN);
        Main.focusObject = Main.player;
      }).trigger(Main.player.character);
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
  
  void render() {
    battleScreen.render();
  }
}