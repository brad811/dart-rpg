library dart_rpg.map_editor_events;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MapEditorEvents extends Component {
  void update() {
    setState({});
    MapEditor.updateMap();
    Editor.debounceExport();
  }

  void trackColors(Map<String, Map<String, int>> colorTrackers) {
    MapEditor.events[Main.world.curMap].forEach((EventTile eventTile) {
      int x = eventTile.sprite.posX.round();
      int y = eventTile.sprite.posY.round();
      String key = "${x},${y}";
      
      if(colorTrackers[key] == null) {
        colorTrackers[key] = MapEditor.newColorTracker(x, y);
      }
      
      Map<String, int> colorTracker = colorTrackers[key];
      
      if(colorTracker["event"] == 0) {
        colorTracker["colorCount"] += 1;
        colorTracker["event"] = 1;
      }
    });
  }

  Function goToEditGameEventsFunction(int i) {
    return (MouseEvent e) {
      props['goToEditObject']('game_event_chains', i);
    };
  }

  static void shift(int xAmount, int yAmount) {
    for(EventTile event in MapEditor.events[Main.world.curMap]) {
      if(event == null)
        continue;
      
      // shift
      if(event.sprite != null) {
        event.sprite.posX += xAmount;
        event.sprite.posY += yAmount;
      }
      
      if(event.topSprite != null) {
        event.topSprite.posX += xAmount;
        event.topSprite.posY += yAmount;
      }
      
      // delete if off map
      if(
          event.sprite.posX < 0 ||
          event.sprite.posX >= Main.world.maps[Main.world.curMap].tiles[0].length ||
          event.sprite.posY < 0 ||
          event.sprite.posY >= Main.world.maps[Main.world.curMap].tiles.length) {
        // delete it
        MapEditor.events[Main.world.curMap].remove(event);
      }
    }
  }

  void addNewEvent(MouseEvent e) {
    if(World.gameEventChains.keys.length > 0) {
      MapEditor.events[Main.world.curMap].add(
        new EventTile(World.gameEventChains.keys.first, false, false, false, new Sprite.int(0, 0, 0), false)
      );
      update();
    }
  }

  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    for(int i=0; i<MapEditor.events[Main.world.curMap].length; i++) {
      try {
        MapEditor.events[Main.world.curMap][i] = new EventTile(
          Editor.getSelectInputStringValue("#map_event_${i}_game_event_chain"),
          Editor.getCheckboxInputBoolValue("#map_event_${i}_run_once"),
          Editor.getCheckboxInputBoolValue("#map_event_${i}_run_on_enter"),
          Editor.getCheckboxInputBoolValue("#map_event_${i}_run_on_interact"),
          new Sprite(
            0,
            Editor.getTextInputDoubleValue('#map_event_${i}_posx', 0.0),
            Editor.getTextInputDoubleValue('#map_event_${i}_posy', 0.0)
          )
        );
      } catch(e) {
        // could not update this event
        print("Error while updating event: ${e}");
      }
    }
    
    //Editor.updateAndRetainValue(e);
    update();
  }

  @override
  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "X"),
        td({}, "Y"),
        td({}), // move event button
        td({}, "Game Event Chain"),
        td({}, "Run Once"),
        td({}, "Run On Enter"),
        td({}, "Run On Interact"),
        td({})
      )
    ];

    // TODO: this is broken until "events" is populated!
    for(int i=0; i<MapEditor.events[Main.world.curMap].length; i++) {
      EventTile curEventTile = MapEditor.events[Main.world.curMap][i];

      List<JsObject> options = [];

      World.gameEventChains.keys.forEach((String gameEventChain) {
        options.add(
          option({'value': gameEventChain}, gameEventChain)
        );
      });

      tableRows.add(
        tr({},
          td({}, i),
          td({},
            Editor.generateInput({
              'id': 'map_event_${i}_posx',
              'type': 'text',
              'className': 'number',
              'value': curEventTile.sprite.posX.round(),
              'onChange': onInputChange
            })
          ),
          td({},
            Editor.generateInput({
              'id': 'map_event_${i}_posy',
              'type': 'text',
              'className': 'number',
              'value': curEventTile.sprite.posY.round(),
              'onChange': onInputChange
            })
          ),
          td({},
            // move event button
            button({
              'id': 'move_event_${i}',
              'onClick': (MouseEvent e) { props['moveInteractable'](curEventTile, '#move_event_${i}'); }
            }, span({'className': 'fa fa-crosshairs'}))
          ),
          td({},
            select({
              'id': 'map_event_${i}_game_event_chain',
              'value': curEventTile.gameEventChain,
              'onChange': onInputChange
            }, options),
            button({
                'onClick': goToEditGameEventsFunction(
                  World.gameEventChains.keys.toList().indexOf(
                    curEventTile.gameEventChain
                  )
                )
              },
              span({'className': 'fa fa-pencil-square-o'}),
              " Edit Game Event"
            )
          ),
          td({},
            input({
              'id': 'map_event_${i}_run_once',
              'type': 'checkbox',
              'checked': curEventTile.runOnce,
              'onChange': onInputChange
            })
          ),
          td({},
            input({
              'id': 'map_event_${i}_run_on_enter',
              'type': 'checkbox',
              'checked': curEventTile.runOnEnter,
              'onChange': onInputChange
            })
          ),
          td({},
            input({
              'id': 'map_event_${i}_run_on_interact',
              'type': 'checkbox',
              'checked': curEventTile.runOnInteract,
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_event_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(MapEditor.events[Main.world.curMap], i, "event", update)
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'events_tab', 'className': 'tab'},
        div({'id': 'events_container'}, [
          button({'id': 'add_event_button', 'onClick': this.addNewEvent}, span({'className': 'fa fa-plus-circle'}), " Add event to map"),
          hr({}),
          table({'className': 'editor_table'}, tbody({}, tableRows))
        ])
      );
  }

  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(EventTile event in MapEditor.events[key]) {
      int
        x = event.sprite.posX.round(),
        y = event.sprite.posY.round();
      
      // do not export events that are outside of the bounds of the map
      if(jsonMap.length - 1 < y || jsonMap[0].length - 1 < x) {
        continue;
      }
      
      if(jsonMap[y][x][0] != null) {
        jsonMap[y][x][0]["event"] = {
          "gameEventChain": event.gameEventChain,
          "runOnce": event.runOnce,
          "runOnEnter": event.runOnEnter,
          "runOnInteract": event.runOnInteract
        };
      }
    }
  }
}