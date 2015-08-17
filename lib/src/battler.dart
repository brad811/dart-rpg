library dart_rpg.battler;

import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class Battler {
  final BattlerType battlerType;
  
  String name;
  
  int
    startingHealth = 0,
    startingPhysicalAttack = 0,
    startingMagicalAttack = 0,
    startingPhysicalDefense = 0,
    startingMagicalDefense = 0,
    startingSpeed = 0,
    
    curHealth = 0,
    curPhysicalAttack = 0,
    curMagicalAttack = 0,
    curPhysicalDefense = 0,
    curMagicalDefense = 0,
    curSpeed = 0,
    
    healthProficiency = 0,
    physicalAttackProficiency = 0,
    magicalAttackProficiency = 0,
    physicalDefenseProficiency = 0,
    magicalDefenseProficiency = 0,
    speedProficiency = 0,
    
    level = 1,
    experience = 0,
    experiencePayout = 0,
    
    displayHealth = 0,
    displayExperience = 0;
  
  Map<String, Attack> attacks = {};
  
  Battler(this.name, this.battlerType, int level, List<Attack> attacks) {
    if(this.name == null)
      this.name = this.battlerType.name;
    
    startingHealth = battlerType.baseHealth;
    startingPhysicalAttack = battlerType.basePhysicalAttack;
    startingMagicalAttack = battlerType.baseMagicalAttack;
    startingPhysicalDefense = battlerType.basePhysicalDefense;
    startingMagicalDefense = battlerType.baseMagicalDefense;
    startingSpeed = battlerType.baseSpeed;
    
    for(Attack attack in attacks) {
      this.attacks[attack.name] = attack;
    }
    
    while(this.level < level)
      levelUp();
    
    experience = curLevelExperience();
    
    experiencePayout = (
      level * battlerType.rarity * battlerType.baseStatsSum() / 5 * 5
    ).round();
    
    reset();
  }
  
  void reset() {
    curHealth = startingHealth;
    curPhysicalAttack = startingPhysicalAttack;
    curMagicalAttack = startingMagicalAttack;
    curPhysicalDefense = startingPhysicalDefense;
    curMagicalDefense = startingMagicalDefense;
    curSpeed = startingSpeed;
    
    displayHealth = startingHealth;
    displayExperience = experience;
  }
  
  int levelExperience(int level) {
    return math.pow(level, 3);
  }
  
  int curLevelExperience() {
    return levelExperience(level);
  }
  
  int nextLevelExperience() {
    return levelExperience(level + 1);
  }
  
  void levelUp([Function callback]) {
    level += 1;

    int healthChange = (battlerType.baseHealth + (math.min(healthProficiency, 25))/5).round();
    startingHealth += healthChange;
    curHealth += healthChange;
    displayHealth += healthChange;
    
    int physicalAttackChange = (battlerType.basePhysicalAttack + (math.min(physicalAttackProficiency, 25))/5).round();
    startingPhysicalAttack += physicalAttackChange;
    curPhysicalAttack += physicalAttackChange;

    int magicalAttackChange = (battlerType.baseMagicalAttack + (math.min(magicalAttackProficiency, 25))/5).round();
    startingMagicalAttack += magicalAttackChange;
    curMagicalAttack += magicalAttackChange;
    
    int physicalDefenseChange = (battlerType.basePhysicalDefense + (math.min(physicalDefenseProficiency, 25))/5).round();
    startingPhysicalDefense += physicalDefenseChange;
    curPhysicalDefense += physicalDefenseChange;
    
    int magicalDefenseChange = (battlerType.baseMagicalDefense + (math.min(magicalDefenseProficiency, 25))/5).round();
    startingMagicalDefense += magicalDefenseChange;
    curMagicalDefense += magicalDefenseChange;
    
    int speedChange = (battlerType.baseSpeed + (math.min(speedProficiency, 25))/5).round();
    startingSpeed += speedChange;
    curSpeed += speedChange;
    
    learnNewAttacks(this.battlerType.levelAttacks[level], callback);
  }
  
  void learnNewAttacks(List<Attack> newAttacks, Function callback) {
    bool showText = callback != null;
    
    // there is at least 1 new attack available at this level
    if(newAttacks != null && newAttacks.length > 0) {
      // battler already knows this attack
      if(this.attacks.containsKey(newAttacks[0].name)) {
        if(newAttacks.length > 1) {
          learnNewAttacks(newAttacks.sublist(1), callback);
        } else if(callback != null) {
          callback();
        }
        
        return;
      }
      
      // check if battler has room to learn attack
      if(this.attacks.keys.length < 4) {
        this.attacks[ newAttacks[0].name ] = newAttacks[0];
        
        if(showText) {
          new TextGameEvent(240, "${ this.name } learned ${ newAttacks[0].name }!", () {
            if(newAttacks.length > 1) {
              learnNewAttacks(newAttacks.sublist(1), callback);
            } else {
              callback();
            }
          }).trigger(Main.player);
        } else {
          if(newAttacks.length > 1) {
            learnNewAttacks(newAttacks.sublist(1), callback);
          } else {
            return;
          }
        }
      } else {
        if(showText) {
          World.gameEventChains["____tmp_forget_move"] = [
            new TextGameEvent(240, "${ this.name } is trying to learn ${ newAttacks[0].name },"),
            new TextGameEvent(240, "but ${ this.name } already knows 4 moves."),
            new TextGameEvent.choice(240, "Forget a move to learn ${ newAttacks[0].name }?",
              new ChoiceGameEvent({
                "Yes": "____tmp_forget_move_yes",
                "No": "____tmp_forget_move_no"
              },
                cancelEvent: Interactable.chainGameEvents(Main.player, World.gameEventChains["____tmp_forget_move_no"])
              )
            )
          ];
          
          // build list of attacks and their delete actions
          Map<String, String> moveOptions = {};
          for(int i=0; i<attacks.keys.length; i++) {
            World.gameEventChains["____tmp_forget_move_${i}"] = [
              new TextGameEvent(240, "${ this.name } forgot ${ attacks.keys.elementAt(i) }, and..."),
              new GameEvent((callback) {
                // forget the old attack
                attacks.remove(attacks.keys.elementAt(i));
                
                // learn the new attack
                attacks[newAttacks[0].name] = newAttacks[0];
                
                callback();
              }),
              new TextGameEvent(240, "${ this.name } learned ${ newAttacks[0].name }!"),
              new GameEvent((_) {
                if(newAttacks.length > 1) {
                  learnNewAttacks(newAttacks.sublist(1), callback);
                } else {
                  callback();
                }
              })
            ];
            
            moveOptions[attacks.keys.elementAt(i)] = "____tmp_forget_move_${i}";
          }
          
          World.gameEventChains["____tmp_forget_move_yes"] = [
            new TextGameEvent.choice(240, "Which move should be forgotten?",
              new ChoiceGameEvent(
                moveOptions,
                cancelEvent: Interactable.chainGameEvents(Main.player, World.gameEventChains["____tmp_forget_move_no"])
              )
            )
          ];
          
          World.gameEventChains["____tmp_forget_move_no"] = [
            new TextGameEvent.choice(240, "Stop learning ${ newAttacks[0].name }?",
              new ChoiceGameEvent({
                "Yes": "____tmp_forget_move_cancel",
                "No": "____tmp_forget_move"
              })
            )
          ];
          
          World.gameEventChains["____tmp_forget_move_cancel"] = [
            new TextGameEvent(240, "${ this.name } did not learn ${ newAttacks[0].name }."),
            new GameEvent((_) {
              if(newAttacks.length > 1) {
                learnNewAttacks(newAttacks.sublist(1), callback);
              } else {
                callback();
              }
            })
          ];
          
          Interactable.chainGameEvents(Main.player, World.gameEventChains["____tmp_forget_move"]).trigger(Main.player);
        } else {
          // find the lowest level attack this battler still knows and replace it
          for(Attack attack in this.battlerType.levelAttacks.values) {
            if(this.attacks.keys.contains(attack)) {
              // forget the old attack
              attacks.remove(attack.name);
              
              // learn the new attack
              attacks[newAttacks[0].name] = newAttacks[0];
              
              if(newAttacks.length > 1) {
                learnNewAttacks(newAttacks.sublist(1), callback);
              }
              
              return;
            }
          }
          
          return;
        }
      }
    } else if(callback != null) {
      callback();
    }
  }
}