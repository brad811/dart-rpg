library dart_rpg.object_editor_characters;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
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
      "size_x", "size_y", /* inventory, game_event */
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
      
      if(target.id.contains("character_label_") && World.characters.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.characters.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      } else {
        List<String> numberFields = [
          "sprite_id", "picture_id", "level",
          "size_x", "size_y",
          "sight_distance"
        ];
        
        numberFields.forEach((String field) {
          if(target.id.contains("character_power_")) {
            // enforce number format
            target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
            return;
          }
        });
      }
    }
    
    World.characters = new Map<String, Character>();
    for(int i=0; querySelector('#character_label_${i}') != null; i++) {
      try {
        String name = (querySelector('#character_label_${i}') as InputElement).value;
        Character character = new Character(
          Editor.getTextInputIntValue('#character_sprite_id_${i}', 1),
          Editor.getTextInputIntValue('#character_picture_id_${i}', 1),
          0, 0,
          layer: World.LAYER_BELOW,
          sizeX: Editor.getTextInputIntValue('#character_size_x_${i}', 1),
          sizeY: Editor.getTextInputIntValue('#character_size_y_${i}', 2),
          solid: true
        );
        
        String battlerTypeName = (querySelector('#character_battler_type_${i}') as SelectElement).value;
        
        Battler battler = new Battler(
          "name",
          World.battlerTypes[battlerTypeName],
          int.parse((querySelector('#character_level_${i}') as TextInputElement).value),
          World.battlerTypes[battlerTypeName].levelAttacks.values.toList()
        );
        
        character.battler = battler;
        character.sightDistance = Editor.getTextInputIntValue('#character_sight_distance_${i}', 1);
        character.preBattleText = Editor.getTextInputStringValue('#character_pre_battle_text_${i}');
        // post battle event
        
        World.characters[name] = character;
      } catch(e) {
        // could not update this character
        print("Error updating character: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    World.characters.forEach((String key, Character character) {
      Map<String, String> characterJson = {};
      characterJson["spriteId"] = character.spriteId.toString();
      characterJson["pictureId"] = character.pictureId.toString();
      characterJson["battlerType"] = character.battler.battlerType.name;
      characterJson["battlerLevel"] = character.battler.level.toString();
      characterJson["sizeX"] = character.sizeX.toString();
      characterJson["sizeY"] = character.sizeY.toString();
      // inventory
      // game event
      characterJson["sightDistance"] = character.sightDistance.toString();
      characterJson["preBattleText"] = character.preBattleText;
      // post battle event
      
      charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
}