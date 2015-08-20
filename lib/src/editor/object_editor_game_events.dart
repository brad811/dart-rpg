library dart_rpg.object_editor_game_events;

import 'dart:html';

import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';

// TODO: map editing events (place/remove/change warps, signs, tiles, events)
// TODO: logic gate events IF this THEN gameEventChainA ELSE gameEventChainB
// TODO: text input game event

class ObjectEditorGameEvents {
  static List<String> advancedTabs = ["game_event_chain_game_events"];
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_game_event_chain_button", addGameEventChain);
    Editor.attachButtonListener("#add_game_event_button", addGameEvent);
    
    querySelector("#object_editor_game_event_chains_tab_header").onClick.listen((MouseEvent e) {
      ObjectEditorGameEvents.selectRow(0);
    });
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
    
    Editor.setMapDeleteButtonListeners(World.gameEventChains, "game_event_chain");
    
    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      String prefix = "game_event_chain_${i}_game_event";
      
      Editor.setListDeleteButtonListeners(
          World.gameEventChains.values.elementAt(i),
          prefix
        );
      
      List<GameEvent> chain = World.gameEventChains.values.elementAt(i);
      for(int j=0; j<chain.length; j++) {
        GameEvent event = chain.elementAt(j);
        if(event is ChoiceGameEvent) {
          Editor.setMapDeleteButtonListeners(
              event.choiceGameEventChains,
              "${prefix}_${j}_choice"
            );
        }
      }
    }
    
    List<String> attrs = ["label"];
    
    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      Editor.attachInputListeners("game_event_chain_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#game_event_chain_row_${i}", (Event e) {
        if(querySelector("#game_event_chain_row_${i}") != null) {
          selectRow(i);
        }
      });
      
      List<GameEvent> gameEventChain = World.gameEventChains.values.elementAt(i);
      
      // game events
      for(int j=0; j<gameEventChain.length; j++) {
        List<String> gameEventAttrs = ["type"];
        
        gameEventAttrs.addAll(gameEventChain[j].getAttributes());
        
        Editor.attachInputListeners("game_event_chain_${i}_game_event_${j}", gameEventAttrs, onInputChange);
        
        if(gameEventChain.elementAt(j) is ChoiceGameEvent) {
          Editor.attachButtonListener("#game_event_chain_${i}_game_event_${j}_add_choice", (MouseEvent e) {
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
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.gameEventChains.keys.length; j++) {
      // un-highlight other game event chain rows
      querySelector("#game_event_chain_row_${j}").classes.remove("selected");
      
      // hide the advanced tab tables for other game event chains
      querySelector("#game_event_chain_${j}_game_event_table").classes.add("hidden");
    }
    
    if(querySelector("#game_event_chain_row_${i}") == null) {
      return;
    }
    
    // hightlight the selected game event chain row
    querySelector("#game_event_chain_row_${i}").classes.add("selected");
    
    // show the game event chains advanced area
    querySelector("#game_event_chains_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected game event chain
    querySelector("#game_event_chain_${i}_game_event_table").classes.remove("hidden");
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
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_label", World.gameEventChains);
    
    World.gameEventChains = new Map<String, List<GameEvent>>();
    for(int i=0; querySelector('#game_event_chain_${i}_label') != null; i++) {
      try {
        List<GameEvent> gameEventChain = new List<GameEvent>();
        for(int j=0; querySelector('#game_event_chain_${i}_game_event_${j}_type') != null; j++) {
          gameEventChain.add(
              ObjectEditorGameEvents.buildGameEvent("game_event_chain_${i}_game_event_${j}")
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
            gameEvent.buildJson()
          );
      });
      
      gameEventChainsJson[key] = gameEventsJson;
    });
    
    exportJson["gameEventChains"] = gameEventChainsJson;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    String gameEventType = Editor.getSelectInputStringValue("#${prefix}_type");
    
    return GameEvent.buildGameEvent(gameEventType, prefix);
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
    
    for(int k=0; k<GameEvent.gameEventTypes.length; k++) {
      String selectedText = "";
      
      if(GameEvent.gameEventTypes[k] == gameEvent.getType()) {
        selectedText = "selected='selected'";
        paramsHtml = gameEvent.buildHtml(prefix, readOnly);
      }
      
      gameEventHtml += "    <option ${selectedText}>${GameEvent.gameEventTypes[k]}</option>";
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
}