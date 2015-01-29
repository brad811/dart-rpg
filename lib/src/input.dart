library Input;

import 'dart:html';

import 'package:dart_rpg/src/input_handler.dart';

class Input {
  static List<int> keys = [];
  static List<int> lastKeys = [];
  static List<int> releasedKeys = [KeyCode.X, KeyCode.Z];
  static List<int> validKeys = [];
  
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
      if(releasedKeys.contains(keys[i]) ||
          keys[i] == KeyCode.LEFT || keys[i] == KeyCode.RIGHT ||
          keys[i] == KeyCode.UP || keys[i] == KeyCode.DOWN ) {
        validKeys.add(keys[i]);
        releasedKeys.remove(keys[i]);
      }
    }
    
    focusObject.handleKeys(validKeys);
    
    lastKeys = new List<int>.from(keys);
  }
}