library dart_rpg.object_editor_items;

import 'dart:html';

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'object_editor.dart';

// TODO: item effects
// TODO: when you can use items
// TODO: item targets
// TODO: max length of things

class ObjectEditorItems {
  static void setUp() {
    Editor.attachButtonListener("#add_item_button", addNewItem);
  }
  
  static void addNewItem(MouseEvent e) {
    World.items["Item"] = new Item();
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    String itemsHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Picture Id</td><td>Name</td><td>Base Price</td><td>Description</td>"+
      "  </tr>";
    for(int i=0; i<World.items.keys.length; i++) {
      Item item = World.items.values.elementAt(i);
      
      itemsHtml +=
        "<tr>"+
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
    
    Editor.setMapDeleteButtonListeners(World.items, "item");
    
    List<String> attrs = ["picture_id", "name", "base_price", "description"];
    for(int i=0; i<World.items.keys.length; i++) {
      Editor.attachInputListeners("item_${i}", attrs, onInputChange);
    }
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains("_name") && World.items.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.items.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      } else if(target.id.contains("_picture_id") || target.id.contains("_base_price")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
    }
    
    World.items = new Map<String, Item>();
    for(int i=0; querySelector('#item_${i}_name') != null; i++) {
      try {
        String name = (querySelector('#item_${i}_name') as TextInputElement).value;
        World.items[name] = new Item(
          Editor.getTextInputIntValue('#item_${i}_picture_id', 1),
          name,
          Editor.getTextInputIntValue('#item_${i}_base_price', 1),
          (querySelector('#item_${i}_description') as TextAreaElement).value
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
      itemsJson[item.name] = itemJson;
    });
    
    exportJson["items"] = itemsJson;
  }
}