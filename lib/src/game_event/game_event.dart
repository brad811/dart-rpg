library dart_rpg.game_event;

import 'dart:js';

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';

import 'package:dart_rpg/src/game_event/battle_game_event.dart';
import 'package:dart_rpg/src/game_event/chain_game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/delay_game_event.dart';
import 'package:dart_rpg/src/game_event/fade_game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/move_game_event.dart';
import 'package:dart_rpg/src/game_event/store_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

class GameEvent implements InputHandler {
  static final String type = "event";
  Function function, callback;
  
  static final List<String> gameEventTypes =
      ["text", "move", "delay", "fade", "heal", "store", "battle", "chain", "choice", "warp"];
  
  GameEvent([this.function, this.callback]);
  
  void trigger(Interactable interactable) {
    if(function != null) {
      function(callback);
    } else {
      function();
    }
  }
  
  void handleKeys(List<int> keyCodes) {}
  
  // Editor functions
  
  List<String> getAttributes() => [];
  
  String getType() => type;
  
  static GameEvent buildGameEvent(String type, String prefix) {
    if(type == BattleGameEvent.type) {
      return BattleGameEvent.buildGameEvent(prefix);
    } else if(type == ChainGameEvent.type) {
      return ChainGameEvent.buildGameEvent(prefix);
    } else if(type == ChoiceGameEvent.type) {
      return ChoiceGameEvent.buildGameEvent(prefix);
    } else if(type == DelayGameEvent.type) {
      return DelayGameEvent.buildGameEvent(prefix);
    } else if(type == FadeGameEvent.type) {
      return FadeGameEvent.buildGameEvent(prefix);
    } else if(type == HealGameEvent.type) {
      return HealGameEvent.buildGameEvent(prefix);
    } else if(type == MoveGameEvent.type) {
      return MoveGameEvent.buildGameEvent(prefix);
    } else if(type == StoreGameEvent.type) {
      return StoreGameEvent.buildGameEvent(prefix);
    } else if(type == TextGameEvent.type) {
      return TextGameEvent.buildGameEvent(prefix);
    } else if(type == WarpGameEvent.type) {
      return WarpGameEvent.buildGameEvent(prefix);
    } else {
      return null;
    }
  }
  
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) => null;
  
  Map<String, Object> buildJson() => {};
}