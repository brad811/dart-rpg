library dart_rpg.battle_game_event;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class BattleGameEvent extends GameEvent {
  BattleGameEvent([Function callback]) : super(null, callback);
  
  void trigger(Character character) {
    Gui.fadeLightAction((){},(){
      Gui.fadeDarkAction((){}, (){
        // start the battle!
        character.battler.reset();
        
        // TODO: reset enemy position if player loses
        // TODO: set enemy as defeated so they don't attack again
        Main.battle = new Battle(
            Main.player.battler,
            character.battler,
            new GameEvent((_) { callback(); })
        );
        
        Main.battle.start();
        Main.player.inputEnabled = true;
      });
    });
  }
}