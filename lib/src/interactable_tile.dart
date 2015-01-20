library InteractableTile;

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements Interactable, InputHandler {
  static final int
    ACTION_CLOSE = 0;
  
  var handler;
  
  InteractableTile(bool solid, Sprite sprite, void handler(int keyCode)) : super(solid, sprite) {
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
  
  void handleKey(int keyCode) {
    int action = handler(keyCode);
    // TODO: change to switch statement when enums are more stable
    if(action == ACTION_CLOSE) {
      close();
    }
  }
}