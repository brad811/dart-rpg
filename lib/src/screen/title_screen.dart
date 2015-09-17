library dart_rpg.title_screen;

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';

import 'package:dart_rpg/src/screen/screen.dart';

class TitleScreen extends Screen {
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
    new ChoiceGameEvent(
      ChoiceGameEvent.generateChoiceMap("battle_item_use", {
          "New Game": [new GameEvent(newGame)]
        }
      )
    ).trigger(this);
  }
  
  void newGame(callback) {
    Main.onTitleScreen = false;
    Main.focusObject = Main.player;
  }
}