library dart_rpg.chain_game_event;

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class ChainGameEvent implements GameEvent {
  static final String type = "chain";
  Function function, callback;
  
  String gameEventChain = "";
  bool makeDefault = false;
  
  ChainGameEvent(this.gameEventChain, this.makeDefault, [this.callback]);
  
  void trigger(InteractableInterface interactable, [Function function]) {
    List<GameEvent> gameEvents = World.gameEventChains[gameEventChain];
    if(gameEvents != null && gameEvents.length > 0) {
      if(makeDefault) {
        interactable.gameEventChain = gameEventChain;
      }
      
      Main.focusObject = null;
      Interactable.chainGameEvents(interactable, gameEvents).trigger(interactable);
    } else {
      callback();
    }
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  List<String> getAttributes() {
    return ["game_event_chain", "make_default"];
  }
  
  @override
  String getType() => type;
  
  @override
  String buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange) {
    String html = "";
    
    String disabledString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
    }
    
    html += "<table>";
    html += "  <tr><td>Game Event Chain</td><td>Make Default</td></tr>";
    html += "  <tr>";
    
    // game event chain
    html += "<td><select id='${prefix}_game_event_chain' ${disabledString}>";
    World.gameEventChains.keys.forEach((String key) {
      html += "<option value='${key}'";
      if(gameEventChain == key) {
        html += " selected";
      }
      
      html += ">${key}</option>";
    });
    
    html += "</select></td>";
    
    html += "<td><input id='${prefix}_make_default' type='checkbox' ";
    if(makeDefault) {
      html += "checked='checked' ";
    }
    html += "/></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    ChainGameEvent chainGameEvent = new ChainGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_game_event_chain"),
        Editor.getCheckboxInputBoolValue("#${prefix}_make_default")
      );
    
    return chainGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["gameEventChain"] = gameEventChain;
    gameEventJson["makeDefault"] = makeDefault;
    
    return gameEventJson;
  }
}