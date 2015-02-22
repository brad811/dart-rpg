library EditorWarps;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class EditorWarps {
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
      update();
      Editor.updateMap();
    });
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      warps[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer in World.layers) {
            if(mapTiles[y][x][layer] is WarpTile) {
              warps[key].add(mapTiles[y][x][layer]);
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
        "</tr>";
    }
    warpsHtml += "</table>";
    querySelector("#warps_container").innerHtml = warpsHtml;
    
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
      Editor.updateMap();
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