library dart_rpg.input;

import 'dart:html';

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';

class Input {
  static final int
    CONFIRM = KeyCode.X,
    BACK = KeyCode.Z,
    LEFT = KeyCode.LEFT,
    RIGHT = KeyCode.RIGHT,
    UP = KeyCode.UP,
    DOWN = KeyCode.DOWN,
    START = KeyCode.ENTER;
  
  static List<int>
    keys = [],
    lastKeys = [],
    releasedKeys = [
      CONFIRM,
      BACK,
      LEFT,
      RIGHT,
      UP,
      DOWN,
      START
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
          (keys[i] == LEFT || keys[i] == RIGHT ||
          keys[i] == UP || keys[i] == DOWN ||
          keys[i] == BACK
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