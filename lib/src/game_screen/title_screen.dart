library dart_rpg.title_screen;

import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';

import 'package:dart_rpg/src/game_screen/game_screen.dart';

class TitleScreen extends GameScreen {
  TitleScreen() {
    // TODO: move to editor
    for(int y=0; y<Main.world.viewYSize; y++) {
      backgroundTiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        backgroundTiles[y].add(new Tile(false, new Sprite.int(66, x, y)));
      }
    }
  }
  
  @override
  void render() {
    super.render();
    
    // TODO: render text, options
  }
  
  void trigger() {
    // TODO: enable other custom choice game event borders and text alignments
    Map<String, List<GameEvent>> choices = {
      "New Game": [new GameEvent(newGame)]
    };
    
    if(window.localStorage.containsKey("saved_game")) {
      choices["Load Game"] = [new GameEvent(loadGame)];
    }
    
    new ChoiceGameEvent(
      ChoiceGameEvent.generateChoiceMap("battle_item_use", choices)
    ).trigger(this);
  }
  
  void newGame(callback) {
    Main.onTitleScreen = false;
    Main.focusObject = Main.player;
  }
  
  void loadGame(callback) {
    Main.world.loadGameProgress();
    Main.world.curMap = Main.player.character.map;
    Main.onTitleScreen = false;
    Main.focusObject = Main.player;
  }
}