library dart_rpg.map_editor_maps;

import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'map_editor.dart';
import 'map_editor_signs.dart';
import 'map_editor_warps.dart';

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
    Main.world.maps["new map"].battlerChances = [];
    
    update();
  }
  
  static void update() {
    String mapsHtml;
    
    mapsHtml = "<hr />Start map: <select id='start_map'>";
    for(int i=0; i<Main.world.maps.keys.length; i++) {
      String mapName = Main.world.maps.keys.elementAt(i);
      mapsHtml += "<option";
      if(Main.world.startMap == mapName) {
        mapsHtml += " selected";
      }
      mapsHtml += ">${mapName}</option>";
    }
    mapsHtml += "</select>&nbsp;&nbsp;&nbsp;&nbsp;";
    mapsHtml += "X: <input id='start_player_x' type='text' class='number' value='${Main.world.startX}' />&nbsp;&nbsp;&nbsp;&nbsp;";
    mapsHtml += "Y: <input id='start_player_y' type='text' class='number' value='${Main.world.startY}' />";
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
    
    Editor.attachInputListeners("start", ["map", "player_x", "player_y"], onInputChange);
    
    setUpLayerVisibilityToggles();
    setUpMapSizeButtons();
  }
  
  static void changeStartMap(Event e) {
    Main.world.startMap = (querySelector('#start_map') as SelectElement).value;
    
    if(e.target is TextInputElement) {
      TextInputElement target = e.target as TextInputElement;
      if(target.id.contains("start_player_")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
    }
    
    Main.world.startX = int.parse((querySelector('#start_player_x') as TextInputElement).value);
    Main.world.startY = int.parse((querySelector('#start_player_y') as TextInputElement).value);
    MapEditor.updateMap(shouldExport: true);
  }
  
  static void onInputChange(Event e) {
    Map<String, GameMap> newMaps = {};
    Map<String, List<WarpTile>> newWarps = {};
    Map<String, List<Sign>> newSigns = {};
    Map<String, List<BattlerChance>> newBattlers = {};
    bool changedByUser;
    
    for(int i=0; i<Main.world.maps.length; i++) {
      changedByUser = false;
      String key = Main.world.maps.keys.elementAt(i);
      try {
        String newName = (querySelector('#map_${i}_name') as TextInputElement).value;
        
        if(key != newName)
          changedByUser = true;
        
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
                if(gameEvent.oldMap == key) {
                  gameEvent.oldMap = newName;
                }
                
                if(gameEvent.newMap == key) {
                  gameEvent.newMap = newName;
                }
              }
            });
          });
          
          // update the start map to have this new map name
          if(Main.world.startMap == key) {
            Main.world.startMap = newName;
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
    Main.world.maps.forEach((String mapName, GameMap map) {
      map.battlerChances = newBattlers[mapName];
    });
    
    setMapSelectorButtonListeners();
    setMapDeleteButtonListeners();
    
    MapEditor.updateMap(shouldExport: true);
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
        MapEditor.layerVisible[World.LAYER_ABOVE] =
            (querySelector('#layer_visible_above') as CheckboxInputElement).checked;
        
        MapEditor.layerVisible[World.LAYER_PLAYER] =
            (querySelector('#layer_visible_player') as CheckboxInputElement).checked;
        
        MapEditor.layerVisible[World.LAYER_BELOW] =
            (querySelector('#layer_visible_below') as CheckboxInputElement).checked;
        
        MapEditor.layerVisible[World.LAYER_GROUND] =
            (querySelector('#layer_visible_ground') as CheckboxInputElement).checked;
        
        Editor.highlightSpecialTiles = 
            (querySelector('#layer_visible_special') as CheckboxInputElement).checked;
        
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
    
    // this will delete any that are now off the map
    MapEditorWarps.shift(0, 0);
    MapEditorSigns.shift(0, 0);
    
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
    
    // this will delete any that are now off the map
    MapEditorWarps.shift(0, 0);
    MapEditorSigns.shift(0, 0);
    
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
    
    // this will shift and delete any that are now off the map
    MapEditorWarps.shift(-1, 0);
    MapEditorSigns.shift(-1, 0);
    
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
    
    // this will shift and delete any that are now off the map
    MapEditorWarps.shift(1, 0);
    MapEditorSigns.shift(1, 0);
    
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
    
    // this will shift and delete any that are now off the map
    MapEditorWarps.shift(0, -1);
    MapEditorSigns.shift(0, -1);
    
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
    
    // this will shift and delete any that are now off the map
    MapEditorWarps.shift(0, 1);
    MapEditorSigns.shift(0, 1);
    
    Editor.update();
  }
}