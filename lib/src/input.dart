library Input;

import 'dart:html';

import 'package:dart_rpg/src/player.dart';

class Input {
  static var keys = [];
  
  static void handleKey(Player player) {
    if(keys.length == 0)
      return;
    
    switch(keys[0]) {
      case KeyCode.LEFT:
        player.move(Player.LEFT);
        break;
      case KeyCode.RIGHT:
        player.move(Player.RIGHT);
        break;
      case KeyCode.UP:
        player.move(Player.UP);
        break;
      case KeyCode.DOWN:
        player.move(Player.DOWN);
        break;
    }
  }
}