library dart_rpg.object_editor_characters;

import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'object_editor.dart';
import 'object_editor_game_events.dart';

// TODO: dimensions, where character is solid and interactable

class ObjectEditorCharacters {
  static List<String> advancedTabs = ["character_inventory", "character_game_event", "character_battle"];
  static int selected;
  
  // TODO: update when adding new things
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_character_button", addNewCharacter);
    Editor.attachButtonListener("#add_inventory_item_button", addInventoryItem);
  }
  
  static void addNewCharacter(MouseEvent e) {
    Character newCharacter = new Character(
      "New Character",
      0, 0, 0, 0,
      layer: World.LAYER_BELOW,
      sizeX: 1, sizeY: 2,
      solid: true
    );
    
    BattlerType battlerType = World.battlerTypes.values.first;
    
    newCharacter.battler = new Battler(battlerType.name, battlerType, 2, battlerType.getAttacksForLevel(2));
    
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
    buildGameEventHtml();
    buildBattleHtml();
    
    // highlight the selected row
    if(querySelector("#character_row_${selected}") != null) {
      querySelector("#character_row_${selected}").classes.add("selected");
      querySelector("#characters_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(World.characters, "character");
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Editor.setMapDeleteButtonListeners(World.characters.values.elementAt(i).inventory.itemStacks, "character_${i}_item");
    }
    
    List<String> attrs = [
      // main
      "label", "name", "sprite_id", "picture_id", "size_x", "size_y", "map",
      
      // battle
      "battler_type", "battler_level", "sight_distance",
      
      // game event chain
      "game_event_chain"
    ];
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Editor.attachInputListeners("character_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#character_row_${i}", (Event e) {
        if(querySelector("#character_row_${i}") != null) {
          selectRow(i);
        }
      });
      
      Character character = World.characters.values.elementAt(i);
      
      for(int j=0; j<character.inventory.itemNames().length; j++) {
        Editor.attachInputListeners("character_${i}_inventory_${j}", ["item", "quantity"], onInputChange);
      }
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.characters.keys.length; j++) {
      // un-highlight other character rows
      querySelector("#character_row_${j}").classes.remove("selected");
      
      // hide the inventory items for other characters
      querySelector("#character_${j}_inventory_table").classes.add("hidden");
      querySelector("#character_${j}_game_event_chain_container").classes.add("hidden");
      querySelector("#character_${j}_battle_container").classes.add("hidden");
    }
    
    // hightlight the selected character row
    querySelector("#character_row_${i}").classes.add("selected");
    
    // show the characters advanced area
    querySelector("#characters_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected character
    querySelector("#character_${i}_inventory_table").classes.remove("hidden");
    querySelector("#character_${i}_game_event_chain_container").classes.remove("hidden");
    querySelector("#character_${i}_battle_container").classes.remove("hidden");
  }
  
  static void buildMainHtml() {
    String charactersHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Label</td>"+
      "    <td>Name</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Picture Id</td>"+
      "    <td>Size X</td>"+
      "    <td>Size Y</td>"+
      "    <td>Map</td>"+
      "    <td></td>"+
      "  </tr>";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String key = World.characters.keys.elementAt(i);
      
      charactersHtml +=
        "<tr id='character_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input id='character_${i}_label' type='text' value='${ key }' /></td>"+
        "  <td><input id='character_${i}_name' type='text' value='${ World.characters[key].name }' /></td>"+
        "  <td><input id='character_${i}_sprite_id' type='text' class='number' value='${ World.characters[key].spriteId }' /></td>"+
        "  <td><input id='character_${i}_picture_id' type='text' class='number' value='${ World.characters[key].pictureId }' /></td>"+
        "  <td><input id='character_${i}_size_x' type='text' class='number' value='${ World.characters[key].sizeX }' /></td>"+
        "  <td><input id='character_${i}_size_y' type='text' class='number' value='${ World.characters[key].sizeY }' /></td>";
        
        // map selector
        charactersHtml += "<td><select id='character_${i}_map'>";
        Main.world.maps.keys.forEach((String mapName) {
          charactersHtml += "<option value='${mapName}'";
          if(World.characters[key].map == mapName) {
            charactersHtml += " selected";
          }
          
          charactersHtml += ">${mapName}</option>";
        });
        
        charactersHtml += "  <td><button id='delete_character_${i}'>Delete</button></td>"+
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
        inventoryHtml += "  <td><select id='character_${i}_inventory_${j}_item'>";
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
        inventoryHtml += "  <td><input id='character_${i}_inventory_${j}_quantity' type='text' class='number' value='${character.inventory.getQuantity(curItemName)}' /></td>";
        inventoryHtml += "  <td><button id='delete_character_${i}_item_${j}'>Delete</button></td>";
        inventoryHtml += "</tr>";
      }
      
      inventoryHtml += "</table>";
    }
    
    querySelector("#inventory_container").setInnerHtml(inventoryHtml);
  }
  
  static void buildGameEventHtml() {
    String gameEventHtml = "";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      Character character = World.characters.values.elementAt(i);
      
      // game event chain selector
      gameEventHtml += "<div id='character_${i}_game_event_chain_container' ${visibleString}>";
      gameEventHtml += "Game Event Chain: <select id='character_${i}_game_event_chain'>";
      gameEventHtml += "  <option value=''>None</option>";
      for(int j=0; j<World.gameEventChains.keys.length; j++) {
        String name = World.gameEventChains.keys.elementAt(j);
        
        gameEventHtml += "  <option value='${name}' ";
        
        if(character.gameEventChain == name) {
          gameEventHtml += "selected='selected'";
        }
          
        gameEventHtml += ">${name}</option>";
      }
      gameEventHtml += "</select><hr />";
      
      // sight distance
      gameEventHtml += "Sight Distance: ";
      gameEventHtml += "<input id='character_${i}_sight_distance' type='text' class='number' value='${character.sightDistance}' />";
      gameEventHtml += "<hr />";
      
      gameEventHtml += "<table id='character_${i}_game_event_table'>";
      gameEventHtml += "<tr><td>Num</td><td>Event Type</td><td>Params</td><td></td></tr>";
      
      if(character.gameEventChain != null && character.gameEventChain != ""
          && World.gameEventChains[character.gameEventChain] != null) {
        for(int j=0; j<World.gameEventChains[character.gameEventChain].length; j++) {
          gameEventHtml +=
            ObjectEditorGameEvents.buildGameEventTableRowHtml(
              World.gameEventChains[character.gameEventChain][j],
              "character_${i}_game_event_${j}",
              j,
              readOnly: true
            );
        }
      }
      
      gameEventHtml += "</table>";
      gameEventHtml += "</div>";
    }
    
    querySelector("#character_game_event_container").setInnerHtml(gameEventHtml);
  }
  
  static void buildBattleHtml() {
    String battleHtml = "";
    
    for(int i=0; i<World.characters.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      Character character = World.characters.values.elementAt(i);
      
      battleHtml += "<table id='character_${i}_battle_container' ${visibleString}>";
      battleHtml += "<tr><td>Battler Type</td><td>Level</td></tr>";
      
      battleHtml += "<tr><td><select id='character_${i}_battler_type'>";
      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        battleHtml += "<option value='${battlerType.name}'";
        if(character.battler.battlerType.name == name) {
          battleHtml += " selected";
        }
        
        battleHtml += ">${battlerType.name}</option>";
      });
      battleHtml += "</select></td>";
      
      battleHtml += "<td><input id='character_${i}_battler_level' type='text' class='number' value='${character.battler.level}' /></td>";
      
      battleHtml += "</tr></table>";
    }
    
    querySelector("#battle_container").setInnerHtml(battleHtml);
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_label", World.characters);
    
    Map<String, Character> charactersBefore = new Map<String, Character>();
    charactersBefore.addAll(World.characters);
    
    World.characters = new Map<String, Character>();
    for(int i=0; querySelector('#character_${i}_label') != null; i++) {
      try {
        String label = Editor.getTextInputStringValue('#character_${i}_label');
        
        int mapX = 0, mapY = 0;
        if(charactersBefore[label] != null) {
          mapX = charactersBefore[label].mapX;
          mapY = charactersBefore[label].mapY;
        }
        
        Character character = new Character(
          label,
          Editor.getTextInputIntValue('#character_${i}_sprite_id', 1),
          Editor.getTextInputIntValue('#character_${i}_picture_id', 1),
          mapX, mapY,
          layer: World.LAYER_BELOW,
          sizeX: Editor.getTextInputIntValue('#character_${i}_size_x', 1),
          sizeY: Editor.getTextInputIntValue('#character_${i}_size_y', 2),
          solid: true
        );
        
        character.name = Editor.getTextInputStringValue('#character_${i}_name');
        
        character.map = Editor.getSelectInputStringValue("#character_${i}_map");
        
        String battlerTypeName = Editor.getSelectInputStringValue('#character_${i}_battler_type');
        
        int level = Editor.getTextInputIntValue('#character_${i}_battler_level', 2);
        
        // TODO: add battler name field
        Battler battler = new Battler(
          "name",
          World.battlerTypes[battlerTypeName],
          level,
          World.battlerTypes[battlerTypeName].getAttacksForLevel(level)
        );
        
        character.battler = battler;
        character.sightDistance = Editor.getTextInputIntValue('#character_${i}_sight_distance', 0);
        
        World.characters[label] = character;
      } catch(e) {
        // could not update this character
        print("Error updating character: " + e.toString());
      }
    }
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);
      character.inventory = new Inventory([]);
      
      for(int j=0; querySelector('#character_${i}_inventory_${j}_item') != null; j++) {
        String itemName = Editor.getSelectInputStringValue('#character_${i}_inventory_${j}_item');
        int itemQuantity = Editor.getTextInputIntValue('#character_${i}_inventory_${j}_quantity', 1);
        character.inventory.addItem(World.items[itemName], itemQuantity);
      }
      
      character.gameEventChain = Editor.getSelectInputStringValue("#character_${i}_game_event_chain");
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    World.characters.forEach((String key, Character character) {
      Map<String, Object> characterJson = {};
      characterJson["spriteId"] = character.spriteId;
      characterJson["pictureId"] = character.pictureId;
      characterJson["sizeX"] = character.sizeX;
      characterJson["sizeY"] = character.sizeY;
      characterJson["map"] = character.map;
      characterJson["name"] = character.name;
      
      // map information
      characterJson["mapX"] = character.mapX;
      characterJson["mapY"] = character.mapY;
      characterJson["layer"] = character.layer;
      characterJson["direction"] = character.direction;
      characterJson["solid"] = character.solid;
      
      // inventory
      List<Map<String, String>> inventoryJson = [];
      character.inventory.itemNames().forEach((String itemName) {
        Map<String, String> itemJson = {};
        itemJson["item"] = itemName;
        itemJson["quantity"] = character.inventory.getQuantity(itemName).toString();
        
        inventoryJson.add(itemJson);
      });
      
      characterJson["inventory"] = inventoryJson;
      
      // game event chain
      characterJson["gameEventChain"] = character.gameEventChain;
      
      // battle
      characterJson["battlerType"] = character.battler.battlerType.name;
      characterJson["battlerLevel"] = character.battler.level.toString();
      characterJson["sightDistance"] = character.sightDistance.toString();
      
      charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
}