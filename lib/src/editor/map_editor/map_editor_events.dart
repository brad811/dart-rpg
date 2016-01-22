library dart_rpg.map_editor_events;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MapEditorEvents extends Component {
  static Map<String, List<EventTile>> events = {};

  void trackColors(Map<String, Map<String, int>> colorTrackers) {
    events[Main.world.curMap].forEach((EventTile eventTile) {
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

  void shift(int xAmount, int yAmount) {
    for(EventTile event in events[Main.world.curMap]) {
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
        events[Main.world.curMap].remove(event);
      }
    }
  }

  void deleteEvent(int i) {
    bool confirm = window.confirm('Are you sure you would like to delete this event?');
    if(confirm) {
      events[Main.world.curMap].removeAt(i);
      props['update']();
    }
  }

  getInitialState() {
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      events[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer in World.layers) {
            if(mapTiles[y][x][layer] is EventTile) {
              EventTile mapEventTile = mapTiles[y][x][layer];
              EventTile eventTile = new EventTile(
                  mapEventTile.gameEventChain,
                  mapEventTile.runOnce,
                  new Sprite(
                    mapEventTile.sprite.id,
                    mapEventTile.sprite.posX,
                    mapEventTile.sprite.posY
                  )
                );
              events[key].add(eventTile);
            }
          }
        }
      }
    }

    return events;
  }

  void addNewEvent(MouseEvent e) {
    if(World.gameEventChains.keys.length > 0) {
      events[Main.world.curMap].add( new EventTile(World.gameEventChains.keys.first, false, new Sprite.int(0, 0, 0), false) );
      props['update']();
    }
  }

  void onInputChange(Event e) {
    // TODO: implement!
    print("MapEditorEventsComponent.onInputChange not yet implemented!");

    Editor.enforceValueFormat(e);
    
    for(int i=0; i<events[Main.world.curMap].length; i++) {
      try {
        events[Main.world.curMap][i] = new EventTile(
          Editor.getSelectInputStringValue("#map_event_${i}_game_event_chain"),
          Editor.getCheckboxInputBoolValue("#map_event_${i}_run_once"),
          new Sprite(
            0,
            Editor.getTextInputDoubleValue('#map_event_${i}_posx', 0.0),
            Editor.getTextInputDoubleValue('#map_event_${i}_posy', 0.0)
          )
        );
      } catch(e) {
        // could not update this event
      }
    }
    
    //Editor.updateAndRetainValue(e);
    MapEditor.updateMap(shouldExport: true);
  }

  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "X"),
        td({}, "Y"),
        td({}, "Game Event Chain"),
        td({}, "Run Once"),
        td({})
      )
    ];

    // TODO: this is broken until "events" is populated!
    for(int i=0; i<events[Main.world.curMap].length; i++) {
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
            input({
              'id': 'map_event_${i}_posx',
              'type': 'text',
              'className': 'number',
              'value': events[Main.world.curMap][i].sprite.posX.round()
            })
          ),
          td({},
            input({
              'id': 'map_event_${i}_posy',
              'type': 'text',
              'className': 'number',
              'value': events[Main.world.curMap][i].sprite.posY.round()
            })
          ),
          td({},
            select({'id': 'map_event_${i}_game_event_chain', 'value': events[Main.world.curMap][i].gameEventChain}, options)
          ),
          td({},
            input({'id': 'map_event_${i}_run_once', 'type': 'checkbox', 'checked': events[Main.world.curMap][i].runOnce})
          ),
          td({},
            button({'id': 'delete_event_${i}', 'onClick': (e) { deleteEvent(i); }}, "Delete")
          )
        )
      );
    }

    return
      div({'id': 'events_tab', 'className': 'tab'},
        div({'id': 'events_container'}, [
          button({'id': 'add_event_button', 'onClick': this.addNewEvent}, "Add new event"),
          hr({}),
          table({'className': 'editor_table'}, tbody({}, tableRows))
        ])
      );
  }

  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(EventTile event in events[key]) {
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
          "runOnce": event.runOnce
        };
      }
    }
  }
}