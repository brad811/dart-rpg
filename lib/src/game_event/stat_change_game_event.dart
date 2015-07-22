library dart_rpg.stat_change_game_event;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/interactable_interface.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class StatChangeGameEvent extends GameEvent {
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
      [Function callback]
    ) : super(null, callback);
  
  void trigger(InteractableInterface interactable) {
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
}