library dart_rpg.editor_signs;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class EditorSigns {
  static Map<String, List<Sign>> signs = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_sign_button").onClick.listen((MouseEvent e) {
      signs[Main.world.curMap].add( new Sign(false, new Sprite.int(0, 0, 0), 234, "Text") );
      update();
      Editor.updateMap();
    });
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      signs[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer in World.layers) {
            if(mapTiles[y][x][layer] is Sign) {
              signs[key].add(mapTiles[y][x][layer]);
            }
          }
        }
      }
    }
  }
  
  static void update() {
    String signsHtml;
    signsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>X</td><td>Y</td><td>Pic</td><td>Text</td>"+
      "  </tr>";
    for(int i=0; i<signs[Main.world.curMap].length; i++) {
      signsHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='signs_posx_${i}' type='text' value='${ signs[Main.world.curMap][i].sprite.posX.round() }' /></td>"+
        "  <td><input id='signs_posy_${i}' type='text' value='${ signs[Main.world.curMap][i].sprite.posY.round() }' /></td>"+
        "  <td><input id='signs_pic_${i}' type='text' value='${ signs[Main.world.curMap][i].textEvent.pictureSpriteId }' /></td>"+
        "  <td><textarea id='signs_text_${i}' />${ signs[Main.world.curMap][i].textEvent.text }</textarea></td>"+
        // TODO: make the delete button work, with a confirm dialog
        "  <td><button>Delete</button></td>" +
        "</tr>";
    }
    signsHtml += "</table>";
    querySelector("#signs_container").innerHtml = signsHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<signs[Main.world.curMap].length; i++) {
        try {
          signs[Main.world.curMap][i] = new Sign(
            false,
            new Sprite(
              0,
              double.parse((querySelector('#signs_posx_${i}') as InputElement).value),
              double.parse((querySelector('#signs_posy_${i}') as InputElement).value)
            ),
            int.parse((querySelector('#signs_pic_${i}') as InputElement).value),
            (querySelector('#signs_text_${i}') as TextAreaElement).value
          );
        } catch(e) {
          // could not update this sign
        }
      }
      Editor.updateMap();
    };
    
    for(int i=0; i<signs[Main.world.curMap].length; i++) {
      List<String> attrs = ["posx", "posy", "pic", "text"];
      for(String attr in attrs) {
        if(listeners["#signs_${attr}_${i}"] != null)
          listeners["#signs_${attr}_${i}"].cancel();
        
        listeners["#signs_${attr}_${i}"] = 
            querySelector('#signs_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    List<Sign> signsToRemove = [];
    for(Sign sign in signs[key]) {
      int
        x = sign.sprite.posX.round(),
        y = sign.sprite.posY.round();
      
      // handle the map shrinking until a warp is out of bounds
      if(jsonMap.length - 1 < y || jsonMap[0].length - 1 < x) {
        signsToRemove.add(sign);
        continue;
      }
      
      if(jsonMap[y][x][0] != null) {
        jsonMap[y][x][0]["sign"] = {
          "posX": x,
          "posY": y,
          "pic": sign.textEvent.pictureSpriteId,
          "text": sign.textEvent.text
        };
      }
    }
    
    for(Sign sign in signsToRemove) {
      signs[key].remove(sign);
    }
  }
}