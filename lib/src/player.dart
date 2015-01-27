library Player;

import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';

class Player extends Character implements InputHandler {
  Player(int posX, int posY) : super(posX, posY);
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(KeyCode.X))
      interact();
    
    for(int key in keyCodes) {
      if(keyCodes.contains(KeyCode.LEFT)) {
        move(Character.LEFT);
        return;
      }
      if(keyCodes.contains(KeyCode.RIGHT)) {
        move(Character.RIGHT);
        return;
      }
      if(keyCodes.contains(KeyCode.UP)) {
        move(Character.UP);
        return;
      }
      if(keyCodes.contains(KeyCode.DOWN)) {
        move(Character.DOWN);
        return;
      }
    }
  }
  
  void interact() {
    if(direction == Character.LEFT && Main.world.isInteractable(mapX-1, mapY)) {
      Main.world.interact(mapX-1, mapY);
    } else if(direction == Character.RIGHT && Main.world.isInteractable(mapX+1, mapY)) {
      Main.world.interact(mapX+1, mapY);
    } else if(direction == Character.UP && Main.world.isInteractable(mapX, mapY-1)) {
      Main.world.interact(mapX, mapY-1);
    } else if(direction == Character.DOWN && Main.world.isInteractable(mapX, mapY+1)) {
      Main.world.interact(mapX, mapY+1);
    }
  }
}