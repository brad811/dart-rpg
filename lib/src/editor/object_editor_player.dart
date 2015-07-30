library dart_rpg.object_editor_player;

import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';

// TODO: inventory window doesn't hide properly

class ObjectEditorPlayer {
  static List<String> advancedTabs = ["player_inventory"];
  static bool selected = false;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_player_inventory_item_button", addInventoryItem);
  }
  
  static void addInventoryItem(MouseEvent e) {
    for(int i=0; i<World.items.keys.length; i++) {
      if(!Main.player.inventory.itemNames().contains(World.items.keys.elementAt(i))) {
        // add the first possible item that is not already in the player's inventory
        Main.player.inventory.addItem(World.items.values.elementAt(i));
        break;
      }
    }
    
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildMainHtml();
    buildInventoryHtml();
    
    if(selected) {
      querySelector("#player_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(Main.player.inventory.itemStacks, "player_inventory_item");
    
    List<String> attrs = [
      // main
      "name", //"sprite_id", "picture_id", "size_x", "size_y",
      
      // battle
      "battler_type", "battler_level",
      
      "money"
    ];
    
    Editor.attachInputListeners("player", attrs, onInputChange);
    
    // when a row is clicked, set it as selected and highlight it
    Editor.attachButtonListener("#player_row", (Event e) {
      selected = true;
      
      // hightlight the selected character row
      querySelector("#player_row").classes.add("selected");
      
      // show the characters advanced area
      querySelector("#player_advanced").classes.remove("hidden");
      
      // show the advanced tables for the selected character
      querySelector("#player_inventory_table").classes.remove("hidden");
    });
    
    for(int j=0; j<Main.player.inventory.itemNames().length; j++) {
      Editor.attachInputListeners("player_inventory_item_${j}", ["name", "quantity"], onInputChange);
    }
  }
  
  static void buildMainHtml() {
    String playerHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Name</td><td>Battler Type</td><td>Level</td><td>Money</td>"+
      "  </tr>"+
      "  <tr id='player_row'>"+
      "    <td><input id='player_name' type='text' value='${Main.player.name}' /></td>"+
      "    <td>";
      
    playerHtml += "<select id='player_battler_type'>";
    World.battlerTypes.forEach((String name, BattlerType battlerType) {
      playerHtml += "<option value='${battlerType.name}'";
      if(Main.player.battler.battlerType.name == name) {
        playerHtml += " selected";
      }
      
      playerHtml += ">${battlerType.name}</option>";
    });
    playerHtml += "</select>";
      
    playerHtml +=
      "    </td>"+
      "    <td><input id='player_battler_level' type='text' class='number' value='${Main.player.battler.level}' /></td>"+
      "    <td><input id='player_money' type='text' class='number' value='${Main.player.inventory.money}' /></td>"+
      "  </tr>";
    playerHtml += "</table>";
    querySelector("#player_container").setInnerHtml(playerHtml);
  }
  
  static void buildInventoryHtml() {
    String inventoryHtml = "";
    
    inventoryHtml += "<table id='player_inventory_table'>";
    inventoryHtml += "<tr><td>Num</td><td>Item</td><td>Quantity</td><td></td></tr>";
    for(int j=0; j<Main.player.inventory.itemNames().length; j++) {
      String curItemName = Main.player.inventory.itemNames().elementAt(j);
      inventoryHtml += "<tr>";
      inventoryHtml += "  <td>${j}</td>";
      inventoryHtml += "  <td><select id='player_inventory_item_${j}_name'>";
      World.items.keys.forEach((String itemOptionName) {
        String selectedString = "";
        
        if(itemOptionName != curItemName && Main.player.inventory.itemNames().contains(itemOptionName)) {
          // don't show items that are already somewhere else in the player's inventory
          return;
        }
        
        if(itemOptionName == curItemName) {
          selectedString = "selected=\"selected\"";
        }
        inventoryHtml += "<option ${selectedString}>${itemOptionName}</option>";
      });
      inventoryHtml += "  </select></td>";
      inventoryHtml += "  <td><input id='player_inventory_item_${j}_quantity' type='text' class='number' value='${Main.player.inventory.getQuantity(curItemName)}' /></td>";
      inventoryHtml += "  <td><button id='delete_player_inventory_item_${j}'>Delete</button></td>";
      inventoryHtml += "</tr>";
    }
    
    inventoryHtml += "</table>";
    
    querySelector("#player_inventory_container").setInnerHtml(inventoryHtml);
  }
  
  static void onInputChange(Event e) {
    String battlerType = (querySelector('#player_battler_type') as SelectElement).value;
    
    Editor.enforceValueFormat(e);
    
    Main.player.battler = new Battler(
      Editor.getTextInputStringValue('#player_name'),
      World.battlerTypes[battlerType],
      Editor.getTextInputIntValue('#player_battler_level', 2),
      World.battlerTypes[battlerType].levelAttacks.values.toList()
    );
    
    Main.player.inventory = new Inventory([]);
    
    for(int j=0; querySelector('#player_inventory_item_${j}_name') != null; j++) {
      String itemName = Editor.getSelectInputStringValue("#player_inventory_item_${j}_name");
      int itemQuantity = Editor.getTextInputIntValue("#player_inventory_item_${j}_quantity", 1);
      Main.player.inventory.addItem(World.items[itemName], itemQuantity);
    }
    
    Main.player.inventory.money = Editor.getTextInputIntValue("#player_money", 0);
    
    Main.player.gameEventChain = Editor.getSelectInputStringValue("#player_game_event_chain");
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Object> playerJson = {};
    playerJson["name"] = Main.player.name;
    playerJson["battlerType"] = Main.player.battler.battlerType.name;
    playerJson["level"] = Main.player.battler.level;
    playerJson["money"] = Main.player.inventory.money;
    
    // inventory
    List<Map<String, String>> inventoryJson = [];
    Main.player.inventory.itemNames().forEach((String itemName) {
      Map<String, String> itemJson = {};
      itemJson["item"] = itemName;
      itemJson["quantity"] = Main.player.inventory.getQuantity(itemName).toString();
      
      inventoryJson.add(itemJson);
    });
    
    playerJson["inventory"] = inventoryJson;
    
    exportJson["player"] = playerJson;
  }
}