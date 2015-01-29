library InteractableTile;

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements Interactable, InputHandler {
  // An input handler function that gets passed in to the constructor
  var handler;
  
  InteractableTile(bool solid, Sprite sprite, void handler(List<int> keyCodes)) : super(solid, sprite) {
    this.handler = handler;
  }
  
  void interact() {}
  
  void close() {}
  
  void handleKeys(List<int> keyCodes) {
    handler(keyCodes);
  }
}