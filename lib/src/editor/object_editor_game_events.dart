library dart_rpg.object_editor_game_events;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/battle_game_event.dart';
import 'package:dart_rpg/src/game_event/chain_game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/delay_game_event.dart';
import 'package:dart_rpg/src/game_event/fade_game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/move_game_event.dart';
import 'package:dart_rpg/src/game_event/store_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

import 'editor.dart';
import 'object_editor.dart';

// TODO: warp game event

class ObjectEditorGameEvents {
  static List<String> advancedTabs = ["game_event_chain_game_events"];
  static Map<String, StreamSubscription> listeners = {};
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    querySelector("#add_game_event_chain_button").onClick.listen(addGameEventChain);
    querySelector("#add_game_event_button").onClick.listen(addGameEvent);
  }
  
  static void addGameEventChain(MouseEvent e) {
    if(World.gameEventChains["new game event chain"] == null)
      World.gameEventChains["new game event chain"] = [new TextGameEvent(1, "Text")];
    
    update();
    ObjectEditor.update();
  }
  
  static void addGameEvent(MouseEvent e) {
    List<GameEvent> selectedGameEventChain = World.gameEventChains.values.elementAt(selected);
    
    selectedGameEventChain.add(
        new TextGameEvent(1, "Text")
    );
    
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
    
    Editor.setMapDeleteButtonListeners(World.gameEventChains, "game_event_chain", listeners);
    
    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      Editor.setListDeleteButtonListeners(
          World.gameEventChains.values.elementAt(i),
          "game_event_chain_${i}_game_event",
          listeners
        );
    }
    
    List<String> attrs = ["label"];
    
    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      Editor.attachListeners(listeners, "game_event_chain_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      querySelector("#game_event_chain_row_${i}").onClick.listen((Event e) {
        selected = i;
        
        for(int j=0; j<World.gameEventChains.keys.length; j++) {
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
      
      List<GameEvent> gameEventChain = World.gameEventChains.values.elementAt(i);
      
      // game events
      for(int j=0; j<gameEventChain.length; j++) {
        List<String> gameEventAttrs = ["type"];
        
        gameEventAttrs.addAll(ObjectEditorGameEvents.getAttributes(gameEventChain[j]));
        
        Editor.attachListeners(listeners, "game_event_chain_${i}_game_event_${j}", gameEventAttrs, onInputChange);
        
        if(gameEventChain.elementAt(j) is ChoiceGameEvent) {
          querySelector("#game_event_chain_${i}_game_event_${j}_add_choice").onClick.listen((MouseEvent e) {
            if(World.gameEventChains.keys.length > 0) {
              ChoiceGameEvent choiceGameEvent = gameEventChain.elementAt(j) as ChoiceGameEvent;
              if(choiceGameEvent.choiceGameEventChains["New choice"] == null) {
                choiceGameEvent.choiceGameEventChains["New choice"] = World.gameEventChains.keys.first;
                Editor.update();
              }
            }
          });
        }
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
    
    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      String key = World.gameEventChains.keys.elementAt(i);
      
      gameEventChainsHtml +=
        "<tr id='game_event_chain_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input id='game_event_chain_${i}_label' type='text' value='${ key }' /></td>"+
        "  <td>${ World.gameEventChains[key].length }</td>"+
        "  <td><button id='delete_game_event_chain_${i}'>Delete</button></td>"+
        "</tr>";
    }
    
    gameEventChainsHtml += "</table>";
    
    querySelector("#game_event_chains_container").setInnerHtml(gameEventChainsHtml);
  }
  
  static void buildGameEventHtml() {
    String gameEventHtml = "";
    
    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      List<GameEvent> gameEventChain = World.gameEventChains.values.elementAt(i);
      
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
      
      if(target.id.contains("_label") && World.gameEventChains.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.gameEventChains.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      }
    }
    
    World.gameEventChains = new Map<String, List<GameEvent>>();
    for(int i=0; querySelector('#game_event_chain_${i}_label') != null; i++) {
      try {
        List<GameEvent> gameEventChain = new List<GameEvent>();
        for(int j=0; querySelector('#game_event_chain_${i}_game_event_${j}_type') != null; j++) {
          gameEventChain.add(
              ObjectEditorGameEvents.buildGameEvent("game_event_chain_${i}_game_event_${j}", Main.player)
            );
        }
        
        String label = Editor.getTextInputStringValue('#game_event_chain_${i}_label');
        
        World.gameEventChains[label] = gameEventChain;
      } catch(e) {
        // could not update this game event chain
        print("Error updating game event chain: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Object> gameEventChainsJson = {};
    World.gameEventChains.forEach((String key, List<GameEvent> gameEventChain) {
      
      // game event
      List<Map<String, String>> gameEventsJson = [];
      gameEventChain.forEach((GameEvent gameEvent) {
        gameEventsJson.add(
            ObjectEditorGameEvents.buildGameEventJson(gameEvent)
          );
      });
      
      gameEventChainsJson[key] = gameEventsJson;
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
    } else if(gameEvent is BattleGameEvent) {
      return [];
    } else if(gameEvent is ChainGameEvent) {
      return ["game_event_chain"];
    } else if(gameEvent is ChoiceGameEvent) {
      //TODO: List<String> attrs = ["cancel_event"];
      List<String> attrs = [];
      
      for(int i=0; i<gameEvent.choiceGameEventChains.keys.length; i++) {
        attrs.add("choice_name_${i}");
        attrs.add("chain_name_${i}");
      }
      
      return attrs;
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
      StoreGameEvent storeGameEvent = new StoreGameEvent();
      
      return storeGameEvent;
    } else if(gameEventType == "battle") {
      BattleGameEvent battleGameEvent = new BattleGameEvent();
      
      return battleGameEvent;
    } else if(gameEventType == "chain") {
      ChainGameEvent chainGameEvent = new ChainGameEvent(
          Editor.getSelectInputStringValue("#${prefix}_game_event_chain")
        );
      
      return chainGameEvent;
    } else if(gameEventType == "choice") {
      Map<String, String> choices = new Map<String, String>();
      for(int i=0; querySelector("#${prefix}_choice_name_${i}") != null; i++) {
        String choiceName = Editor.getTextInputStringValue("#${prefix}_choice_name_${i}");
        String chainName = Editor.getSelectInputStringValue("#${prefix}_chain_name_${i}");
        
        choices[choiceName] = chainName;
      }
      
      ChoiceGameEvent choiceGameEvent = new ChoiceGameEvent(choices);
      
      return choiceGameEvent;
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
    } else if(gameEvent is BattleGameEvent) {
      gameEventJson["type"] = "battle";
    } else if(gameEvent is ChainGameEvent) {
      gameEventJson["type"] = "chain";
      gameEventJson["game_event_chain"] = gameEvent.gameEventChain;
    } else if(gameEvent is ChoiceGameEvent) {
      gameEventJson["type"] = "choice";
      gameEventJson["choices"] = gameEvent.choiceGameEventChains;
      gameEventJson["cancel_event"] = gameEvent.cancelEvent;
    }
    
    return gameEventJson;
  }
  
  static String buildGameEventTableRowHtml(GameEvent gameEvent, String prefix, int num, {bool readOnly: false}) {
    String gameEventHtml = "";
    gameEventHtml += "<tr>";
    gameEventHtml += "  <td>${num}</td>";
    
    String disabledString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
    }
    
    gameEventHtml += "  <td><select id='${prefix}_type' ${disabledString}>";
    
    String paramsHtml = "";
    
    List<String> gameEventTypes = ["text", "move", "delay", "fade", "heal", "store", "battle", "chain", "choice", "warp"];
    for(int k=0; k<gameEventTypes.length; k++) {
      String selectedText = "";
      if(gameEventTypes[k] == "text" && gameEvent is TextGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildTextGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "move" && gameEvent is MoveGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildMoveGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "delay" && gameEvent is DelayGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildDelayGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "fade" && gameEvent is FadeGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildFadeGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "heal" && gameEvent is HealGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildHealGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "store" && gameEvent is StoreGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildStoreGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "battle" && gameEvent is BattleGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildBattleGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "chain" && gameEvent is ChainGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildChainGameEventParamsHtml(gameEvent, prefix, readOnly);
      } else if(gameEventTypes[k] == "choice" && gameEvent is ChoiceGameEvent) {
        selectedText = "selected='selected'";
        paramsHtml = ObjectEditorGameEvents.buildChoiceGameEventParamsHtml(gameEvent, prefix, readOnly);
      }
      
      gameEventHtml += "    <option ${selectedText}>${gameEventTypes[k]}</option>";
    }
    
    gameEventHtml += "  </select></td>";
    gameEventHtml += "  <td>${paramsHtml}</td>";
    gameEventHtml += "  <td>";
    
    if(!readOnly) {
      gameEventHtml += "<button id='delete_${prefix}'>Delete</button>";
    }
    
    gameEventHtml += "</td>";
    gameEventHtml += "</tr>";
    
    return gameEventHtml;
  }
  
  static String buildTextGameEventParamsHtml(TextGameEvent textGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String readOnlyString = "";
    if(readOnly) {
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Picture Id</td><td>Text</td></tr>";
    html += "  <tr>";
    html += "    <td><input type='text' class='number' id='${prefix}_picture_id' value='${textGameEvent.pictureSpriteId}' ${readOnlyString} /></td>";
    html += "    <td><textarea id='${prefix}_text' ${readOnlyString}>${textGameEvent.text}</textarea>";
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildMoveGameEventParamsHtml(MoveGameEvent moveGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String disabledString = "";
    String readOnlyString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Direction</td><td>Distance</td></tr>";
    html += "  <tr>";
    
    // direction
    html += "<td><select id='${prefix}_direction' ${disabledString}>";
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
    html += "    <td><input type='text' class='number' id='${prefix}_distance' value='${moveGameEvent.distance}' ${readOnlyString} /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildDelayGameEventParamsHtml(DelayGameEvent delayGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String readOnlyString = "";
    if(readOnly) {
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Milliseconds</td></tr>";
    html += "  <tr>";
    
    // milliseconds
    html += "    <td><input type='text' class='number' id='${prefix}_milliseconds' value='${delayGameEvent.milliseconds}' ${readOnlyString} /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildFadeGameEventParamsHtml(FadeGameEvent fadeGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String disabledString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
    }
    
    html += "<table>";
    html += "  <tr><td>Fade Type</td></tr>";
    html += "  <tr>";
    
    // fade type
    html += "<td><select id='${prefix}_fade_type' ${disabledString}>";
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
  
  static String buildHealGameEventParamsHtml(HealGameEvent healGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String disabledString = "";
    String readOnlyString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Character</td><td>Amount</td></tr>";
    html += "  <tr>";
    
    // character
    html += "<td><select id='${prefix}_character' ${disabledString}>";
    html += "  <option value='Player'>Player</option>";
    html += "</select></td>";
    
    // amount
    html += "    <td><input type='text' class='number' id='${prefix}_amount' value='${healGameEvent.amount}' ${readOnlyString} /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildStoreGameEventParamsHtml(StoreGameEvent storeGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    return html;
  }
  
  static String buildBattleGameEventParamsHtml(BattleGameEvent battleGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    return html;
  }
  
  static String buildChainGameEventParamsHtml(ChainGameEvent chainGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String disabledString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
    }
    
    html += "<table>";
    html += "  <tr><td>Game Event Chain</td></tr>";
    html += "  <tr>";
    
    // game event chain
    html += "<td><select id='${prefix}_game_event_chain' ${disabledString}>";
    World.gameEventChains.keys.forEach((String key) {
      html += "<option value='${key}'";
      if(chainGameEvent.gameEventChain == key) {
        html += " selected";
      }
      
      html += ">${key}</option>";
    });
    
    html += "</select></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static String buildChoiceGameEventParamsHtml(ChoiceGameEvent choiceGameEvent, String prefix, bool readOnly) {
    String html = "";
    
    String disabledString = "";
    String readOnlyString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Choice Name</td><td>Game Event Chain</td></tr>";
    
    int i = 0;
    choiceGameEvent.choiceGameEventChains.forEach((String choiceName, String chainName) {
      // choice name
      html += "<tr><td>";
      html += "<input type='text' id='${prefix}_choice_name_${i}' value='${choiceName}' ${readOnlyString} />";
      html += "</td>";
      
      // game event chain
      html += "<td><select id='${prefix}_chain_name_${i}' ${disabledString}>";
      
      World.gameEventChains.keys.forEach((String key) {
        html += "<option value='${key}'";
        if(chainName == key) {
          html += " selected";
        }
        
        html += ">${key}</option>";
      });
      
      html += "</select></td></tr>";
      
      i += 1;
    });
    
    html += "</table>";
    
    html += "<br /><button id='${prefix}_add_choice'>Add choice</button>";
    
    return html;
  }
}