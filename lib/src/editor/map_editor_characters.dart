library dart_rpg.map_editor_characters;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';

import 'editor.dart';
import 'map_editor.dart';

class MapEditorCharacters {
  static Map<String, List<Character>> characters = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_character_button").onClick.listen((MouseEvent e) {
      characters[Main.world.curMap].add(
        new Character(
          0, 0,
          0, 0
        )
      );
      
      Editor.update();
    });
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<Character> mapCharacters = Main.world.maps[key].characters;
      characters[key] = [];
      
      for(Character character in mapCharacters) {
        characters[key].add(character);
      }
    }
  }
  
  static void update() {
    String charactersHtml;
    charactersHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>SpriteId</td><td>PicId</td><td>MapX</td><td>MapY</td><td>SizeX</td><td>SizeY</td><td>Solid</td>"+
      "  </tr>";
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      charactersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='characters_spriteid_${i}' type='text' value='${ characters[Main.world.curMap][i].spriteId }' /></td>"+
        "  <td><input id='characters_picid_${i}' type='text' value='${ characters[Main.world.curMap][i].pictureId }' /></td>"+
        "  <td><input id='characters_mapx_${i}' type='text' value='${ characters[Main.world.curMap][i].mapX }' /></td>"+
        "  <td><input id='characters_mapy_${i}' type='text' value='${ characters[Main.world.curMap][i].mapY }' /></td>"+
        "  <td><input id='characters_sizex_${i}' type='text' value='${ characters[Main.world.curMap][i].sizeX }' /></td>"+
        "  <td><input id='characters_sizey_${i}' type='text' value='${ characters[Main.world.curMap][i].sizeY }' /></td>"+
        "  <td><input id='characters_solid_${i}' type='checkbox' checked='${ characters[Main.world.curMap][i].solid }' disabled /></td>"+
        "</tr>";
    }
    charactersHtml += "</table>";
    querySelector("#characters_container").innerHtml = charactersHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<characters[Main.world.curMap].length; i++) {
        try {
          characters[Main.world.curMap][i].spriteId = int.parse((querySelector('#characters_spriteid_${i}') as InputElement).value);
          characters[Main.world.curMap][i].pictureId = int.parse((querySelector('#characters_picid_${i}') as InputElement).value);
          characters[Main.world.curMap][i].mapX = int.parse((querySelector('#characters_mapx_${i}') as InputElement).value);
          characters[Main.world.curMap][i].mapY = int.parse((querySelector('#characters_mapy_${i}') as InputElement).value);
          characters[Main.world.curMap][i].sizeX = int.parse((querySelector('#characters_sizex_${i}') as InputElement).value);
          characters[Main.world.curMap][i].sizeY = int.parse((querySelector('#characters_sizey_${i}') as InputElement).value);
          characters[Main.world.curMap][i].solid = true;
        } catch(e) {
          // could not update this character
        }
      }
      
      MapEditor.updateMap(shouldExport: true);
    };
    
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      List<String> attrs = ["spriteid", "picid", "mapx", "mapy", "sizex", "sizey", "solid"];
      for(String attr in attrs) {
        if(listeners["#characters_${attr}_${i}"] != null)
          listeners["#characters_${attr}_${i}"].cancel();
        
        listeners["#characters_${attr}_${i}"] = 
            querySelector('#characters_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void export(Map jsonMap, String key) {
    jsonMap["characters"] = [];
    for(Character character in characters[key]) {
      jsonMap["characters"].add({
        "sprite": character.spriteId,
        "pic": character.pictureId,
        "mapx": character.mapX,
        "mapy": character.mapY,
        "sizex": character.sizeX,
        "sizey": character.sizeY,
        "solid": character.solid
      });
    }
  }
}