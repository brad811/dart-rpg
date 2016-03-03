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

import 'package:react/react.dart';

class MapEditorMaps extends Component {
  void update() {
    setState({});
  }

  void removeDeleted() {
    // remove references to deleted maps
    if(Main.world.maps.length == 0) {
      addNewMap(null);
    }

    // move characters away from maps that don't exist anymore
    World.characters.forEach((String label, Character character) {
      if(!Main.world.maps.containsValue(character.startMap)) {
        character.startMap = Main.world.maps.keys.first;
        character.startX = 0;
        character.startY = 0;
      }

      if(!Main.world.maps.containsValue(character.map)) {
        character.map = Main.world.maps.keys.first;
        character.mapX = 0;
        character.mapY = 0;
      }
    });
    
    props['changeMap'](Main.world.maps.keys.first);
    props['update'](shouldExport: true);

    // TODO: this might not be necessary because of the above update
    update();
  }

  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "Name"),
        td({}, "X Size"),
        td({}, "Y Size"),
        td({})
      )
    ];

    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);

      JsObject mapButton;
      if(Main.world.curMap != key) {
        mapButton = 
          td({},
            button({
              'id': 'map_select_${i}',
              'onClick': (MouseEvent e) { props['changeMap'](key); }
            }, i)
          );
      } else {
        mapButton = td({}, i);
      }

      tableRows.add(
        tr({},
          mapButton,
          td({},
            input({
              'id': 'map_${i}_name',
              'type': 'text',
              'value': Main.world.maps[key].name,
              'onChange': onInputChange
            })
          ),
          td({}, Main.world.maps[key].tiles[0].length),
          td({}, Main.world.maps[key].tiles.length),
          td({},
            button({
              'id': 'delete_map_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(Main.world.maps, key, "map", removeDeleted)
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'maps_tab', 'className': 'tab'},
        button({'id': 'add_map_button', 'onClick': addNewMap}, span({'className': 'fa fa-plus-circle'}), " Add new map"),
        div({'id': 'maps_container'},
          hr({}),
          table({'className': 'editor_table'}, tbody({}, tableRows))
        )
      );
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
    
    MapEditor.warps["new map"] = [];
    MapEditor.signs["new map"] = [];
    MapEditor.events["new map"] = [];
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
        
        newWarps[newName] = MapEditor.warps[key];
        newSigns[newName] = MapEditor.signs[key];
        newBattlers[newName] = Main.world.maps[key].battlerChances;
        newEvents[newName] = MapEditor.events[key];
        
        if(newName != key && Main.world.curMap == key && changedByUser) {
          Main.world.curMap = newName;
        }
        
        if(newName != key) {
          // update all warp destinations that include this map name
          MapEditor.warps.forEach((String map, List<WarpTile> warpTiles) {
            warpTiles.forEach((WarpTile warpTile) {
              if(warpTile.destMap == key)
                warpTile.destMap = newName;
            });
          });
          
          // update warps list to have this new map name
          if(MapEditor.warps.containsKey(key)) {
            MapEditor.warps[newName] = MapEditor.warps[key];
            MapEditor.warps.remove(key);
          }
          
          // update signs list to have this new map name
          if(MapEditor.signs.containsKey(key)) {
             MapEditor.signs[newName] = MapEditor.signs[key];
             MapEditor.signs.remove(key);
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
          if(MapEditor.events.containsKey(key)) {
            MapEditor.events[newName] = MapEditor.events[key];
            MapEditor.events.remove(key);
          }
        }
      } catch(e) {
        // could not update this map
        print("Error updating map name: ${e}");
      }
    }
    
    Main.world.maps = newMaps;
    MapEditor.warps = newWarps;
    MapEditor.signs = newSigns;
    MapEditor.events = newEvents;
    Main.world.maps.forEach((String mapName, GameMap map) {
      map.battlerChances = newBattlers[mapName];
    });
    
    if(nameChange) {
      props['debounceUpdate']();
      update();
    } else {
      MapEditor.updateMap(shouldExport: true);
    }
  }
}