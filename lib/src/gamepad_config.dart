library dart_rpg.gamepad_config;

import 'dart:html';

import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/main.dart';

class GamepadConfig {
  Gamepad gamepad;

  Map<int, InputCode> mappings = {};

  List<int>
    lastButtons = [],
    releasedButtons = [];

  GamepadConfig(this.gamepad);

  List<int> getRawValidButtons() {
    List<int> buttons = [], validButtons = [];
    List<GamepadButton> gamepadButtons = gamepad.buttons;

    for(int i=0; i<gamepadButtons.length; i++) {
      if(gamepadButtons[i].pressed) {
        Input.lastGamepad = gamepad.id;
        buttons.add(i);
      } else if(!releasedButtons.contains(i)) {
        releasedButtons.add(i);
      }
    }

    validButtons = [];
    for(int i=0; i<buttons.length; i++) {
      if(
        releasedButtons.contains(buttons[i]) ||
        // only allow holding buttons down if you're controlling the player
        (Main.focusObject == Main.player &&
          (mappings[buttons[i]] == InputCode.LEFT || mappings[buttons[i]] == InputCode.RIGHT ||
          mappings[buttons[i]] == InputCode.UP || mappings[buttons[i]] == InputCode.DOWN ||
          mappings[buttons[i]] == InputCode.BACK
          )
        )
      ) {
        validButtons.add(buttons[i]);
        releasedButtons.remove(buttons[i]);
      }
    }

    lastButtons = new List<int>.from(buttons);

    return validButtons;
  }

  List<InputCode> getValidButtons() {
    List<int> validButtons = getRawValidButtons();
    List<InputCode> translatedValidButtons = [];

    for(int i=0; i<validButtons.length; i++) {
      translatedValidButtons.add(mappings[validButtons[i]]);
    }

    return translatedValidButtons;
  }
}