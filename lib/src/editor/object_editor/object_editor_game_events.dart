library dart_rpg.object_editor_game_events;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';

import 'package:react/react.dart';

// TODO: map editing events (place/remove/change warps, signs, tiles, events)
// TODO: character editing events (change gameEventChain, battler/level, inventory, name, size, picture/sprite)
// TODO: logic gate events IF this THEN gameEventChainA ELSE gameEventChainB
// TODO: text input game event

class ObjectEditorGameEventChainsComponent extends Component {
  void render() {
    List tableRows = [];

    tableRows.add(
      tr({}, [
        td({}, "Num"),
        td({}, "Label"),
        td({}, "Num Game events"),
        td({})
      ])
    );

    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      String key = World.gameEventChains.keys.elementAt(i);

      tableRows.add(
        tr({'id': 'game_event_chain_row_${i}'}, [
          td({}, i),
          td({},
            input({
              'id': 'game_event_chain_${i}_label',
              'type': 'text',
              'value': key
            })
          ),
          td({}, World.gameEventChains[key].length),
          td({},
            button({'id': 'delete_game_event_chain_${i}'}, "Delete")
          )
        ])
      );
    }

    return
      table({'className': 'editor_table'},
        tbody({}, tableRows)
      );
  }
}

var objectEditorGameEventChainsComponent = registerComponent(() => new ObjectEditorGameEventChainsComponent());

class ObjectEditorGameEventComponent extends Component {
  // TODO: use state
  int selected;
  List<Function> callbacks = [];

  componentDidMount(a) {
    callCallbacks();
  }

  componentDidUpdate(a, b, c) {
    callCallbacks();
  }

  void callCallbacks() {
    if(callbacks != null) {
      for(Function callback in callbacks) {
        callback();
      }
    }
  }

  render() {
    this.callbacks = [];
    List<JsObject> tables = [];

    for(int i=0; i<World.gameEventChains.keys.length; i++) {
      List<GameEvent> gameEventChain = World.gameEventChains.values.elementAt(i);

      List<JsObject> tableRows = [
        tr({}, [
          td({}, "Num"),
          td({}, "Event Type"),
          td({}, "Params"),
          td({})
        ])
      ];

      for(int j=0; j<gameEventChain.length; j++) {
        tableRows.add(
          ObjectEditorGameEvents.buildGameEventTableRowHtml(
            gameEventChain[j], "game_event_chain_${i}_game_event_${j}", j, callbacks: callbacks
          )
        );
      }

      tables.add(
        table({'id': 'game_event_chain_${i}_game_event_table', 'className': selected != i? 'hidden' : ''}, tableRows)
      );
    }

    this.callbacks = callbacks;

    return div({}, tables);
  }
}

var objectEditorGameEventComponent = registerComponent(() => new ObjectEditorGameEventComponent());




class ObjectEditorGameEvents {
  static List<String> advancedTabs = ["game_event_chain_game_events"];
  
  static int selected;
  
  static void setUp() {
    render(objectEditorGameEventChainsComponent({}), querySelector('#game_event_chains_container'));

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
    render(objectEditorGameEventChainsComponent({}), querySelector('#game_event_chains_container'));
    render(objectEditorGameEventComponent({}), querySelector('#game_event_chain_game_events_container'));
    
    // highlight the selected row
    if(querySelector("#game_event_chain_row_${selected}") != null) {
      querySelector("#game_event_chain_row_${selected}").classes.add("selected");
      querySelector("#object_editor_game_event_chains_advanced").classes.remove("hidden");
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
    querySelector("#object_editor_game_event_chains_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected game event chain
    querySelector("#game_event_chain_${i}_game_event_table").classes.remove("hidden");
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
  
  static JsObject buildGameEventTableRowHtml(GameEvent gameEvent, String prefix, int num, {bool readOnly: false, List<Function> callbacks}) {
    JsObject paramsHtml;
    
    List<JsObject> options = [];

    for(int k=0; k<GameEvent.gameEventTypes.length; k++) {
      options.add(
        option({}, GameEvent.gameEventTypes[k])
      );

      if(GameEvent.gameEventTypes[k] == gameEvent.getType()) {
        paramsHtml = gameEvent.buildHtml(prefix, readOnly, callbacks, onInputChange);
      }
    }
    
    JsObject buttonHtml = null;
    if(!readOnly) {
      buttonHtml = button({'id': 'delete_${prefix}'}, "Delete");
    }
    
    return tr({}, [
      td({}, num),
      td({},
        select({'id': '${prefix}_type', 'disabled': readOnly, 'value': gameEvent.getType()}, options)
      ),
      td({}, paramsHtml),
      td({}, buttonHtml)
    ]);
  }
}