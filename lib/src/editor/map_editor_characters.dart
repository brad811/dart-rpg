library dart_rpg.map_editor_characters;

import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';

class MapEditorCharacters {
  static void setUp() {
  }
  
  static void update() {
    List<String> attrs = ["map_x", "map_y", "layer", "direction", "solid"];
    
    String charactersHtml;
    charactersHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Label</td><td>X</td><td>Y</td><td>Layer</td><td>Direction</td><td>Solid</td><td></td>"+
      "  </tr>";
    
    int i = -1;
    
    World.characters.forEach((String key, Character character) {
      i += 1;
      
      if(character.map != Main.world.curMap)
        return;
      
      charactersHtml +=
        "<tr>"+
        "  <td>${i}</td>";
      
      charactersHtml += "<td>${key}</td>";
      
      charactersHtml +=
        "  <td><input id='map_character_${i}_map_x' class='number' type='text' value='${ character.mapX }' /></td>"+
        "  <td><input id='map_character_${i}_map_y' class='number' type='text' value='${ character.mapY }' /></td>";
      
      charactersHtml += "<td><select id='map_character_${i}_layer'>";
      List<String> layers = ["Ground", "Below", "Player", "Above"];
      for(int layer=0; layer<layers.length; layer++) {
        charactersHtml += "<option value='${layer}'";
        if(character.layer == layer) {
          charactersHtml += " selected";
        }
        
        charactersHtml += ">${layers[layer]}</option>";
      }
      charactersHtml += "</select></td>";
      
      charactersHtml += "<td><select id='map_character_${i}_direction'>";
      List<String> directions = ["Down", "Right", "Up", "Left"];
      for(int direction=0; direction<directions.length; direction++) {
        charactersHtml += "<option value='${direction}'";
        if(character.direction == direction) {
          charactersHtml += " selected";
        }
        
        charactersHtml += ">${directions[direction]}</option>";
      }
      charactersHtml += "</select></td>";
      
      String checkedHtml = "";
      if(character.solid == true) {
        checkedHtml = "checked='checked'";
      }
      charactersHtml += "<td><input type='checkbox' id='map_character_${i}_solid' ${checkedHtml} /></td>";
      
      charactersHtml += "</tr>";
    });
    
    charactersHtml += "</table>";
    querySelector("#map_characters_container").setInnerHtml(charactersHtml);
    
    for(int i=0; i<World.characters.keys.length; i++) {
      if(World.characters.values.elementAt(i).map != Main.world.curMap)
        continue;
      
      Editor.attachInputListeners("map_character_${i}", attrs, onInputChange);
    }
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    int i = -1;
    World.characters.forEach((String key, Character character) {
      i += 1;
      
      if(character.map != Main.world.curMap)
        return;
      
      try {
        character.mapX = Editor.getTextInputIntValue("#map_character_${i}_map_x", 0);
        character.mapY = Editor.getTextInputIntValue("#map_character_${i}_map_y", 0);
        character.layer = Editor.getSelectInputIntValue("#map_character_${i}_layer", World.LAYER_BELOW);
        character.direction = Editor.getSelectInputIntValue("#map_character_${i}_direction", Character.DOWN);
        character.solid = Editor.getCheckboxInputBoolValue("#map_character_${i}_solid");
        
        character.x = character.mapX * character.motionAmount;
        character.y = character.mapY * character.motionAmount;
      } catch(e) {
        // could not update this character
        print("Error updating map character: " + e.toString());
      }
    });
    
    Editor.updateAndRetainValue(e);
  }
  
  static void shift(int xAmount, int yAmount) {
    World.characters.forEach((String characterLabel, Character character) {
      if(character.map != Main.world.curMap)
        return;
      
      character.mapX += xAmount;
      character.mapY += yAmount;
      
      character.x = character.mapX * character.motionAmount;
      character.y = character.mapY * character.motionAmount;
    });
  }
  
  // exporting is done in object editor character class
}