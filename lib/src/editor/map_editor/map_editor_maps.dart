library dart_rpg.map_editor_maps;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_events.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_signs.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_warps.dart';

import 'package:react/react.dart';

class MapEditorMaps extends Component {
  componentDidMount(Element rootNode) {
    Editor.attachButtonListener("#add_map_button", addNewMap);

    setMapSelectorButtonListeners();
    setMapDeleteButtonListeners();
    
    for(int i=0; i<Main.world.maps.length; i++) {
      Editor.attachInputListeners("map_${i}", ["name"], onInputChange);
    }
  }

  render() {
    List<JsObject> tableRows = [
      tr({}, [
        td({}, "Num"),
        td({}, "Name"),
        td({}, "X Size"),
        td({}, "Y Size"),
        td({})
      ])
    ];

    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);

      JsObject mapButton;
      if(Main.world.curMap != key) {
        mapButton = 
          td({},
            button({'id': 'map_select_${i}'}, i)
          );
      } else {
        mapButton = td({}, i);
      }

      tableRows.add(
        tr({}, [
          mapButton,
          td({},
            input({'id': 'map_${i}_name', 'type': 'text', 'value': Main.world.maps[key].name})
          ),
          td({}, Main.world.maps[key].tiles[0].length),
          td({}, Main.world.maps[key].tiles.length),
          td({},
            button({'id': 'delete_map_${i}'}, "Delete")
          )
        ])
      );
    }

    return
      div({'id': 'maps_tab', 'className': 'tab'}, [
        button({'id': 'add_map_button'}, "Add new map"),
        div({'id': 'maps_container'}, [
          hr({}),
          table({'className': 'editor_table'}, tbody({}, tableRows))
        ])
      ]);
  }
  
  void addNewMap(MouseEvent e) {
    // check if a new map already exists so we don't overwrite it
    if(Main.world.maps["new map"] != null)
      return;
    
    List nulls = [];
    for(int i=0; i<World.layers.length; i++)
      nulls.add(null);
    
    Main.world.maps["new map"] = new GameMap(
      "new map",
      [ [ nulls ] ]
    );
    
    MapEditorWarps.warps["new map"] = [];
    MapEditorSigns.signs["new map"] = [];
    MapEditorEvents.events["new map"] = [];
    Main.world.maps["new map"].battlerChances = [];
    
    props['update']();
  }
  
  void onInputChange(Event e) {
    Map<String, GameMap> newMaps = {};
    Map<String, List<WarpTile>> newWarps = {};
    Map<String, List<Sign>> newSigns = {};
    Map<String, List<BattlerChance>> newBattlers = {};
    Map<String, List<EventTile>> newEvents = {};
    bool changedByUser, nameChange = false;
    
    Editor.enforceValueFormat(e);
    
    for(int i=0; i<Main.world.maps.length; i++) {
      changedByUser = false;
      String key = Main.world.maps.keys.elementAt(i);
      try {
        String newName = Editor.getTextInputStringValue("#map_${i}_name");
        
        if(key != newName) {
          changedByUser = true;
          nameChange = true;
        }
        
        if(newMaps.keys.contains(newName)) {
          int j=0;
          while(newMaps.keys.contains("${newName}_${j}")) {
            j++;
          }
          
          newName = "${newName}_${j}";
          (querySelector('#map_${i}_name') as TextInputElement).value = newName;
        }
        
        newMaps[newName] = Main.world.maps[key];
        newMaps[newName].name = newName;
        
        newWarps[newName] = MapEditorWarps.warps[key];
        newSigns[newName] = MapEditorSigns.signs[key];
        newBattlers[newName] = Main.world.maps[key].battlerChances;
        newEvents[newName] = MapEditorEvents.events[key];
        
        if(newName != key && Main.world.curMap == key && changedByUser) {
          Main.world.curMap = newName;
        }
        
        if(newName != key) {
          // update all warp destinations that include this map name
          MapEditorWarps.warps.forEach((String map, List<WarpTile> warpTiles) {
            warpTiles.forEach((WarpTile warpTile) {
              if(warpTile.destMap == key)
                warpTile.destMap = newName;
            });
          });
          
          // update warps list to have this new map name
          if(MapEditorWarps.warps.containsKey(key)) {
            MapEditorWarps.warps[newName] = MapEditorWarps.warps[key];
            MapEditorWarps.warps.remove(key);
          }
          
          // update signs list to have this new map name
          if(MapEditorSigns.signs.containsKey(key)) {
             MapEditorSigns.signs[newName] = MapEditorSigns.signs[key];
             MapEditorSigns.signs.remove(key);
          }
          
          // update characters to have this new map name
          World.characters.values.forEach((Character character) {
            if(character.map == key) {
              character.map = newName;
            }
          });
          
          // update warp game events to have this new map name
          World.gameEventChains.values.forEach((List<GameEvent> gameEvents) {
            gameEvents.forEach((GameEvent gameEvent) {
              if(gameEvent is WarpGameEvent) {
                if(gameEvent.newMap == key) {
                  gameEvent.newMap = newName;
                }
              }
            });
          });
          
          // update events list to have this new map name
          if(MapEditorEvents.events.containsKey(key)) {
            MapEditorEvents.events[newName] = MapEditorEvents.events[key];
            MapEditorEvents.events.remove(key);
          }
        }
      } catch(e) {
        // could not update this map
        print("Error updating map name: ${e}");
      }
    }
    
    Main.world.maps = newMaps;
    MapEditorWarps.warps = newWarps;
    MapEditorSigns.signs = newSigns;
    MapEditorEvents.events = newEvents;
    Main.world.maps.forEach((String mapName, GameMap map) {
      map.battlerChances = newBattlers[mapName];
    });
    
    setMapSelectorButtonListeners();
    setMapDeleteButtonListeners();
    
    if(nameChange) {
      Editor.updateAndRetainValue(e, props['update']);
    } else {
      MapEditor.updateMap(shouldExport: true);
    }
  }
  
  void setMapSelectorButtonListeners() {
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      if(Main.world.curMap != key) {
        Editor.attachButtonListener("#map_select_${i}", (MouseEvent e) {
          Main.world.curMap = key;
          props['update']();
        });
      }
    }
  }
  
  void setMapDeleteButtonListeners() {
    for(int i=0; i<Main.world.maps.length; i++) {
      Editor.attachButtonListener("#delete_map_${i}", (MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this map?');
        if(confirm) {
          String mapName = Main.world.maps.keys.elementAt(i);
          Main.world.maps.remove(mapName);
          if(Main.world.maps.length == 0) {
            addNewMap(null);
          }
          
          Main.world.curMap = Main.world.maps.keys.first;
          props['update']();
        }
      });
    }
  }
}