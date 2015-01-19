library Input;

import 'package:dart_rpg/src/input_handler.dart';

class Input {
  static var keys = [];
  
  static void handleKey(InputHandler focusObject) {
    if(keys.length == 0)
      return;
    
    focusObject.handleKey(keys[0]);
  }
}