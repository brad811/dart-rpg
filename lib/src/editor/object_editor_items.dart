library dart_rpg.object_editor_items;

import 'dart:html';

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';
import 'package:dart_rpg/src/editor/object_editor_game_events.dart';

// TODO: when you can use items
// TODO: item targets
// TODO: max length of things

class ObjectEditorItems {
  static List<String> advancedTabs = ["item_game_event"];
  
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_item_button", addNewItem);
    
    querySelector("#object_editor_items_tab_header").onClick.listen((MouseEvent e) {
      ObjectEditorItems.selectRow(0);
    });
  }
  
  static void addNewItem(MouseEvent e) {
    World.items["Item"] = new Item();
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildMainHtml();
    buildGameEventHtml();
    
    // highlight the selected row
    if(querySelector("#item_row_${selected}") != null) {
      querySelector("#item_row_${selected}").classes.add("selected");
      querySelector("#object_editor_items_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(World.items, "item");
    
    List<String> attrs = [
      "picture_id", "name", "base_price", "description",
      
      // game event chain
      "game_event_chain"
    ];
    for(int i=0; i<World.items.keys.length; i++) {
      Editor.attachInputListeners("item_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#item_row_${i}", (Event e) {
        if(querySelector("#item_row_${i}") != null) {
          selectRow(i);
        }
      });
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.items.keys.length; j++) {
      // un-highlight other item rows
      querySelector("#item_row_${j}").classes.remove("selected");
      
      // hide the advanced containers for other rows
      querySelector("#item_${j}_game_event_chain_container").classes.add("hidden");
    }
    
    if(querySelector("#item_row_${i}") == null) {
      return;
    }
    
    // hightlight the selected row
    querySelector("#item_row_${i}").classes.add("selected");
    
    // show the advanced area
    querySelector("#object_editor_items_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected row
    querySelector("#item_${i}_game_event_chain_container").classes.remove("hidden");
  }
  
  static void buildMainHtml() {
    String itemsHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Picture Id</td><td>Name</td><td>Base Price</td><td>Description</td>"+
      "  </tr>";
    for(int i=0; i<World.items.keys.length; i++) {
      Item item = World.items.values.elementAt(i);
      
      itemsHtml +=
        "<tr id='item_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input class='number' id='item_${i}_picture_id' type='text' value='${item.pictureId}' /></td>"+
        "  <td><input id='item_${i}_name' type='text' value='${item.name}' /></td>"+
        "  <td><input class='number' id='item_${i}_base_price' type='text' value='${item.basePrice}' /></td>"+
        "  <td><textarea id='item_${i}_description' />${item.description}</textarea></td>"+
        "  <td><button id='delete_item_${i}'>Delete</button></td>"+
        "</tr>";
    }
    itemsHtml += "</table>";
    querySelector("#items_container").setInnerHtml(itemsHtml);
  }
  
  static void buildGameEventHtml() {
    String gameEventHtml = "";
    
    for(int i=0; i<World.items.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      Item item = World.items.values.elementAt(i);
      
      // game event chain selector
      gameEventHtml += "<div id='item_${i}_game_event_chain_container' ${visibleString}>";
      gameEventHtml += "Game Event Chain: <select id='item_${i}_game_event_chain'>";
      gameEventHtml += "  <option value=''>None</option>";
      for(int j=0; j<World.gameEventChains.keys.length; j++) {
        String name = World.gameEventChains.keys.elementAt(j);
        
        gameEventHtml += "  <option value='${name}' ";
        
        if(item.gameEventChain == name) {
          gameEventHtml += "selected='selected'";
        }
          
        gameEventHtml += ">${name}</option>";
      }
      gameEventHtml += "</select><hr />";
      
      gameEventHtml += "<table id='item_${i}_game_event_table'>";
      gameEventHtml += "<tr><td>Num</td><td>Event Type</td><td>Params</td><td></td></tr>";
      
      if(item.gameEventChain != null && item.gameEventChain != ""
          && World.gameEventChains[item.gameEventChain] != null) {
        for(int j=0; j<World.gameEventChains[item.gameEventChain].length; j++) {
          gameEventHtml +=
            ObjectEditorGameEvents.buildGameEventTableRowHtml(
              World.gameEventChains[item.gameEventChain][j],
              "item_${i}_game_event_${j}",
              j,
              readOnly: true
            );
        }
      }
      
      gameEventHtml += "</table>";
      gameEventHtml += "</div>";
    }
    
    querySelector("#item_game_event_container").setInnerHtml(gameEventHtml);
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.items);
    
    World.items = new Map<String, Item>();
    for(int i=0; querySelector('#item_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue("#item_${i}_name");
        World.items[name] = new Item(
          Editor.getTextInputIntValue('#item_${i}_picture_id', 1),
          name,
          Editor.getTextInputIntValue('#item_${i}_base_price', 1),
          Editor.getTextAreaStringValue("#item_${i}_description"),
          Editor.getSelectInputStringValue("#item_${i}_game_event_chain")
        );
      } catch(e) {
        // could not update this item
        print("Error updating item: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> itemsJson = {};
    World.items.forEach((String key, Item item) {
      Map<String, String> itemJson = {};
      itemJson["pictureId"] = item.pictureId.toString();
      itemJson["basePrice"] = item.basePrice.toString();
      itemJson["description"] = item.description;
      itemJson["gameEventChain"] = item.gameEventChain;
      itemsJson[item.name] = itemJson;
    });
    
    exportJson["items"] = itemsJson;
  }
}