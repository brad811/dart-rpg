library dart_rpg.move_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class MoveGameEvent extends GameEvent {
  Character character;
  int direction;
  int distance;
  
  MoveGameEvent(this.character, this.direction, this.distance, [Function callback]) : super(null, callback);
  
  void trigger() {
    int traveled = 0;
    
    Main.player.inputEnabled = false;
    chainCharacterMovement(traveled);
  }
  
  void chainCharacterMovement(int traveled) {
    if(traveled >= distance) {
      Main.player.inputEnabled = true;
      callback();
    } else {
      character.move(direction);
      character.motionCallback = () {
        chainCharacterMovement(traveled + 1);
      };
    }
  }
}