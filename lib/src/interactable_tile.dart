library InteractableTile;

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements Interactable, InputHandler {
  static final int
    ACTION_CONTINUE = 0;
  
  var handler;
  
  InteractableTile(bool solid, Sprite sprite, void handler(List<int> keyCodes)) : super(solid, sprite) {
    this.handler = handler;
  }
  
  void interact() {
    Main.focusObject = this;
    Gui.inConversation = true;
  }
  
  void close() {
    Main.focusObject = Main.player;
    Gui.inConversation = false;
  }
  
  void handleKeys(List<int> keyCodes) {
    handler(keyCodes);
  }
}