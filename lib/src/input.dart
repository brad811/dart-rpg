library dart_rpg.input;

import 'dart:html';

import 'package:dart_rpg/src/gamepad_config.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/game_screen/title_screen.dart';

enum InputCode {
  CONFIRM, BACK, LEFT, RIGHT, UP, DOWN, START
}

class Input {

  static final Map<int, InputCode> keyMappings = {
    KeyCode.X: InputCode.CONFIRM,
    KeyCode.Z: InputCode.BACK,
    KeyCode.LEFT: InputCode.LEFT,
    KeyCode.RIGHT: InputCode.RIGHT,
    KeyCode.UP: InputCode.UP,
    KeyCode.DOWN: InputCode.DOWN,
    KeyCode.ENTER: InputCode.START
  };

  static List<int>
    keys = [],
    lastKeys = [],
    releasedKeys = new List.from(keyMappings.keys),
    allKeys = new List.from(keyMappings.keys);

  static String lastGamepad = "";

  static Map<String, GamepadConfig> gamepadConfigs = {};

  static void handleKey(InputHandler focusObject) {

    // Start Buttons
    List<Gamepad> gamepads = window.navigator.getGamepads();
    List<Gamepad> validGamepads = [];
    gamepads.forEach((Gamepad gamepad) {
      if(gamepad == null)
        return;

      if(!gamepadConfigs.containsKey(gamepad.id)) {
        gamepadConfigs[gamepad.id] = new GamepadConfig(gamepad);
      }

      validGamepads.add(gamepad);
    });
    // End Buttons

    // find keys that have been released
    for(int i=0; i<lastKeys.length; i++) {
      if(!keys.contains(lastKeys[i]) && !releasedKeys.contains(lastKeys[i])) {
        releasedKeys.add(lastKeys[i]);
      }
    }
    
    // find valid keys (only arrow keys can be held down)
    List<int> validKeys = [];
    for(int i=0; i<keys.length; i++) {
      if(
        releasedKeys.contains(keys[i]) ||
        // only allow holding keys down if you're controlling the player
        (Main.focusObject == Main.player &&
          (keyMappings[keys[i]] == InputCode.LEFT || keyMappings[keys[i]] == InputCode.RIGHT ||
          keyMappings[keys[i]] == InputCode.UP || keyMappings[keys[i]] == InputCode.DOWN ||
          keyMappings[keys[i]] == InputCode.BACK
          )
        )
      ) {
        validKeys.add(keys[i]);
        releasedKeys.remove(keys[i]);
      }
    }
    
    if(TitleScreen.mode == -1) {
      List<InputCode> validInputs = [];

      validKeys.forEach((int validKey) {
        validInputs.add(keyMappings[validKey]);
      });

      validGamepads.forEach((Gamepad gamepad) {
        validInputs.addAll(gamepadConfigs[gamepad.id].getValidButtons());
      });

      focusObject.handleInput(validInputs);
    } else {
      List<int> validButtons = [];
      validGamepads.forEach((Gamepad gamepad) {
        validButtons.addAll(gamepadConfigs[gamepad.id].getRawValidButtons());
      });

      Main.titleScreen.handleButtons(validButtons);
    }
    
    lastKeys = new List<int>.from(keys);
  }
}