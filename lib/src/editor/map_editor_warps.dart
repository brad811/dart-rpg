library dart_rpg.map_editor_warps;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'map_editor.dart';

class MapEditorWarps {
  static Map<String, List<WarpTile>> warps = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_warp_button").onClick.listen((MouseEvent e) {
      warps[Main.world.curMap].add(
        new WarpTile(
          false,
          new Sprite.int(0, 0, 0),
          Main.world.curMap, 0, 0
        )
      );
      
      Editor.update();
    });
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      warps[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer in World.layers) {
            if(mapTiles[y][x][layer] is WarpTile) {
              // make a copy of the warp tile
              WarpTile mapWarpTile = mapTiles[y][x][layer];
              WarpTile warpTile = new WarpTile(
                  mapWarpTile.solid,
                  new Sprite(
                    mapWarpTile.sprite.id,
                    mapWarpTile.sprite.posX,
                    mapWarpTile.sprite.posY
                  ),
                  mapWarpTile.destMap,
                  mapWarpTile.destX,
                  mapWarpTile.destY
                );
              warps[key].add(warpTile);
            }
          }
        }
      }
    }
  }
  
  static void update() {
    String warpsHtml;
    warpsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>X</td><td>Y</td><td>Dest Map</td><td>Dest X</td><td>Dest Y</td>"+
      "  </tr>";
    for(int i=0; i<warps[Main.world.curMap].length; i++) {
      warpsHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='warps_posx_${i}' type='text' value='${ warps[Main.world.curMap][i].sprite.posX.round() }' /></td>"+
        "  <td><input id='warps_posy_${i}' type='text' value='${ warps[Main.world.curMap][i].sprite.posY.round() }' /></td>"+
        "  <td>"+
        "    <select id='warps_destMap_${i}'>";
        
      for(String key in Main.world.maps.keys) {
        if(warps[Main.world.curMap][i].destMap == key)
          warpsHtml += "<option selected=\"selected\" value=\"${key}\">${key}</option>";
        else
          warpsHtml += "<option value=\"${key}\">${key}</option>";
      }
        
      warpsHtml +=
        "    </select>"+
        "  </td>"+
        "  <td><input id='warps_destx_${i}' type='text' value='${ warps[Main.world.curMap][i].destX }' /></td>"+
        "  <td><input id='warps_desty_${i}' type='text' value='${ warps[Main.world.curMap][i].destY }' /></td>"+
        "  <td><button id='delete_warp_${i}'>Delete</button></td>" +
        "</tr>";
    }
    warpsHtml += "</table>";
    querySelector("#warps_container").innerHtml = warpsHtml;
    
    setWarpDeleteButtonListeners();
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<warps[Main.world.curMap].length; i++) {
        try {
          warps[Main.world.curMap][i].sprite.posX = double.parse((querySelector('#warps_posx_${i}') as InputElement).value);
          warps[Main.world.curMap][i].sprite.posY = double.parse((querySelector('#warps_posy_${i}') as InputElement).value);
          warps[Main.world.curMap][i].destMap = (querySelector('#warps_destMap_${i}') as SelectElement).value;
          warps[Main.world.curMap][i].destX = int.parse((querySelector('#warps_destx_${i}') as InputElement).value);
          warps[Main.world.curMap][i].destY = int.parse((querySelector('#warps_desty_${i}') as InputElement).value);
        } catch(e) {
          // could not update this warp
        }
      }
      
      MapEditor.updateMap(shouldExport: true);
    };
    
    for(int i=0; i<warps[Main.world.curMap].length; i++) {
      List<String> attrs = ["posx", "posy", "destMap", "destx", "desty"];
      for(String attr in attrs) {
        if(listeners["#warps_${attr}_${i}"] != null)
          listeners["#warps_${attr}_${i}"].cancel();
        
        listeners["#warps_${attr}_${i}"] = 
            querySelector('#warps_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void setWarpDeleteButtonListeners() {
    for(int i=0; i<warps[Main.world.curMap].length; i++) {
      if(listeners["#delete_warp_${i}"] != null)
        listeners["#delete_warp_${i}"].cancel();
      
      listeners["#delete_warp_${i}"] = querySelector("#delete_warp_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this warp?');
        if(confirm) {
          warps[Main.world.curMap].removeAt(i);
          Editor.update();
        }
      });
    }
  }
  
  static void shift(int xAmount, int yAmount) {
    for(WarpTile warpTile in warps[Main.world.curMap]) {
      if(warpTile == null)
        continue;
      
      // shift
      if(warpTile.sprite != null) {
        warpTile.sprite.posX += xAmount;
        warpTile.sprite.posY += yAmount;
      }
      
      if(warpTile.topSprite != null) {
        warpTile.topSprite.posX += xAmount;
        warpTile.topSprite.posY += yAmount;
      }
      
      // delete if off map
      if(
          warpTile.sprite.posX < 0 ||
          warpTile.sprite.posX >= Main.world.maps[Main.world.curMap].tiles[0].length ||
          warpTile.sprite.posY < 0 ||
          warpTile.sprite.posY >= Main.world.maps[Main.world.curMap].tiles.length) {
        // delete it
        warps[Main.world.curMap].remove(warpTile);
      }
    }
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(WarpTile warp in warps[key]) {
      int
        x = warp.sprite.posX.round(),
        y = warp.sprite.posY.round();
      
      // handle the map shrinking until a warp is out of bounds
      if(jsonMap.length - 1 < y || jsonMap[0].length - 1 < x) {
        continue;
      }
      
      if(jsonMap[y][x][0] != null) {
        jsonMap[y][x][0]["warp"] = {
          "posX": x,
          "posY": y,
          "destMap": warp.destMap,
          "destX": warp.destX,
          "destY": warp.destY
        };
      }
    }
  }
}