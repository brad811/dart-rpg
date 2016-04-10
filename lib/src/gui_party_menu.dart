library dart_rpg.gui_party_menu;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';

class GuiPartyMenu {
  static bool backEnabled = true;

  static GameEvent party = new GameEvent((Function callback) {
    GameEvent callbackEvent = new GameEvent((Function c){
      callback();
    });

    Map<String, List<GameEvent>> partyChoices = new Map<String, List<GameEvent>>();
    for(Character character in Main.player.characters) {
      partyChoices.addAll({character.name: [callbackEvent]});
    }
    
    if(backEnabled) {
      partyChoices.addAll({"Back": [callbackEvent]});
    }
    
    ChoiceGameEvent partyChoice;

    partyChoice = new ChoiceGameEvent.custom(
      Main.player.getCurCharacter(),
      ChoiceGameEvent.generateChoiceMap("start_menu_party", partyChoices),
      0, 0,
      10, 10
    );
    
    partyChoice.trigger(Main.player.getCurCharacter());
  });

  static trigger(Function callback) {
    party.callback = callback;
    party.trigger(Main.player.getCurCharacter());
  }
}