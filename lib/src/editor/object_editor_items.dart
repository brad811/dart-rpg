library dart_rpg.object_editor_items;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'object_editor.dart';

class ObjectEditorItems {
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_item_button").onClick.listen((MouseEvent e) {
      World.items["New Item"] = new Item();
      update();
      ObjectEditor.update();
    });
  }
  
  static void update() {
    String itemsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>Picture Id</td><td>Name</td><td>Base Price</td><td>Description</td>"+
      "  </tr>";
    for(int i=0; i<World.items.keys.length; i++) {
      String key = World.items.keys.elementAt(i);
      
      itemsHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input class='number' id='item_picture_id_${i}' type='text' value='${i}' /></td>"+
        "  <td><input id='item_name_${i}' type='text' value='${i}' /></td>"+
        "  <td><input class='number' id='item_base_price_${i}' type='text' value='${i}' /></td>"+
        "  <td><textarea id='item_description_${i}' />${i}</textarea></td>"+
        "  <td><button id='delete_item_${i}'>Delete</button></td>"+
        "</tr>";
    }
    itemsHtml += "</table>";
    querySelector("#items_container").innerHtml = itemsHtml;
    
    Editor.setDeleteButtonListeners(World.items, "item", listeners);
    
    Function inputChangeFunction = (Event e) {
      if(e.target is InputElement) {
        InputElement target = e.target;
        
        if(target.id.contains("item_name_") && World.items.keys.contains(target.value)) {
          // avoid name collisions
          int i = 0;
          for(; World.items.keys.contains(target.value + "_${i}"); i++) {}
          target.value += "_${i}";
        } else if(target.id.contains("item_picture_id_") || target.id.contains("item_base_price_")) {
          // enforce number format
          target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
        }
      }
      
      World.items = new Map<String, Item>();
      for(int i=0; querySelector('#item_name_${i}') != null; i++) {
        try {
          String name = (querySelector('#item_name_${i}') as InputElement).value;
          World.items[name] = new Item();
        } catch(e) {
          // could not update this item
          print("Error updating item: " + e.toString());
        }
      }
      
      // TODO: account for textarea
      if(e.target is TextInputElement) {
        // save the cursor location
        TextInputElement target = e.target;
        TextInputElement inputElement = querySelector('#' + target.id);
        int position = inputElement.selectionStart;
        
        // update everything
        Editor.update();
        
        // restore the cursor position
        inputElement = querySelector('#' + target.id);
        inputElement.focus();
        inputElement.setSelectionRange(position, position);
      } else {
        // update everything
        Editor.update();
      }
    };
    
    List<String> attrs = ["picture_id", "name", "base_price", "description"];
    for(int i=0; i<World.items.keys.length; i++) {
      for(String attr in attrs) {
        if(listeners["#item_${attr}_${i}"] != null)
          listeners["#item_${attr}_${i}"].cancel();
        
        listeners["#item_${attr}_${i}"] = 
            querySelector('#item_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
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