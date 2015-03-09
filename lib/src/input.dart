library Input;

import 'dart:html';

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';

class Input {
  static List<int>
    keys = [],
    lastKeys = [],
    releasedKeys = [
      KeyCode.X,
      KeyCode.Z,
      KeyCode.LEFT,
      KeyCode.RIGHT,
      KeyCode.UP,
      KeyCode.DOWN,
      KeyCode.ENTER
    ],
    validKeys = [];
  
  static void handleKey(InputHandler focusObject) {
    // find keys that have been released
    for(int i=0; i<lastKeys.length; i++) {
      if(!keys.contains(lastKeys[i]) && !releasedKeys.contains(lastKeys[i])) {
        releasedKeys.add(lastKeys[i]);
      }
    }
    
    // find valid keys (only arrow keys can be held down)
    validKeys = [];
    for(int i=0; i<keys.length; i++) {
      if(
        releasedKeys.contains(keys[i]) ||
        // only allow holding keys down if you're controlling the player
        (Main.focusObject == Main.player &&
          (keys[i] == KeyCode.LEFT || keys[i] == KeyCode.RIGHT ||
          keys[i] == KeyCode.UP || keys[i] == KeyCode.DOWN ||
          keys[i] == KeyCode.Z
          )
        )
      ) {
        validKeys.add(keys[i]);
        releasedKeys.remove(keys[i]);
      }
    }
    
    focusObject.handleKeys(validKeys);
    
    lastKeys = new List<int>.from(keys);
  }
}