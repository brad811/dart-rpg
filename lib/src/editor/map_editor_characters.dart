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
    querySelector("#add_map_character_button").onClick.listen(addNewCharacter);
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<Character> mapCharacters = Main.world.maps[key].characters;
      characters[key] = [];
      
      for(Character character in mapCharacters) {
        characters[key].add(character);
      }
    }
  }
  
  static void addNewCharacter(MouseEvent e) {
    characters[Main.world.curMap].add(
      new Character(
        0, 0,
        0, 0
      )
    );
    
    Editor.update();
  }
  
  /*
   * derp.mapX
   * derp.mapY
   * derp.layer
   * derp.direction
   * derp.solid
   */
  
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
        "  <td><input id='map_character_spriteid_${i}' type='text' value='${ characters[Main.world.curMap][i].spriteId }' /></td>"+
        "  <td><input id='map_character_picid_${i}' type='text' value='${ characters[Main.world.curMap][i].pictureId }' /></td>"+
        "  <td><input id='map_character_mapx_${i}' type='text' value='${ characters[Main.world.curMap][i].mapX }' /></td>"+
        "  <td><input id='map_character_mapy_${i}' type='text' value='${ characters[Main.world.curMap][i].mapY }' /></td>"+
        "  <td><input id='map_character_sizex_${i}' type='text' value='${ characters[Main.world.curMap][i].sizeX }' /></td>"+
        "  <td><input id='map_character_sizey_${i}' type='text' value='${ characters[Main.world.curMap][i].sizeY }' /></td>"+
        "  <td><input id='map_character_solid_${i}' type='checkbox' checked='${ characters[Main.world.curMap][i].solid }' disabled /></td>"+
        "</tr>";
    }
    charactersHtml += "</table>";
    querySelector("#map_characters_container").innerHtml = charactersHtml;
    
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      List<String> attrs = ["spriteid", "picid", "mapx", "mapy", "sizex", "sizey", "solid"];
      for(String attr in attrs) {
        if(listeners["#map_character_${attr}_${i}"] != null)
          listeners["#map_character_${attr}_${i}"].cancel();
        
        listeners["#map_character_${attr}_${i}"] = 
            querySelector('#map_character_${attr}_${i}').onInput.listen(onInputChange);
      }
    }
  }
  
  static void onInputChange(Event e) {
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      try {
        characters[Main.world.curMap][i].spriteId = int.parse((querySelector('#map_character_spriteid_${i}') as InputElement).value);
        characters[Main.world.curMap][i].pictureId = int.parse((querySelector('#map_character_picid_${i}') as InputElement).value);
        characters[Main.world.curMap][i].mapX = int.parse((querySelector('#map_character_mapx_${i}') as InputElement).value);
        characters[Main.world.curMap][i].mapY = int.parse((querySelector('#map_character_mapy_${i}') as InputElement).value);
        characters[Main.world.curMap][i].sizeX = int.parse((querySelector('#map_character_sizex_${i}') as InputElement).value);
        characters[Main.world.curMap][i].sizeY = int.parse((querySelector('#map_character_sizey_${i}') as InputElement).value);
        characters[Main.world.curMap][i].solid = true;
      } catch(e) {
        // could not update this character
      }
    }
    
    MapEditor.updateMap(shouldExport: true);
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