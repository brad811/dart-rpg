library dart_rpg.title_screen;

import 'dart:html';

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';

import 'package:dart_rpg/src/game_screen/game_screen.dart';

class TitleScreen extends GameScreen implements InputHandler {
  TitleScreen() {
    // TODO: move to editor
    for(int y=0; y<Main.world.viewYSize; y++) {
      backgroundTiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        backgroundTiles[y].add(new Tile(false, new Sprite.int(66, x, y)));
      }
    }
  }

  static int mode = -1;

  @override
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.length != 1 && mode != 0)
      return;

    if(Input.lastGamepad == null || Input.lastGamepad.length == 0 || mode == -1)
      return;

    String buttonText = "";
    if(mode == 0) {
      buttonText = "CONFIRM";
    } else if(mode == 1) {
      Input.CONFIRM_BUTTON = keyCodes[0];
      buttonText = "BACK";
    } else if(mode == 2) {
      Input.BACK_BUTTON = keyCodes[0];
      buttonText = "LEFT";
    } else if(mode == 3) {
      Input.LEFT_BUTTON = keyCodes[0];
      buttonText = "RIGHT";
    } else if(mode == 4) {
      Input.RIGHT_BUTTON = keyCodes[0];
      buttonText = "UP";
    } else if(mode == 5) {
      Input.UP_BUTTON = keyCodes[0];
      buttonText = "DOWN";
    } else if(mode == 6) {
      Input.DOWN_BUTTON = keyCodes[0];
      buttonText = "START";
    } else if(mode == 7) {
      Input.START_BUTTON = keyCodes[0];
      mode = -1;
      Gui.clear();
      this.trigger();
      return;
    }

    mode++;

    Gui.clear();
    Gui.addWindow(() {
      Gui.renderWindow(
        0, 5,
        20, 5
      );
      
      Font.renderStaticText(2.0, 14.0, "Configuring: ${ Input.lastGamepad.substring(0, 31) }");
      Font.renderStaticText(2.0, 17.0, "Press a button for ${ buttonText }");
    });
  }
  
  @override
  void render() {
    super.render();
    
    // TODO: render text, options
  }
  
  void trigger() {
    // TODO: enable other custom choice game event borders and text alignments
    Map<String, List<GameEvent>> choices = {
      "New Game": [new GameEvent(newGame)],
      "Configure Input": [new GameEvent(configureInput)]
    };
    
    if(window.localStorage.containsKey("saved_game")) {
      choices["Load Game"] = [new GameEvent(loadGame)];
    }
    
    new ChoiceGameEvent(
      ChoiceGameEvent.generateChoiceMap("battle_item_use", choices)
    ).trigger(this);
  }
  
  void newGame(Function callback) {
    Main.onTitleScreen = false;
    Main.focusObject = Main.player;
  }

  void configureInput(Function callback) {
    Gui.clear();
    Gui.addWindow(() {
      Gui.renderWindow(
        0, 5,
        20, 5
      );
      
      Font.renderStaticText(2.0, 14.0, "Press a button on the controller you would like");
      Font.renderStaticText(2.0, 15.5, "to configure.");
    });

    Main.focusObject = this;
    mode = 0;
  }
  
  void loadGame(Function callback) {
    Main.world.loadGameProgress();
    Main.world.curMap = Main.player.getCurCharacter().map;
    Main.onTitleScreen = false;
    Main.focusObject = Main.player;
  }
}