library dart_rpg.sign;

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class Sign extends InteractableTile implements InputHandler {
  TextGameEvent textEvent;
  
  Sign(bool solid, Sprite sprite, int pictureSpriteId, String text) : super(solid, sprite, null) {
    textEvent = new TextGameEvent(pictureSpriteId, text, close);
  }
  
  void handleKeys(List<int> keyCodes) {
    textEvent.handleKeys(keyCodes);
  }
  
  void interact() {
    Main.focusObject = this;
    textEvent.trigger(this);
  }
  
  void close() {
    Main.focusObject = Main.player;
  }
}