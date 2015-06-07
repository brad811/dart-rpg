library dart_rpg.map_editor_maps;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'map_editor.dart';
import 'map_editor_battlers.dart';
import 'map_editor_characters.dart';
import 'map_editor_signs.dart';
import 'map_editor_warps.dart';

class MapEditorMaps {
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_map_button").onClick.listen((MouseEvent e) {
      // check if a new map already exists so we don't overwrite it
      if(Main.world.maps["new map"] != null)
        return;
      
      List nulls = [];
      for(int i=0; i<World.layers.length; i++)
        nulls.add(null);
      
      Main.world.maps["new map"] = new GameMap(
        "new map",
        [ [ nulls ] ],
        []
      );
      
      MapEditorCharacters.characters["new map"] = [];
      MapEditorWarps.warps["new map"] = [];
      MapEditorSigns.signs["new map"] = [];
      Main.world.maps["new map"].battlerChances = [];
      
      update();
    });
  }
  
  static void update() {
    String mapsHtml;
    mapsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>Name</td><td>X Size</td><td>Y Size</td><td>Chars</td>"+
      "  </tr>";
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      mapsHtml += "<tr>";
      if(Main.world.curMap != key)
        mapsHtml += "  <td><button id='map_select_${i}'>${i}</button></td>";
      else
        mapsHtml += "  <td>${i}</td>";
        
      mapsHtml +=
        "  <td><input id='maps_name_${i}' type='text' value='${ Main.world.maps[key].name }' /></td>"+
        "  <td>${ Main.world.maps[key].tiles[0].length }</td>"+
        "  <td>${ Main.world.maps[key].tiles.length }</td>"+
        "  <td>${ Main.world.maps[key].characters.length }</td>"+
        "</tr>";
    }
    mapsHtml += "</table>";
    querySelector("#maps_container").innerHtml = mapsHtml;
    
    setMapSelectorButtonListeners();
    
    Function inputChangeFunction = (Event e) {
      Map<String, GameMap> newMaps = {};
      Map<String, List<Character>> newCharacters = {};
      Map<String, List<WarpTile>> newWarps = {};
      Map<String, List<Sign>> newSigns = {};
      Map<String, List<BattlerChance>> newBattlers = {};
      bool changedByUser;
      
      for(int i=0; i<Main.world.maps.length; i++) {
        changedByUser = false;
        String key = Main.world.maps.keys.elementAt(i);
        try {
          String newName = (querySelector('#maps_name_${i}') as TextInputElement).value;
          
          if(key != newName)
            changedByUser = true;
          
          if(newMaps.keys.contains(newName)) {
            int j=0;
            while(newMaps.keys.contains("${newName}_${j}")) {
              j++;
            }
            
            newName = "${newName}_${j}";
            (querySelector('#maps_name_${i}') as TextInputElement).value = newName;
          }
          
          newMaps[newName] = Main.world.maps[key];
          newMaps[newName].name = newName;
          
          newCharacters[newName] = MapEditorCharacters.characters[key];
          newWarps[newName] = MapEditorWarps.warps[key];
          newSigns[newName] = MapEditorSigns.signs[key];
          newBattlers[newName] = Main.world.maps[key].battlerChances;
          
          if(newName != key && Main.world.curMap == key && changedByUser)
            Main.world.curMap = newName;
          
          if(newName != key) {
            // TODO: update all warp destinations that include this one
          }
        } catch(e) {
          // could not update this map
          print("Error updating map name: ${e}");
        }
      }
      
      Main.world.maps = newMaps;
      MapEditorCharacters.characters = newCharacters;
      MapEditorWarps.warps = newWarps;
      MapEditorSigns.signs = newSigns;
      Main.world.maps.forEach((String mapName, GameMap map) {
        map.battlerChances = newBattlers[mapName];
      });
      
      setMapSelectorButtonListeners();
      
      MapEditor.updateMap(shouldExport: true);
    };
    
    for(int i=0; i<Main.world.maps.length; i++) {
      if(listeners["#maps_name_${i}"] != null)
        listeners["#maps_name_${i}"].cancel();
      
      listeners["#maps_name_${i}"] = querySelector('#maps_name_${i}').onInput.listen(inputChangeFunction);
    }
    
    setUpLayerVisibilityToggles();
    setUpMapSizeButtons();
  }
  
  static void setMapSelectorButtonListeners() {
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      if(Main.world.curMap != key) {
        if(listeners["#map_select_${i}"] != null)
          listeners["#map_select_${i}"].cancel();
        
        listeners["#map_select_${i}"] = querySelector("#map_select_${i}").onClick.listen((MouseEvent e) {
          Main.world.curMap = key;
          Editor.update();
        });
      }
    }
  }
  
  static void setUpLayerVisibilityToggles() {
    if(listeners["#layer_above_visible"] != null)
      listeners["#layer_above_visible"].cancel();
    
    if(listeners["#layer_player_visible"] != null)
      listeners["#layer_player_visible"].cancel();
    
    if(listeners["#layer_below_visible"] != null)
      listeners["#layer_below_visible"].cancel();
    
    if(listeners["#layer_ground_visible"] != null)
      listeners["#layer_ground_visible"].cancel();
    
    listeners["#layer_above_visible"] = querySelector('#layer_above_visible').onChange.listen((Event e) {
      CheckboxInputElement checkbox = querySelector('#layer_above_visible');
      MapEditor.layerVisible[World.LAYER_ABOVE] = checkbox.checked;
      Editor.update();
    });
    
    listeners["#layer_player_visible"] = querySelector('#layer_player_visible').onChange.listen((Event e) {
      CheckboxInputElement checkbox = querySelector('#layer_player_visible');
      MapEditor.layerVisible[World.LAYER_PLAYER] = checkbox.checked;
      Editor.update();
    });
    
    listeners["#layer_below_visible"] = querySelector('#layer_below_visible').onChange.listen((Event e) {
      CheckboxInputElement checkbox = querySelector('#layer_below_visible');
      MapEditor.layerVisible[World.LAYER_BELOW] = checkbox.checked;
      Editor.update();
    });
    
    listeners["#layer_ground_visible"] = querySelector('#layer_ground_visible').onChange.listen((Event e) {
      CheckboxInputElement checkbox = querySelector('#layer_ground_visible');
      MapEditor.layerVisible[World.LAYER_GROUND] = checkbox.checked;
      Editor.update();
    });
  }
  
  static void setUpMapSizeButtons() {
    // size x down button
    if(listeners["#size_x_down_button"] != null)
      listeners["#size_x_down_button"].cancel();
      
    listeners["#size_x_down_button"] = querySelector('#size_x_down_button').onClick.listen((MouseEvent e) {
      sizeDownRight();
    });
     
    // size x up button
    if(listeners["#size_x_up_button"] != null)
      listeners["#size_x_up_button"].cancel();
      
    listeners["#size_x_up_button"] = querySelector('#size_x_up_button').onClick.listen((MouseEvent e) {
      sizeUpRight();
    });
    
    // size y down button
    if(listeners["#size_y_down_button"] != null)
      listeners["#size_y_down_button"].cancel();
      
    listeners["#size_y_down_button"] = querySelector('#size_y_down_button').onClick.listen((MouseEvent e) {
      sizeDownBottom();
    });
    
    // size y up button
    if(listeners["#size_y_up_button"] != null)
      listeners["#size_y_up_button"].cancel();
      
    listeners["#size_y_up_button"] = querySelector('#size_y_up_button').onClick.listen((MouseEvent e) {
      sizeUpBottom();
    });
    
    // ////////////////////////////////////////
    // Pre buttons
    // ////////////////////////////////////////
    
    // size x down button pre
    if(listeners["#size_x_down_button_pre"] != null)
      listeners["#size_x_down_button_pre"].cancel();
      
    listeners["#size_x_down_button_pre"] = querySelector('#size_x_down_button_pre').onClick.listen((MouseEvent e) {
      sizeDownLeft();
    });
     
    // size x up button pre
    if(listeners["#size_x_up_button_pre"] != null)
      listeners["#size_x_up_button_pre"].cancel();
      
    listeners["#size_x_up_button_pre"] = querySelector('#size_x_up_button_pre').onClick.listen((MouseEvent e) {
      sizeUpLeft();
    });
    
    // size y down button pre
    if(listeners["#size_y_down_button_pre"] != null)
      listeners["#size_y_down_button_pre"].cancel();
      
    listeners["#size_y_down_button_pre"] = querySelector('#size_y_down_button_pre').onClick.listen((MouseEvent e) {
      sizeDownTop();
    });
     
    // size y up button pre
    if(listeners["#size_y_up_button_pre"] != null)
      listeners["#size_y_up_button_pre"].cancel();
      
    listeners["#size_y_up_button_pre"] = querySelector('#size_y_up_button_pre').onClick.listen((MouseEvent e) {
      sizeUpTop();
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