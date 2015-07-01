library dart_rpg.map_editor_characters;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'map_editor.dart';

// TODO: editor tabs need to update everything because of this class

class MapEditorCharacters {
  static Map<String, List<Map<String, Object>>> characters = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_map_character_button").onClick.listen(addNewCharacter);
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<Character> mapCharacters = Main.world.maps[key].characters;
      characters[key] = [];
      
      for(Character character in mapCharacters) {
        characters[key].add({
          "type": character.name,
          "mapX": character.mapX,
          "mapY": character.mapY,
          "layer": character.layer,
          "direction": character.direction,
          "solid": character.solid
        });
      }
    }
  }
  
  static void addNewCharacter(MouseEvent e) {
    characters[Main.world.curMap].add({
      "type": World.characters.keys.first,
      "mapX": 0,
      "mapY": 0,
      "layer": World.LAYER_BELOW,
      "direction": Character.DOWN,
      "solid": true
    });
    
    Editor.update();
  }
  
  static void update() {
    String charactersHtml;
    charactersHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Type</td><td>X</td><td>Y</td><td>Layer</td><td>Direction</td><td>Solid</td>"+
      "  </tr>";
    
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      charactersHtml +=
        "<tr>"+
        "  <td>${i}</td>";
      
      charactersHtml += "<td><select id='map_character_${i}_type'>";
      World.characters.keys.forEach((String characterType) {
        charactersHtml += "<option value='${characterType}'";
        if(characters[Main.world.curMap][i]["type"] == characterType) {
          charactersHtml += " selected";
        }
        
        charactersHtml += ">${characterType}</option>";
      });
      charactersHtml += "</select></td>";
        
      charactersHtml +=
        "  <td><input id='map_character_${i}_map_x' type='text' value='${ characters[Main.world.curMap][i]["mapX"] }' /></td>"+
        "  <td><input id='map_character_${i}_map_y' type='text' value='${ characters[Main.world.curMap][i]["mapY"] }' /></td>";
      
      charactersHtml += "<td><select id='map_character_${i}_layer'>";
      List<String> layers = ["Ground", "Below", "Player", "Above"];
      for(int layer=0; layer<layers.length; layer++) {
        charactersHtml += "<option value='${layer}'";
        if(characters[Main.world.curMap][i]["layer"] == layer) {
          charactersHtml += " selected";
        }
        
        charactersHtml += ">${layers[layer]}</option>";
      }
      charactersHtml += "</select></td>";
      
      charactersHtml += "<td><select id='map_character_${i}_direction'>";
      List<String> directions = ["Down", "Right", "Up", "Left"];
      for(int direction=0; direction<directions.length; direction++) {
        charactersHtml += "<option value='${direction}'";
        if(characters[Main.world.curMap][i]["direction"] == direction) {
          charactersHtml += " selected";
        }
        
        charactersHtml += ">${directions[direction]}</option>";
      }
      charactersHtml += "</select></td>";
      
      String checkedHtml = "";
      if(characters[Main.world.curMap][i]["solid"] == true) {
        checkedHtml = "checked='checked'";
      }
      charactersHtml += "<td><input type='checkbox' id='map_character_${i}_solid' ${checkedHtml} /></td>";
      
      charactersHtml += "</tr>";
    }
    charactersHtml += "</table>";
    querySelector("#map_characters_container").innerHtml = charactersHtml;
    
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      List<String> attrs = ["type", "map_x", "map_y", "layer", "direction", "solid"];
      Editor.attachListeners(listeners, "map_character_${i}", attrs, onInputChange);
    }
  }
  
  static void onInputChange(Event e) {
    // TODO: character does not move when changing character position
    for(int i=0; i<characters[Main.world.curMap].length; i++) {
      try {
        characters[Main.world.curMap][i]["type"] = Editor.getSelectInputStringValue("#map_character_${i}_type");
        characters[Main.world.curMap][i]["mapX"] = Editor.getTextInputIntValue("#map_character_${i}_map_x", 0);
        characters[Main.world.curMap][i]["mapY"] = Editor.getTextInputIntValue("#map_character_${i}_map_y", 0);
        characters[Main.world.curMap][i]["layer"] = Editor.getSelectInputIntValue("#map_character_${i}_layer", World.LAYER_BELOW);
        characters[Main.world.curMap][i]["direction"] = Editor.getSelectInputIntValue("#map_character_${i}_direction", Character.DOWN);
        characters[Main.world.curMap][i]["solid"] = (querySelector("#map_character_${i}_solid") as CheckboxInputElement).checked;
        
        Character character = Main.world.maps[Main.world.curMap].characters[i];
        
        character.name = characters[Main.world.curMap][i]["type"];
        character.mapX = characters[Main.world.curMap][i]["mapX"];
        character.mapY = characters[Main.world.curMap][i]["mapY"];
        character.layer = characters[Main.world.curMap][i]["layer"];
        character.direction = characters[Main.world.curMap][i]["direction"];
        character.solid = characters[Main.world.curMap][i]["solid"];
        
        character.x = character.mapX * character.motionAmount;
        character.y = character.mapY * character.motionAmount;
      } catch(e) {
        // could not update this character
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map jsonMap, String key) {
    jsonMap["characters"] = [];
    for(Map<String, String> character in characters[key]) {
      jsonMap["characters"].add(character);
    }
  }
}