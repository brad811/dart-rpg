library dart_rpg.interactable_tile;

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements InputHandler {
  // An input handler function that gets passed in to the constructor
  dynamic handler;
  String gameEventChain;
  
  InteractableTile(bool solid, Sprite sprite, void handler(List<int> keyCodes), [layered]) : super(solid, sprite, layered) {
    if(handler != null) {
      this.handler = handler;
    }
  }
  
  void interact() {}
  
  void close() {}
  
  void handleKeys(List<int> keyCodes) {
    handler(keyCodes);
  }
}