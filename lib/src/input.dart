library Input;

import 'dart:html';

import 'package:dart_rpg/src/input_handler.dart';

class Input {
  static List<int> keys = [];
  
  static void handleKey(InputHandler focusObject) {
    if(keys.length == 0)
      return;
    
    focusObject.handleKey(keys[0]);
    
    List<int> toRemove = [];
    Iterator<int> it = keys.iterator;
    while(it.moveNext()) {
      if(it.current != KeyCode.LEFT && it.current != KeyCode.RIGHT &&
          it.current != KeyCode.UP && it.current != KeyCode.DOWN) {
        toRemove.add(it.current);
      }
    }
    
    for(int key in toRemove) {
      keys.remove(key);
    }
  }
}