library dart_rpg.input;

import 'dart:html';

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/game_screen/title_screen.dart';

class Input {
  static final int
    CONFIRM = KeyCode.X,
    BACK = KeyCode.Z,
    LEFT = KeyCode.LEFT,
    RIGHT = KeyCode.RIGHT,
    UP = KeyCode.UP,
    DOWN = KeyCode.DOWN,
    START = KeyCode.ENTER;

  static List<int>
    keys = [],
    lastKeys = [],
    releasedKeys = [
      CONFIRM,
      BACK,
      LEFT,
      RIGHT,
      UP,
      DOWN,
      START
    ],
    allKeys = [
      CONFIRM, BACK,
      LEFT, RIGHT, UP, DOWN,
      START
    ],
    validKeys = [];


  static String lastGamepad = "";

  static int
    CONFIRM_BUTTON = -1,
    BACK_BUTTON = -1,
    LEFT_BUTTON = -1,
    RIGHT_BUTTON = -1,
    UP_BUTTON = -1,
    DOWN_BUTTON = -1,
    START_BUTTON = -1;
  
  static List<int>
    buttons = [],
    lastButtons = [],
    releasedButtons = [
      CONFIRM_BUTTON, BACK_BUTTON,
      LEFT_BUTTON, RIGHT_BUTTON, UP_BUTTON, DOWN_BUTTON,
      START_BUTTON
    ],
    validButtons = [];
  
  static void handleKey(InputHandler focusObject) {

    // Start Buttons
    buttons = [];

    List<Gamepad> gamepads = window.navigator.getGamepads();
    gamepads.forEach((Gamepad gamepad) {
      if(gamepad == null)
        return;

      List<GamepadButton> gamepadButtons = gamepad.buttons;
      for(int i=0; i<gamepadButtons.length; i++) {
        if(gamepadButtons[i].pressed) {
          lastGamepad = gamepad.id;
          buttons.add(i);
        } else if(!releasedButtons.contains(i)) {
          releasedButtons.add(i);
        }
      }
    });

    for(int i=0; i<lastButtons.length; i++) {
      if(!buttons.contains(lastButtons[i]) && !releasedButtons.contains(lastButtons[i])) {
        releasedButtons.add(lastButtons[i]);
      }
    }

    validButtons = [];
    for(int i=0; i<buttons.length; i++) {
      if(
        releasedButtons.contains(buttons[i]) ||
        // only allow holding buttons down if you're controlling the player
        (Main.focusObject == Main.player &&
          (buttons[i] == LEFT_BUTTON || buttons[i] == RIGHT_BUTTON ||
          buttons[i] == UP_BUTTON || buttons[i] == DOWN_BUTTON ||
          buttons[i] == BACK_BUTTON
          )
        )
      ) {
        validButtons.add(buttons[i]);
        releasedButtons.remove(buttons[i]);
      }
    }

    lastButtons = new List<int>.from(buttons);
    // End Buttons

    // find keys that have been released
    for(int i=0; i<lastKeys.length; i++) {
      if(!keys.contains(lastKeys[i]) && !releasedKeys.contains(lastKeys[i])) {
        releasedKeys.add(lastKeys[i]);
      }
    }
    
    // find valid keys (only arrow keys can be held down)
    validKeys = [];
    for(int i=0; i<keys.length; i++) {
      if(
        releasedKeys.contains(keys[i]) ||
        // only allow holding keys down if you're controlling the player
        (Main.focusObject == Main.player &&
          (keys[i] == LEFT || keys[i] == RIGHT ||
          keys[i] == UP || keys[i] == DOWN ||
          keys[i] == BACK
          )
        )
      ) {
        validKeys.add(keys[i]);
        releasedKeys.remove(keys[i]);
      }
    }
    
    if(TitleScreen.mode == -1) {
      for(int i=0; i<validButtons.length; i++) {
        if(!validKeys.contains(validButtons[i])) {
          if(validButtons[i] == CONFIRM_BUTTON)
            validKeys.add(CONFIRM);
          else if(validButtons[i] == BACK_BUTTON)
            validKeys.add(BACK);
          else if(validButtons[i] == LEFT_BUTTON)
            validKeys.add(LEFT);
          else if(validButtons[i] == RIGHT_BUTTON)
            validKeys.add(RIGHT);
          else if(validButtons[i] == UP_BUTTON)
            validKeys.add(UP);
          else if(validButtons[i] == DOWN_BUTTON)
            validKeys.add(DOWN);
          else if(validButtons[i] == START_BUTTON)
            validKeys.add(START);
        }
      }

      focusObject.handleKeys(validKeys);
    } else {
      focusObject.handleKeys(validButtons);
    }
    
    lastKeys = new List<int>.from(keys);
  }
}