library dart_rpg.stat_change_game_event;

import 'dart:js';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/interactable.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

// TODO: implement

class StatChangeGameEvent implements GameEvent {
  static final String type = "stat";
  Function function, callback;
  
  Battler battler;
  int physicalAttachChange, physicalDefenseChange,
    magicalAttackChange, magicalDefenseChange,
    speedChange, healthChange;
  bool permanent;
  
  StatChangeGameEvent(this.battler,
      this.physicalAttachChange, this.physicalDefenseChange,
      this.magicalAttackChange, this.magicalDefenseChange,
      this.speedChange, this.healthChange,
      this.permanent,
      [this.callback]
    );
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    battler.curPhysicalAttack += physicalAttachChange;
    battler.curPhysicalDefense += physicalDefenseChange;
    battler.curMagicalAttack += magicalAttackChange;
    battler.curMagicalDefense += magicalDefenseChange;
    battler.curSpeed += speedChange;
    battler.curHealth += healthChange;
    
    if(permanent) {
      battler.startingPhysicalAttack += physicalAttachChange;
      battler.startingPhysicalDefense += physicalDefenseChange;
      battler.startingMagicalAttack += magicalAttackChange;
      battler.startingMagicalDefense += magicalDefenseChange;
      battler.startingSpeed += speedChange;
      battler.startingHealth += healthChange;
    }
    
    battler.displayHealth = battler.curHealth;
    
    callback();
  }
  
  @override
  void handleInput(List<InputCode> inputCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) { /* TODO */ return null; }
  
  GameEvent buildGameEvent(String prefix) { /* TODO */ return null; }
  
  @override
  Map<String, Object> buildJson() { /* TODO */ return null; }
}