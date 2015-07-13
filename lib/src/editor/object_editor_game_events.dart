library dart_rpg.object_editor_game_events;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/delay_game_event.dart';
import 'package:dart_rpg/src/game_event/fade_game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/move_game_event.dart';
import 'package:dart_rpg/src/game_event/store_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

import 'editor.dart';
import 'object_editor.dart';

class ObjectEditorGameEvents {
  static Map<String, List<GameEvent>> gameEventChains = new Map<String, List<GameEvent>>();
  static List<String> advancedTabs = ["game_event_chain_game_events"];
  static Map<String, StreamSubscription> listeners = {};
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    querySelector("#add_game_event_chain_button").onClick.listen(addGameEventChain);
    querySelector("#add_game_event_button").onClick.listen(addGameEvent);
  }
  
  static void addGameEventChain(MouseEvent e) {
    if(gameEventChains["new game event chain"] == null)
      gameEventChains["new game event chain"] = [new TextGameEvent(1, "Text")];
    
    // TODO: needed?
    update();
    ObjectEditor.update();
  }
  
  static void addGameEvent(MouseEvent e) {
    List<GameEvent> selectedGameEventChain = gameEventChains.values.elementAt(selected);
    
    selectedGameEventChain.add(
        new TextGameEvent(1, "Text")
    );
    
    // TODO: needed?
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildMainHtml();
    buildGameEventHtml();
    
    // highlight the selected row
    if(querySelector("#game_event_chain_row_${selected}") != null) {
      querySelector("#game_event_chain_row_${selected}").classes.add("selected");
      querySelector("#game_event_chains_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(gameEventChains, "game_event_chain", listeners);
    
    for(int i=0; i<gameEventChains.keys.length; i++) {
      Editor.setListDeleteButtonListeners(
          gameEventChains.values.elementAt(i),
          "game_event_chain_${i}_game_event",
          listeners
        );
    }
    
    List<String> attrs = ["label"];
    
    for(int i=0; i<gameEventChains.keys.length; i++) {
      Editor.attachListeners(listeners, "game_event_chain_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      querySelector("#game_event_chain_row_${i}").onClick.listen((Event e) {
        selected = i;
        
        for(int j=0; j<gameEventChains.keys.length; j++) {
          // un-highlight other game event chain rows
          querySelector("#game_event_chain_row_${j}").classes.remove("selected");
          
          // hide the advanced tab tables for other game event chains
          querySelector("#game_event_chain_${j}_game_event_table").classes.add("hidden");
        }
        
        // hightlight the selected game event chain row
        querySelector("#game_event_chain_row_${i}").classes.add("selected");
        
        // show the game event chains advanced area
        querySelector("#game_event_chains_advanced").classes.remove("hidden");
        
        // show the advanced tables for the selected game event chain
        querySelector("#game_event_chain_${i}_game_event_table").classes.remove("hidden");
      });
      
      List<GameEvent> gameEventChain = gameEventChains.values.elementAt(i);
      
      // game events
      for(int j=0; j<gameEventChain.length; j++) {
        List<String> gameEventAttrs = ["type"];
        
        gameEventAttrs.addAll(ObjectEditorGameEvents.getAttributes(gameEventChain[j]));
        
        Editor.attachListeners(listeners, "game_event_chain_${i}_game_event_${j}", gameEventAttrs, onInputChange);
      }
    }
  }
  
  static void buildMainHtml() {
    String gameEventChainsHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Label</td>"+
      "    <td>Num Game Events</td>"+
      "    <td></td>"+
      "  </tr>";
    
    for(int i=0; i<gameEventChains.keys.length; i++) {
      String key = gameEventChains.keys.elementAt(i);
      
      gameEventChainsHtml +=
        "<tr id='game_event_chain_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input id='game_event_chain_${i}_label' type='text' value='${ key }' /></td>"+
        "  <td>${ gameEventChains[key].length }</td>"+
        "  <td><button id='delete_game_event_chain_${i}'>Delete</button></td>"+
        "</tr>";
    }
    
    gameEventChainsHtml += "</table>";
    
    querySelector("#game_event_chains_container").setInnerHtml(gameEventChainsHtml);
  }
  
  static void buildGameEventHtml() {
    String gameEventHtml = "";
    
    for(int i=0; i<gameEventChains.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      List<GameEvent> gameEventChain = gameEventChains.values.elementAt(i);
      
      gameEventHtml += "<table id='game_event_chain_${i}_game_event_table' ${visibleString}>";
      gameEventHtml += "<tr><td>Num</td><td>Event Type</td><td>Params</td><td></td></tr>";
      for(int j=0; j<gameEventChain.length; j++) {
        gameEventHtml += ObjectEditorGameEvents.buildGameEventTableRowHtml(gameEventChain[j], "game_event_chain_${i}_game_event_${j}", j);
      }
      
      gameEventHtml += "</table>";
    }
    
    querySelector("#game_event_chain_game_events_container").setInnerHtml(gameEventHtml);
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains("_label") && gameEventChains.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; gameEventChains.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      }
    }
    
    gameEventChains = new Map<String, List<GameEvent>>();
    for(int i=0; querySelector('#game_event_chain_${i}_label') != null; i++) {
      try {
        List<GameEvent> gameEventChain = new List<GameEvent>();
        for(int j=0; querySelector('#game_event_chain_${i}_game_event_${j}_type') != null; j++) {
          // TODO: change character at import
          gameEventChain.add(
              ObjectEditorGameEvents.buildGameEvent("game_event_chain_${i}_game_event_${j}", Main.player)
            );
        }
        
        String label = Editor.getTextInputStringValue('#game_event_chain_${i}_label');
        
        gameEventChains[label] = gameEventChain;
      } catch(e) {
        // could not update this game event chain
        print("Error updating game event chain: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> gameEventChainsJson = {};
    gameEventChains.forEach((String key, List<GameEvent> gameEventChain) {
      Map<String, Object> gameEventChainJson = {};
      
      // game event
      List<Map<String, String>> gameEventsJson = [];
      gameEventChain.forEach((GameEvent gameEvent) {
        gameEventsJson.add(
            ObjectEditorGameEvents.buildGameEventJson(gameEvent)
          );
      });
      
      gameEventChainJson[key] = gameEventsJson;
    });
    
    exportJson["gameEventChains"] = gameEventChainsJson;
  }
  
  static List<String> getAttributes(GameEvent gameEvent) {
    if(gameEvent is TextGameEvent) {
      return ["picture_id", "text"];
    } else if(gameEvent is MoveGameEvent) {
      return ["direction", "distance"];
    } else if(gameEvent is DelayGameEvent) {
      return ["milliseconds"];
    } else if(gameEvent is FadeGameEvent) {
      return ["fade_type"];
    } else if(gameEvent is HealGameEvent) {
      return ["character", "amount"];
    } else if(gameEvent is StoreGameEvent) {
      return [];
    } else {
      return [];
    }
  }
  
  static GameEvent buildGameEvent(String prefix, Character character) {
    String gameEventType = Editor.getSelectInputStringValue("#${prefix}_type");
    
    if(gameEventType == "text") {
      TextGameEvent textGameEvent = new TextGameEvent(
          Editor.getTextInputIntValue("#${prefix}_picture_id", 1),
          Editor.getTextAreaStringValue("#${prefix}_text")
        );
      
      return textGameEvent;
    } else if(gameEventType == "move") {
      MoveGameEvent moveGameEvent = new MoveGameEvent(
          character,
          Editor.getSelectInputIntValue("#${prefix}_direction", Character.DOWN),
          Editor.getTextInputIntValue("#${prefix}_distance", 1)
        );
      
      return moveGameEvent;
    } else if(gameEventType == "delay") {
      DelayGameEvent delayGameEvent = new DelayGameEvent(
          Editor.getTextInputIntValue("#${prefix}_milliseconds", 100)
        );
      
      return delayGameEvent;
    } else if(gameEventType == "fade") {
      FadeGameEvent fadeGameEvent = new FadeGameEvent(
          Editor.getSelectInputIntValue("#${prefix}_fade_type", 2)
        );
      
      return fadeGameEvent;
    } else if(gameEventType == "heal") {
      HealGameEvent healGameEvent = new HealGameEvent(
          Main.player, Editor.getTextInputIntValue("#${prefix}_amount", 0)
        );
      
      return healGameEvent;
    } else if(gameEventType == "store") {
      StoreGameEvent storeGameEvent = new StoreGameEvent(
          character
        );
      
      return storeGameEvent;
    } else {
      return null;
    }
  }
  
  static Map<String, Object> buildGameEventJson(GameEvent gameEvent) {
    Map<String, Object> gameEventJson = {};
    
    if(gameEvent is TextGameEvent) {
      gameEventJson["type"] = "text";
      gameEventJson["pictureId"] = gameEvent.pictureSpriteId;
      gameEventJson["text"] = gameEvent.text;
    } else if(gameEvent is MoveGameEvent) {
      gameEventJson["type"] = "move";
      gameEventJson["direction"] = gameEvent.direction;
      gameEventJson["distance"] = gameEvent.distance;
    } else if(gameEvent is DelayGameEvent) {
      gameEventJson["type"] = "delay";
      gameEventJson["milliseconds"] = gameEvent.milliseconds;
    } else if(gameEvent is FadeGameEvent) {
      gameEventJson["type"] = "fade";
      gameEventJson["fade_type"] = gameEvent.fadeType;
    } else if(gameEvent is HealGameEvent) {
      gameEventJson["type"] = "heal";
      gameEventJson["character"] = gameEvent.character.name;
      gameEventJson["amount"] = gameEvent.amount;
    } else if(gameEvent is StoreGameEvent) {
      gameEventJson["type"] = "store";
    }
    
    return gameEventJson;
  }
  
  static String buildGameEventTableRowHtml(GameEvent gameEvent, String prefix, int num) {
    String gameEventHtml = "";
    gameEventHtml += "<tr>";
    gameEventHtml += "  <td>${num}</td>";
    gameEventHtml += "  <td><select id='${prefix}_type'>";
    
    String paramsHtml = "";
    
    List<String> gameEventTypes = ["text", "move", "delay", "fade", "heal", "store", "warp"];
    for(int k=0; k<gameEventTypes.length; k++) {
      String selectedText = "";
      if(gameEventTypes[k] == "text" && gameEvent is TextGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildTextGameEventParamsHtml(gameEvent, prefix);
      } else if(gameEventTypes[k] == "move" && gameEvent is MoveGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildMoveGameEventParamsHtml(gameEvent, prefix);
      } else if(gameEventTypes[k] == "delay" && gameEvent is DelayGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildDelayGameEventParamsHtml(gameEvent, prefix);
      } else if(gameEventTypes[k] == "fade" && gameEvent is FadeGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildFadeGameEventParamsHtml(gameEvent, prefix);
      } else if(gameEventTypes[k] == "heal" && gameEvent is HealGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildHealGameEventParamsHtml(gameEvent, prefix);
      } else if(gameEventTypes[k] == "store" && gameEvent is StoreGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildStoreGameEventParamsHtml(gameEvent, prefix);
      }
      
      gameEventHtml += "    <option ${selectedText}>${gameEventTypes[k]}</option>";
    }
    
    gameEventHtml += "  </select></td>";
    gameEventHtml += "  <td>${paramsHtml}</td>";
    gameEventHtml += "  <td><button id='delete_${prefix}'>Delete</button></td>";
    gameEventHtml += "</tr>";
    
    return gameEventHtml;
  }
  
  static String buildTextGameEventParamsHtml(TextGameEvent textGameEvent, String prefix) {
    String html = "";
    
    html += "<table>";
    html += "  <tr><td>Picture Id</td><td>Text</td></tr>";
    html += "  <tr>";
    html += "    <td><input type='text' class='number' id='${prefix}_picture_id' value='${textGameEvent.pictureSpriteId}' /></td>";
    html += "    <td><textarea id='${prefix}_text'>${textGameEvent.text}</textarea>";
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildMoveGameEventParamsHtml(MoveGameEvent moveGameEvent, String prefix) {
    String html = "";
    
    html += "<table>";
    html += "  <tr><td>Direction</td><td>Distance</td></tr>";
    html += "  <tr>";
    
    // direction
    html += "<td><select id='${prefix}_direction'>";
    List<String> directions = ["Down", "Right", "Up", "Left"];
    for(int direction=0; direction<directions.length; direction++) {
      html += "<option value='${direction}'";
      if(moveGameEvent.direction == direction) {
        html += " selected";
      }
      
      html += ">${directions[direction]}</option>";
    }
    html += "</select></td>";
    
    // distance
    html += "    <td><input type='text' class='number' id='${prefix}_distance' value='${moveGameEvent.distance}' /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildDelayGameEventParamsHtml(DelayGameEvent delayGameEvent, String prefix) {
    String html = "";
    
    html += "<table>";
    html += "  <tr><td>Milliseconds</td></tr>";
    html += "  <tr>";
    
    // milliseconds
    html += "    <td><input type='text' class='number' id='${prefix}_milliseconds' value='${delayGameEvent.milliseconds}' /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildFadeGameEventParamsHtml(FadeGameEvent fadeGameEvent, String prefix) {
    String html = "";
    
    html += "<table>";
    html += "  <tr><td>Fade Type</td></tr>";
    html += "  <tr>";
    
    // fade type
    html += "<td><select id='${prefix}_fade_type'>";
    List<String> fadeTypes = ["Normal to white", "White to normal", "Normal to black", "Black to normal"];
    for(int fadeType=0; fadeType<fadeTypes.length; fadeType++) {
      html += "<option value='${fadeType}'";
      if(fadeGameEvent.fadeType == fadeType) {
        html += " selected";
      }
      
      html += ">${fadeTypes.elementAt(fadeType)}</option>";
    }
    html += "</select></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildHealGameEventParamsHtml(HealGameEvent healGameEvent, String prefix) {
    String html = "";
    
    html += "<table>";
    html += "  <tr><td>Character</td><td>Amount</td></tr>";
    html += "  <tr>";
    
    // character
    html += "<td><select id='${prefix}_character'>";
    html += "  <option value='Player'>Player</option>";
    html += "</select></td>";
    
    // amount
    html += "    <td><input type='text' class='number' id='${prefix}_amount' value='${healGameEvent.amount}' /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildStoreGameEventParamsHtml(StoreGameEvent storeGameEvent, String prefix) {
    String html = "";
    
    return html;
  }
}