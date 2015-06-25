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
  static List<String> advancedTabs = ["character_inventory", "character_game_event", "character_battle"];
  static Map<String, StreamSubscription> listeners = {};
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    querySelector("#add_character_button").onClick.listen(addNewCharacter);
    querySelector("#add_inventory_item_button").onClick.listen(addInventoryItem);
  }
  
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
  
  static void addInventoryItem(MouseEvent e) {
    Character selectedCharacter = World.characters.values.elementAt(selected);
    for(int i=0; i<World.items.keys.length; i++) {
      if(!selectedCharacter.inventory.itemNames().contains(World.items.keys.elementAt(i))) {
        // add the first possible item that is not already in the character's inventory
        selectedCharacter.inventory.addItem(World.items.values.elementAt(i));
        break;
      }
    }
    
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildMainHtml();
    buildInventoryHtml();
    
    // TODO: add inventory, game event, and post battle event to right half
    // TODO: move level, sight distance, and pre-battle text under battle tab
    
    // highlight the selected row
    if(querySelector("#character_row_${selected}") != null) {
      querySelector("#character_row_${selected}").classes.add("selected");
      querySelector("#characters_advanced").style.display = "";
    }
    
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
      
      // when a row is clicked, set it as selected and highlight it
      querySelector("#character_row_${i}").onClick.listen((Event e) {
        selected = i;
        
        for(int j=0; j<World.characters.keys.length; j++) {
          querySelector("#character_row_${j}").classes.remove("selected");
        }
        
        querySelector("#character_row_${i}").classes.add("selected");
        querySelector("#characters_advanced").style.display = "";
      });
      
      // set listeners for inventory
    }
  }
  
  static void buildMainHtml() {
    String charactersHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Label</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Picture Id</td>"+
      "    <td>Battler</td>"+
      "    <td>Level</td>"+
      "    <td>Size X</td>"+
      "    <td>Size Y</td>"+
      "    <td>Sight Distance</td>"+
      "    <td>Pre Battle Text</td>"+
      "    <td></td>"+
      "  </tr>";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String key = World.characters.keys.elementAt(i);
      
      charactersHtml +=
        "<tr id='character_row_${i}'>"+
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
      "  <td><input id='character_sight_distance_${i}' type='text' class='number' value='${ World.characters[key].sightDistance }' /></td>"+
      "  <td><input id='character_pre_battle_text_${i}' type='text' value='${ World.characters[key].preBattleText }' /></td>"+
      "  <td><button id='delete_character_${i}'>Delete</button></td>"+
      "</tr>";
    }
    
    charactersHtml += "</table>";
    
    querySelector("#characters_container").innerHtml = charactersHtml;
  }
  
  static void buildInventoryHtml() {
    if(selected == null)
      return;
    
    String inventoryHtml = "";
    
    inventoryHtml += "<table>";
    inventoryHtml += "<tr><td>Num</td><td>Item</td><td>Quantity</td><td></td></tr>";
    Character selectedCharacter = World.characters.values.elementAt(selected);
    for(int i=0; i<selectedCharacter.inventory.itemNames().length; i++) {
      String curItemName = selectedCharacter.inventory.itemNames().elementAt(i);
      inventoryHtml += "<tr>";
      inventoryHtml += "  <td>${i}</td>";
      inventoryHtml += "  <td><select>";
      World.items.keys.forEach((String itemOptionName) {
        String selectedString = "";
        
        if(itemOptionName != curItemName && selectedCharacter.inventory.itemNames().contains(itemOptionName)) {
          // don't show items that are already somewhere else in the character's inventory
          return;
        }
        
        if(itemOptionName == curItemName) {
          selectedString = "selected=\"selected\"";
        }
        inventoryHtml += "<option ${selectedString}>${itemOptionName}</option>";
      });
      inventoryHtml += "  </select></td>";
      inventoryHtml += "  <td><input type='text' class='number' value='${selectedCharacter.inventory.getQuantity(curItemName)}' /></td>";
      inventoryHtml += "  <td><button id='delete_inventory_item_${i}'>Delete</button></td>";
      inventoryHtml += "</tr>";
    }
    
    inventoryHtml += "</table>";
    
    
    querySelector("#inventory_container").innerHtml = inventoryHtml;
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
      List<Map<String, String>> inventoryJson = [];
      character.inventory.itemNames().forEach((String itemName) {
        Map<String, String> itemJson = {};
        itemJson["item"] = itemName;
        itemJson["quantity"] = character.inventory.getQuantity(itemName).toString();
        
        inventoryJson.add(itemJson);
      });
      
      characterJson["inventory"] = inventoryJson.toString();
      
      // game event
      characterJson["sightDistance"] = character.sightDistance.toString();
      characterJson["preBattleText"] = character.preBattleText;
      // post battle event
      
      charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
}