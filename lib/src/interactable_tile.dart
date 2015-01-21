library InteractableTile;

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements Interactable, InputHandler {
  // An input handler function that gets passed in to the constructor
  var handler;
  
  InteractableTile(bool solid, Sprite sprite, void handler(List<int> keyCodes)) : super(solid, sprite) {
    this.handler = handler;
  }
  
  void interact() {
    // Take input focus and show the GUI window
    Main.focusObject = this;
    Gui.inConversation = true;
  }
  
  void close() {
    // Set focus back on the player and hide the GUI window
    Main.focusObject = Main.player;
    Gui.inConversation = false;
  }
  
  void handleKeys(List<int> keyCodes) {
    handler(keyCodes);
  }
}