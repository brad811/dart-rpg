library dart_rpg.object_editor_characters;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
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
    Character newCharacter = new Character(
      0, 0, 0, 0,
      layer: World.LAYER_BELOW,
      sizeX: 1, sizeY: 2,
      solid: true
    );
    
    BattlerType battlerType = World.battlerTypes.values.first;
    
    newCharacter.battler = new Battler(battlerType.name, battlerType, 2, battlerType.levelAttacks.values.toList());
    
    World.characters["New Character"] = newCharacter;
    
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    String charactersHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Label</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Picture Id</td>"+
      "    <td>Battler</td>"+
      "    <td>Level</td>"+
      "    <td>Size X</td>"+
      "    <td>Size Y</td>"+
      "    <td>Walk Speed</td>"+
      "    <td>Run Speed</td>"+
      "    <td>Inventory</td>"+
      "    <td>Game Event</td>"+
      "    <td>Sight Distance</td>"+
      "    <td>Pre Battle Text</td>"+
      "    <td>Post Battle Event</td>"+
      "    <td></td>"+
      "  </tr>";
    for(int i=0; i<World.characters.keys.length; i++) {
      String key = World.characters.keys.elementAt(i);
      
      charactersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='character_label_${i}' type='text' value='${ key }' /></td>"+
        "  <td><input id='character_sprite_id_${i}' type='text' class='number' value='${ World.characters[key].spriteId }' /></td>"+
        "  <td><input id='character_picture_id_${i}' type='text' class='number' value='${ World.characters[key].pictureId }' /></td>";
        
        charactersHtml += "<td><select id='character_battler_type_${i}'>";
        World.battlerTypes.forEach((String name, BattlerType battlerType) {
          charactersHtml += "<option value='${battlerType.name}'";
          if(World.characters[key].battler.battlerType.name == name) {
            charactersHtml += " selected";
          }
          
          charactersHtml += ">${battlerType.name}</option>";
        });
        charactersHtml += "</select></td>";
        
        charactersHtml +=
        "  <td><input id='character_level_${i}' type='text' class='number' value='${ World.characters[key].battler.level }' /></td>"+
        "  <td><input id='character_size_x_${i}' type='text' class='number' value='${ World.characters[key].sizeX }' /></td>"+
        "  <td><input id='character_size_y_${i}' type='text' class='number' value='${ World.characters[key].sizeY }' /></td>"+
        "  <td><input id='character_walk_speed_${i}' type='text' class='number' value='${ World.characters[key].walkSpeed }' /></td>"+
        "  <td><input id='character_run_speed_${i}' type='text' class='number' value='${ World.characters[key].runSpeed }' /></td>"+
        "  <td>Inventory</td>"+
        "  <td>Game Event</td>"+
        "  <td><input id='character_sight_distance_${i}' type='text' class='number' value='${ World.characters[key].sightDistance }' /></td>"+
        "  <td><input id='character_pre_battle_text_${i}' type='text' value='${ World.characters[key].preBattleText }' /></td>"+
        "  <td>Post Battle Event</td>"+
        "  <td><button id='delete_character_${i}'>Delete</button></td>"+
        "</tr>";
    }
    charactersHtml += "</table>";
    querySelector("#characters_container").innerHtml = charactersHtml;
    
    Editor.setDeleteButtonListeners(World.characters, "character", listeners);
    
    List<String> attrs = [
      "label", "sprite_id", "picture_id", "battler_type", "level",
      "size_x", "size_y", "walk_speed", "run_speed", /* inventory, game_event */
      "sight_distance", "pre_battle_text" /* post battle event */
    ];
    
    for(int i=0; i<World.characters.keys.length; i++) {
      for(String attr in attrs) {
        if(listeners["#character_${attr}_${i}"] != null)
          listeners["#character_${attr}_${i}"].cancel();
        
        listeners["#character_${attr}_${i}"] = 
            querySelector('#character_${attr}_${i}').onInput.listen(onInputChange);
      }
    }
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains("character_name_") && World.characters.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.characters.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      } else if(target.id.contains("character_power_")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
    }
    
    World.characters = new Map<String, Character>();
    for(int i=0; querySelector('#character_name_${i}') != null; i++) {
      try {
        String name = (querySelector('#character_name_${i}') as InputElement).value;
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