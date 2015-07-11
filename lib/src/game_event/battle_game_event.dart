library dart_rpg.store_game_event;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class StoreGameEvent extends GameEvent {
  Character character;
  
  StoreGameEvent(this.character, [Function callback]) : super(null, callback);
  
  void trigger() {
    Gui.fadeLightAction((){},(){
      Gui.fadeDarkAction((){}, (){
        // start the battle!
        character.battler.reset();
        
        Main.battle = new Battle(
            Main.player.battler,
            character.battler,
            character.postBattleEvent
        );
        
        Main.battle.start();
        Main.player.inputEnabled = true;
      });
    });
  }
}