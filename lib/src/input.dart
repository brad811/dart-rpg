library Input;

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/world.dart';

class Input {
  static var keys = [];
  
  static void handleKey(InputHandler focusObject, World world) {
    if(keys.length == 0)
      return;
    
    focusObject.handleKey(keys[0], world);
  }
}