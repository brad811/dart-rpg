library dart_rpg.object_editor_characters;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/inventory.dart';
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
    querySelector("#characters_advanced").classes.remove("hidden");
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
    buildBattleHtml();
    
    // TODO: add inventory, game event, and post battle event to right half
    // TODO: move level, sight distance, and pre-battle text under battle tab
    
    // highlight the selected row
    if(querySelector("#character_row_${selected}") != null) {
      querySelector("#character_row_${selected}").classes.add("selected");
      querySelector("#characters_advanced").classes.remove("hidden");
    }
    
    Editor.setDeleteButtonListeners(World.characters, "character", listeners);
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Editor.setDeleteButtonListeners(World.characters.values.elementAt(i).inventory.itemStacks, "character_${i}_item", listeners);
    }
    
    List<String> attrs = [
      "label", "sprite_id", "picture_id", //"battler_type", "level",
      "size_x", "size_y" /* inventory, game_event */
      /*"sight_distance", "pre_battle_text" post battle event */
    ];
    
    List<String> advanced_attrs = [
      "inventory_item", "inventory_quantity"
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
          // un-highlight other character rows
          querySelector("#character_row_${j}").classes.remove("selected");
          
          // hide the inventory items for other characters
          querySelector("#character_${j}_inventory_table").classes.add("hidden");
          querySelector("#character_${j}_battle_container").classes.add("hidden");
        }
        
        querySelector("#character_row_${i}").classes.add("selected");
        querySelector("#characters_advanced").classes.remove("hidden");
        
        // show the inventory table for the selected character
        querySelector("#character_${i}_inventory_table").classes.remove("hidden");
        querySelector("#character_${i}_battle_container").classes.remove("hidden");
      });
      
      Character character = World.characters.values.elementAt(i);
      for(int j=0; j<character.inventory.itemNames().length; j++) {
        for(String advanced_attr in advanced_attrs) {
          String elementSelector = "#character_${i}_${advanced_attr}_${j}";
          
          if(listeners[elementSelector] != null) {
            listeners[elementSelector].cancel();
          }
          
          listeners[elementSelector] = querySelector(elementSelector).onInput.listen(onInputChange);
        }
      }
    }
  }
  
  static void buildMainHtml() {
    String charactersHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Label</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Picture Id</td>"+
      "    <td>Size X</td>"+
      "    <td>Size Y</td>"+
      "    <td></td>"+
      "  </tr>";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String key = World.characters.keys.elementAt(i);
      
      charactersHtml +=
        "<tr id='character_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input id='character_label_${i}' type='text' value='${ key }' /></td>"+
        "  <td><input id='character_sprite_id_${i}' type='text' class='number' value='${ World.characters[key].spriteId }' /></td>"+
        "  <td><input id='character_picture_id_${i}' type='text' class='number' value='${ World.characters[key].pictureId }' /></td>"+
        "  <td><input id='character_size_x_${i}' type='text' class='number' value='${ World.characters[key].sizeX }' /></td>"+
        "  <td><input id='character_size_y_${i}' type='text' class='number' value='${ World.characters[key].sizeY }' /></td>"+
        "  <td><button id='delete_character_${i}'>Delete</button></td>"+
        "</tr>";
    }
    
    charactersHtml += "</table>";
    
    querySelector("#characters_container").setInnerHtml(charactersHtml);
  }
  
  static void buildInventoryHtml() {
    String inventoryHtml = "";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      inventoryHtml += "<table id='character_${i}_inventory_table' ${visibleString}>";
      inventoryHtml += "<tr><td>Num</td><td>Item</td><td>Quantity</td><td></td></tr>";
      Character character = World.characters.values.elementAt(i);
      for(int j=0; j<character.inventory.itemNames().length; j++) {
        String curItemName = character.inventory.itemNames().elementAt(j);
        inventoryHtml += "<tr>";
        inventoryHtml += "  <td>${j}</td>";
        inventoryHtml += "  <td><select id='character_${i}_inventory_item_${j}'>";
        World.items.keys.forEach((String itemOptionName) {
          String selectedString = "";
          
          if(itemOptionName != curItemName && character.inventory.itemNames().contains(itemOptionName)) {
            // don't show items that are already somewhere else in the character's inventory
            return;
          }
          
          if(itemOptionName == curItemName) {
            selectedString = "selected=\"selected\"";
          }
          inventoryHtml += "<option ${selectedString}>${itemOptionName}</option>";
        });
        inventoryHtml += "  </select></td>";
        inventoryHtml += "  <td><input id='character_${i}_inventory_quantity_${j}' type='text' class='number' value='${character.inventory.getQuantity(curItemName)}' /></td>";
        inventoryHtml += "  <td><button id='delete_character_${i}_item_${j}'>Delete</button></td>";
        inventoryHtml += "</tr>";
      }
      
      inventoryHtml += "</table>";
    }
    
    // TODO: replace all .innerHtml with .setInnerHtml()
    querySelector("#inventory_container").setInnerHtml(inventoryHtml);
  }
  
  static void buildBattleHtml() {
    String battleHtml = "";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String visibleString = "class='hidden'";
      print("Selected battle: ${selected}");
      if(selected == i) {
        visibleString = "";
      }
      
      Character character = World.characters.values.elementAt(i);
      
      battleHtml += "<div id='character_${i}_battle_container' ${visibleString}>";
      
      battleHtml += "Battler Type: <select id='character_battler_type_${i}'>";
      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        battleHtml += "<option value='${battlerType.name}'";
        if(character.battler.battlerType.name == name) {
          battleHtml += " selected";
        }
        
        battleHtml += ">${battlerType.name}</option>";
      });
      battleHtml += "</select><br />";
      
      battleHtml += "Level: <input type='text' class='number' value='${character.battler.level}' /><br />";
      battleHtml += "Sight Distance: <input type='text' class='number' value='${character.sightDistance}' /><br />";
      battleHtml += "Pre Battle Text: <textarea>${character.preBattleText}</textarea><br />";
      
      battleHtml += "</div>";
    }
    
    print("Setting battle html...");
    querySelector("#battle_container").setInnerHtml(battleHtml);
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
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);
      character.inventory = new Inventory([]);
      
      for(int j=0; querySelector('#character_${i}_inventory_item_${j}') != null; j++) {
        String itemName = (querySelector('#character_${i}_inventory_item_${j}') as SelectElement).value;
        int itemQuantity = int.parse((querySelector('#character_${i}_inventory_quantity_${j}') as TextInputElement).value);
        character.inventory.addItem(World.items[itemName], itemQuantity);
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    World.characters.forEach((String key, Character character) {
      Map<String, Object> characterJson = {};
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
      
      characterJson["inventory"] = inventoryJson;
      
      // game event
      characterJson["sightDistance"] = character.sightDistance.toString();
      characterJson["preBattleText"] = character.preBattleText;
      // post battle event
      
      charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
}