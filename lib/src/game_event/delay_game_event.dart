library dart_rpg.delay_game_event;

import 'dart:async';

import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class DelayGameEvent implements GameEvent {
  static final String type = "delay";
  Function function, callback;
  
  int milliseconds;
  
  DelayGameEvent(this.milliseconds, [this.callback]);
  
  void trigger(InteractableInterface interactable, [Function function]) {
    Main.player.inputEnabled = false;
    Future future = new Future.delayed(new Duration(milliseconds: milliseconds), () {});
    
    future.then((_) {
      Main.player.inputEnabled = true;
      callback();
    });
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  List<String> getAttributes() {
    return ["milliseconds"];
  }
  
  @override
  String getType() => type;
  
  @override
  String buildHtml(String prefix, bool readOnly) {
    String html = "";
    
    String readOnlyString = "";
    if(readOnly) {
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Milliseconds</td></tr>";
    html += "  <tr>";
    
    // milliseconds
    html += "    <td><input type='text' class='number' id='${prefix}_milliseconds' value='${milliseconds}' ${readOnlyString} /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    DelayGameEvent delayGameEvent = new DelayGameEvent(
        Editor.getTextInputIntValue("#${prefix}_milliseconds", 100)
      );
    
    return delayGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["milliseconds"] = milliseconds;
    
    return gameEventJson;
  }
}