library dart_rpg.object_editor_characters;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'object_editor.dart';

class ObjectEditorCharacters {
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_character_button").onClick.listen(addNewCharacter);
  }
  
  // TODO: this might have to be a different type
  // Perhaps have CharacterType or MapCharacter in map editor
  // because this should not have map information like location and layer
  
  static void addNewCharacter(MouseEvent e) {
    World.characters["New Character"] = new Character(
      0, 0, 0, 0,
      layer: World.LAYER_BELOW
    );
    
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    String charactersHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>Sprite Id</td><td>Picture Id</td><td>Power</td>"+
      "  </tr>";
    for(int i=0; i<World.characters.keys.length; i++) {
      String key = World.characters.keys.elementAt(i);
      
      charactersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='characters_name_${i}' type='text' value='${ World.characters[key].spriteId }' /></td>"+
        "  <td><input class='number' id='characters_power_${i}' type='text' value='${ World.characters[key].pictureId }' /></td>"+
        "  <td><button id='delete_character_${i}'>Delete</button></td>"+
        "</tr>";
    }
    charactersHtml += "</table>";
    querySelector("#characters_container").innerHtml = charactersHtml;
    
    Editor.setDeleteButtonListeners(World.characters, "character", listeners);
    
    List<String> attrs = ["name", "category", "power"];
    for(int i=0; i<World.characters.keys.length; i++) {
      for(String attr in attrs) {
        if(listeners["#characters_${attr}_${i}"] != null)
          listeners["#characters_${attr}_${i}"].cancel();
        
        listeners["#characters_${attr}_${i}"] = 
            querySelector('#characters_${attr}_${i}').onInput.listen(onInputChange);
      }
    }
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains("characters_name_") && World.characters.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.characters.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      } else if(target.id.contains("characters_power_")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
    }
    
    World.characters = new Map<String, Character>();
    for(int i=0; querySelector('#characters_name_${i}') != null; i++) {
      try {
        String name = (querySelector('#characters_name_${i}') as InputElement).value;
        //TODO: World.characters[name] = new Character();
      } catch(e) {
        // could not update this character
        print("Error updating character: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    /* TODO: 
    World.characters.forEach((String key, Character character) {
      Map<String, String> characterJson = {};
      characterJson["category"] = character.category.toString();
      characterJson["power"] = character.power.toString();
      charactersJson[character.name] = characterJson;
    });
    */
    
    exportJson["characters"] = charactersJson;
  }
}