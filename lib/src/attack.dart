library Attack;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/text_game_event.dart';

class Attack {
  final String name;
  final int power;
  
  TextGameEvent textGameEvent;
  
  Attack(this.name, this.power) {
    
  }
  
  void use(Battler user, Function callback) {
    textGameEvent = new TextGameEvent(241, "You attacked the enemy with ${name}!");
    textGameEvent.callback = callback;
    textGameEvent.trigger();
  }
}