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

// TODO: change it so that this is a list of game event chains that all contain a list of game events

class ObjectEditorGameEvents {
  static List<GameEvent> gameEvents = new List<GameEvent>();
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_game_event_button").onClick.listen(addGameEvent);
  }
  
  static void addGameEvent(MouseEvent e) {
    gameEvents.add(
        new TextGameEvent(1, "Text")
    );
    
    // TODO: needed?
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildGameEventHtml();
      
    // game events
    for(int i=0; i<gameEvents.length; i++) {
      List<String> gameEventAttrs = ["type"];
      
      gameEventAttrs.addAll(getAttributes(gameEvents[i]));
      
      Editor.attachListeners(listeners, "game_event_${i}", gameEventAttrs, onInputChange);
    }
  }
  
  static void buildGameEventHtml() {
    String gameEventHtml = "";
    
    gameEventHtml += "<table id='game_event_table' class='editor_table'>";
    gameEventHtml += "<tr><td>Num</td><td>Event Type</td><td>Params</td><td></td></tr>";
  
    for(int i=0; i<gameEvents.length; i++) {
      gameEventHtml += buildGameEventTableRowHtml(gameEvents[i], "game_event_${i}", i);
    }
    
    gameEventHtml += "</table>";
    
    querySelector("#game_events_container").setInnerHtml(gameEventHtml);
  }
  
  static void onInputChange(Event e) {
    gameEvents = new List<GameEvent>();
    for(int i=0; querySelector('#game_event_${i}_type') != null; i++) {
      // TODO: on import, change the character
      gameEvents.add(
          buildGameEvent("game_event_${i}", Main.player)
        );
    }
    
    Editor.updateAndRetainValue(e);
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