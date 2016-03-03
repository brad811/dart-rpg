library dart_rpg.object_editor_game_events;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/chain_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

// TODO: map editing events (place/remove/change warps, signs, tiles, events)
// TODO: character editing events (change gameEventChain, battler/level, inventory, name, size, picture/sprite)
// TODO: logic gate events IF this THEN gameEventChainA ELSE gameEventChainB
// TODO: text input game event

class ObjectEditorGameEvents extends Component {
  List<Function> callbacks = [];
  bool shouldScrollIntoView = false;

  getInitialState() => {
    'selected': -1
  };

  componentDidMount(Element rootNode) {
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    callCallbacks();
    if(state['selected'] > World.gameEventChains.length - 1) {
      setState({
        'selected': World.gameEventChains.length - 1
      });
    }

    if(shouldScrollIntoView) {
      shouldScrollIntoView = false;
      querySelector('#game_event_chain_row_${state['selected']}').scrollIntoView();
    }
  }

  void callCallbacks() {
    if(callbacks != null) {
      for(Function callback in callbacks) {
        callback();
      }
    }
  }

  void removeDeleted() {
    // remove references to deleted game events

    // characters
    World.characters.forEach((String label, Character character) {
      if(!World.gameEventChains.containsKey(character.getGameEventChain())) {
        character.setGameEventChain(null, 0);
      }
    });

    // event tiles
    MapEditor.events.forEach((String mapName, List<EventTile> eventTiles) {
      for(EventTile eventTile in eventTiles.toList()) {
        if(!World.gameEventChains.containsKey(eventTile.gameEventChain)) {
          eventTiles.remove(eventTile);
        }
      }
    });

    // chain game events
    World.gameEventChains.forEach((String name, List<GameEvent> gameEvents) {
      for(GameEvent gameEvent in gameEvents.toList()) {
        if(gameEvent is ChainGameEvent) {
          if(!World.gameEventChains.containsKey(gameEvent.gameEventChain)) {
            gameEvent.gameEventChain = World.gameEventChains.keys.first;
          }
        }
      }
    });
    
    update();
  }

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
        tr({
          'id': 'game_event_chain_row_${i}',
          'className': state['selected'] == i ? 'selected' : '',
          'onClick': (MouseEvent e) { setState({'selected': i}); },
          'onFocus': (MouseEvent e) { setState({'selected': i}); }
        }, [
          td({}, i),
          td({},
            input({
              'id': 'game_event_chain_${i}_label',
              'type': 'text',
              'value': key,
              'onChange': onInputChange
            })
          ),
          td({}, World.gameEventChains[key].length),
          td({},
            button({
              'id': 'delete_game_event_chain_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(World.gameEventChains, key, "game event chain", removeDeleted)
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        ])
      );
    }

    return
      div({'id': 'object_editor_game_event_chains_container', 'className': 'object_editor_tab_container'},

        table({
          'id': 'object_editor_game_event_chains_advanced',
          'className': 'object_editor_advanced_tab'}, tbody({},
          tr({},
            td({'className': 'tab_headers'},
              div({
                'id': 'game_event_chain_game_events_tab_header',
                'className': 'tab_header selected'
              }, "Game Events")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'className': 'tab'},
                div({'className': state['selected'] == -1 ? 'hidden' : ''},
                  button({
                    'id': 'add_game_event_button',
                    'onClick': addGameEvent
                  }, span({'className': 'fa fa-plus-circle'}), " Add new game event"),
                  hr({}),
                  div({'id': 'game_event_chain_game_events_container'}, getGameEventsTab())
                )
              )
            )
          )
        )),

        div({'id': 'object_editor_game_event_chains_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'},
            button({
              'id': 'add_game_event_chain_button',
              'onClick': addNewGameEventChain
            }, span({'className': 'fa fa-plus-circle'}), " Add new game event chain"),
            hr({}),
            div({'id': 'battler_types_container'},
              table({'className': 'editor_table'}, tbody({}, tableRows))
            )
          )
        )

      );
  }

  getGameEventsTab() {
    callbacks = [];

    if(state['selected'] == -1 || World.gameEventChains.values.length == 0) {
      return div({});
    }

    List<GameEvent> gameEventChain = World.gameEventChains.values.elementAt(state['selected']);

    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "Event Type"),
        td({}, "Params"),
        td({})
      )
    ];

    for(int j=0; j<gameEventChain.length; j++) {
      tableRows.add(
        buildGameEventTableRowHtml(
          gameEventChain[j], "game_event_chain_${state['selected']}_game_event_${j}", j, callbacks
        )
      );
    }

    this.callbacks = callbacks;

    return
      table({
        'id': 'game_event_chain_${state['selected']}_game_event_table'}, tbody({},
        tableRows
      ));
  }

  void addNewGameEventChain(MouseEvent e) {
    String name = Editor.getUniqueName("New Game Event Chain", World.gameEventChains);
    World.gameEventChains[name] = [new TextGameEvent(1, "Text")];
    
    shouldScrollIntoView = true;
    this.setState({
      'selected': World.gameEventChains.keys.length - 1
    });
  }
  
  void addGameEvent(MouseEvent e) {
    List<GameEvent> selectedGameEventChain = World.gameEventChains.values.elementAt(state['selected']);
    
    selectedGameEventChain.add(
        new TextGameEvent(1, "Text")
    );
    
    update();
  }
  
  void update() {
    setState({});
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_label", World.gameEventChains);

    Map<String, List<GameEvent>> newGameEventChains = {};

    String oldLabel = World.gameEventChains.keys.elementAt(state['selected']);

    World.gameEventChains.forEach((String key, List<GameEvent> gameEvents) {
      if(key != oldLabel) {
        newGameEventChains[key] = World.gameEventChains[key];
      } else {
        try {
          List<GameEvent> gameEventChain = new List<GameEvent>();
          for(int j=0; querySelector('#game_event_chain_${state['selected']}_game_event_${j}_type') != null; j++) {
            gameEventChain.add(
                buildGameEvent("game_event_chain_${state['selected']}_game_event_${j}")
              );
          }
          
          String label = Editor.getTextInputStringValue('#game_event_chain_${state['selected']}_label');
          
          newGameEventChains[label] = gameEventChain;
        } catch(e) {
          // could not update this game event chain
          print("Error updating game event chain: " + e.toString());
        }
      }
    });

    World.gameEventChains = newGameEventChains;
    
    update();

    Editor.debounceExport();
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
  
  GameEvent buildGameEvent(String prefix) {
    String gameEventType = Editor.getSelectInputStringValue("#${prefix}_type");
    
    return GameEvent.buildGameEvent(gameEventType, prefix);
  }

  JsObject buildGameEventTableRowHtml(GameEvent gameEvent, String prefix, int number, List<Function> callbacks) {
    JsObject paramsHtml;
    
    List<JsObject> options = [];

    for(int k=0; k<GameEvent.gameEventTypes.length; k++) {
      options.add(
        option({}, GameEvent.gameEventTypes[k])
      );

      if(GameEvent.gameEventTypes[k] == gameEvent.getType()) {
        paramsHtml = gameEvent.buildHtml(prefix, false, callbacks, onInputChange, update);
      }
    }
    
    return tr({}, [
      td({}, number),
      td({},
        select({
          'id': '${prefix}_type',
          'value': gameEvent.getType(),
          'onChange': onInputChange
        }, options)
      ),
      td({}, paramsHtml),
      td({},
        button({
          'id': 'delete_${prefix}',
          'onClick': Editor.generateConfirmDeleteFunction(
            World.gameEventChains.values.elementAt(state['selected']), number, "game event", update
          )
        }, span({'className': 'fa fa-trash'}), " Delete")
      )
    ]);
  }
  
  static JsObject buildReadOnlyGameEventTableRowHtml(GameEvent gameEvent, String prefix, int number, List<Function> callbacks) {
    JsObject paramsHtml;
    
    List<JsObject> options = [];

    for(int k=0; k<GameEvent.gameEventTypes.length; k++) {
      options.add(
        option({}, GameEvent.gameEventTypes[k])
      );

      if(GameEvent.gameEventTypes[k] == gameEvent.getType()) {
        paramsHtml = gameEvent.buildHtml(prefix, true, callbacks, null, null);
      }
    }
    
    return tr({}, [
      td({}, number),
      td({},
        select({
          'id': '${prefix}_type',
          'disabled': true,
          'value': gameEvent.getType(),
        }, options)
      ),
      td({}, paramsHtml),
      td({})
    ]);
  }
}