library dart_rpg.battle_game_event;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class BattleGameEvent implements GameEvent {
  static final String type = "battle";
  Function function, callback;
  
  BattleGameEvent([this.callback]);
  
  void trigger(Character character) {
    Gui.fadeLightAction((){},(){
      Gui.fadeDarkAction((){}, (){
        // start the battle!
        character.battler.reset();
        
        // TODO: reset enemy position if player loses
        // TODO: allow custom actions for win and lose
        Main.battle = new Battle(
            Main.player.battler,
            character.battler,
            new GameEvent((_) {
              character.sightDistance = 0;
              callback();
            }),
            false
        );
        
        Main.battle.start();
        Main.player.inputEnabled = true;
      });
    });
  }
  
  @override
  void handleKeys(List<int> keyCodes) {}
  
  // Editor functions
  
  @override
  List<String> getAttributes() {
    return [];
  }
  
  @override
  String getType() => type;
  
  @override
  String buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange) {
    return "";
  }
  
  static GameEvent buildGameEvent(String prefix) {
    BattleGameEvent battleGameEvent = new BattleGameEvent();
    
    return battleGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    
    return gameEventJson;
  }
}