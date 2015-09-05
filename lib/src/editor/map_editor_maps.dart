library dart_rpg.map_editor_maps;

import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor.dart';
import 'package:dart_rpg/src/editor/map_editor_characters.dart';
import 'package:dart_rpg/src/editor/map_editor_events.dart';
import 'package:dart_rpg/src/editor/map_editor_signs.dart';
import 'package:dart_rpg/src/editor/map_editor_warps.dart';

class MapEditorMaps {
  static void setUp() {
    Editor.attachButtonListener("#add_map_button", addNewMap);
  }
  
  static void addNewMap(MouseEvent e) {
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
    
    update();
  }
  
  static void update() {
    String mapsHtml = "";
    
    mapsHtml += "<hr />";
    
    mapsHtml += "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Name</td><td>X Size</td><td>Y Size</td><td></td>"+
      "  </tr>";
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      mapsHtml += "<tr>";
      if(Main.world.curMap != key)
        mapsHtml += "  <td><button id='map_select_${i}'>${i}</button></td>";
      else
        mapsHtml += "  <td>${i}</td>";
        
      mapsHtml +=
        "  <td><input id='map_${i}_name' type='text' value='${ Main.world.maps[key].name }' /></td>"+
        "  <td>${ Main.world.maps[key].tiles[0].length }</td>"+
        "  <td>${ Main.world.maps[key].tiles.length }</td>"+
        "  <td><button id='delete_map_${i}'>Delete</button></td>"+
        "</tr>";
    }
    mapsHtml += "</table>";
    querySelector("#maps_container").setInnerHtml(mapsHtml);
    
    setMapSelectorButtonListeners();
    setMapDeleteButtonListeners();
    
    for(int i=0; i<Main.world.maps.length; i++) {
      Editor.attachInputListeners("map_${i}", ["name"], onInputChange);
    }
    
    setUpLayerVisibilityToggles();
    setUpMapSizeButtons();
  }
  
  static void onInputChange(Event e) {
    Map<String, GameMap> newMaps = {};
    Map<String, List<WarpTile>> newWarps = {};
    Map<String, List<Sign>> newSigns = {};
    Map<String, List<BattlerChance>> newBattlers = {};
    Map<String, List<EventTile>> newEvents = {};
    bool changedByUser, nameChange = false;
    
    Editor.enforceValueFormat(e);
    // TODO: figure out how to update names of things in other places when avoiding collisions
    
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
    
    // TODO: tab scrolls when changing map name
    if(nameChange) {
      Editor.updateAndRetainValue(e);
    } else {
      MapEditor.updateMap(shouldExport: true);
    }
  }
  
  static void setMapSelectorButtonListeners() {
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      if(Main.world.curMap != key) {
        Editor.attachButtonListener("#map_select_${i}", (MouseEvent e) {
          Main.world.curMap = key;
          Editor.update();
        });
      }
    }
  }
  
  static void setMapDeleteButtonListeners() {
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
          Editor.update();
        }
      });
    }
  }
  
  static void setUpLayerVisibilityToggles() {
    Editor.attachInputListeners("layer_visible",
      ["above", "player", "below", "ground", "special"],
      (_) {
        MapEditor.layerVisible[World.LAYER_ABOVE] = Editor.getCheckboxInputBoolValue("#layer_visible_above");
        MapEditor.layerVisible[World.LAYER_PLAYER] = Editor.getCheckboxInputBoolValue("#layer_visible_player");
        MapEditor.layerVisible[World.LAYER_BELOW] = Editor.getCheckboxInputBoolValue("#layer_visible_below");
        MapEditor.layerVisible[World.LAYER_GROUND] = Editor.getCheckboxInputBoolValue("#layer_visible_ground");
        
        Editor.highlightSpecialTiles = Editor.getCheckboxInputBoolValue("#layer_visible_special");
        
        Editor.update();
      }
    );
  }
  
  static void setUpMapSizeButtons() {
    Editor.attachButtonListener("#size_x_down_button", (_) { sizeDownRight(); });
    Editor.attachButtonListener("#size_x_up_button", (_) { sizeUpRight(); });
    Editor.attachButtonListener("#size_y_down_button", (_) { sizeDownBottom(); });
    Editor.attachButtonListener("#size_y_up_button", (_) { sizeUpBottom(); });
    
    Editor.attachButtonListener("#size_x_down_button_pre", (_) { sizeDownLeft(); });
    Editor.attachButtonListener("#size_x_up_button_pre", (_) { sizeUpLeft(); });
    Editor.attachButtonListener("#size_y_down_button_pre", (_) { sizeDownTop(); });
    Editor.attachButtonListener("#size_y_up_button_pre", (_) { sizeUpTop(); });
  }
  
  static void shiftObjects(int xAmount, int yAmount) {
    if(xAmount == 0 && yAmount == 0) {
      return;
    }
    
    MapEditorWarps.shift(xAmount, yAmount);
    MapEditorSigns.shift(xAmount, yAmount);
    MapEditorEvents.shift(xAmount, yAmount);
    MapEditorCharacters.shift(xAmount, yAmount);
    
    // shift warp game event destinations
    World.gameEventChains.values.forEach((List<GameEvent> gameEventChain) {
      gameEventChain.forEach((GameEvent gameEvent) {
        if(gameEvent is WarpGameEvent) {
          gameEvent.x += xAmount;
          gameEvent.y += yAmount;
        }
      });
    });
  }
  
  static void sizeDownRight() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles[0].length == 1)
      return;
    
    for(int y=0; y<mapTiles.length; y++) {
      mapTiles[y].removeLast();
      
      for(int x=0; x<mapTiles[y].length; x++) {
        for(int k=0; k<mapTiles[y][x].length; k++) {
          if(mapTiles[y][x][k] is Tile) {
            mapTiles[y][x][k].sprite.posX = x * 1.0;
          }
        }
      }
    }
    
    MapEditorMaps.shiftObjects(0, 0);
    
    Editor.update();
  }
  
  static void sizeUpRight() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 0)
      mapTiles.add([]);
    
    for(int y=0; y<mapTiles.length; y++) {
      List<Tile> array = [];
      for(int k=0; k<World.layers.length; k++) {
        array.add(null);
      }
      mapTiles[y].add(array);
    }
    
    Editor.update();
  }
  
  static void sizeDownBottom() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 1)
      return;
    
    mapTiles.removeLast();
    
    MapEditorMaps.shiftObjects(0, 0);
    
    Editor.update();
  }
  
  static void sizeUpBottom() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<List<Tile>> rowArray = [];
    
    for(int x=0; x<mapTiles[0].length; x++) {
      List<Tile> array = [];
      for(int k=0; k<World.layers.length; k++) {
        array.add(null);
      }
      rowArray.add(array);
    }
    
    mapTiles.add(rowArray);
    
    Editor.update();
  }
  
  static void sizeDownLeft() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles[0].length == 1)
      return;
    
    for(int i=0; i<mapTiles.length; i++) {
      mapTiles[i] = mapTiles[i].sublist(1);
      
      for(int j=0; j<mapTiles[i].length; j++) {
        for(int k=0; k<mapTiles[i][j].length; k++) {
          if(mapTiles[i][j][k] is Tile) {
            mapTiles[i][j][k].sprite.posX = j * 1.0;
          }
        }
      }
    }
    
    MapEditorMaps.shiftObjects(-1, 0);
    
    Editor.update();
  }
  
  static void sizeUpLeft() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 0)
      mapTiles.add([]);
    
    for(int y=0; y<mapTiles.length; y++) {
      List<Tile> array = [];
      for(int k=0; k<World.layers.length; k++) {
        array.add(null);
      }
      var temp = mapTiles[y];
      temp.insert(0, array);
      mapTiles[y] = temp;
    }
    
    for(int y=0; y<mapTiles.length; y++) {
      for(int x=0; x<mapTiles[y].length; x++) {
        for(int k=0; k<mapTiles[y][x].length; k++) {
          if(mapTiles[y][x][k] is Tile) {
            mapTiles[y][x][k].sprite.posX = x * 1.0;
          }
        }
      }
    }
    
    MapEditorMaps.shiftObjects(1, 0);
    
    Editor.update();
  }
  
  static void sizeDownTop() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 1)
      return;
    
    mapTiles.removeAt(0);
    
    for(int y=0; y<mapTiles.length; y++) {
      for(int x=0; x<mapTiles[0].length; x++) {
        for(int k=0; k<mapTiles[0][0].length; k++) {
          if(mapTiles[y][x][k] is Tile) {
            mapTiles[y][x][k].sprite.posY = y * 1.0;
          }
        }
      }
    }
    
    MapEditorMaps.shiftObjects(0, -1);
    
    Editor.update();
  }
  
  static void sizeUpTop() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<List<Tile>> rowArray = [];
    
    for(int i=0; i<mapTiles[0].length; i++) {
      List<Tile> array = [];
      for(int j=0; j<World.layers.length; j++) {
        array.add(null);
      }
      rowArray.add(array);
    }
    
    mapTiles.insert(0, rowArray);
    
    for(int y=0; y<mapTiles.length; y++) {
      for(int x=0; x<mapTiles[0].length; x++) {
        for(int k=0; k<mapTiles[0][0].length; k++) {
          if(mapTiles[y][x][k] is Tile) {
            mapTiles[y][x][k].sprite.posY = y * 1.0;
          }
        }
      }
    }
    
    MapEditorMaps.shiftObjects(0, 1);
    
    Editor.update();
  }
}