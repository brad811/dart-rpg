library dart_rpg.object_editor_types;

import 'dart:html';

import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';

class ObjectEditorTypes {
  static List<String> advancedTabs = ["type_effectiveness"];
  
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_type_button", addNewType);
    
    querySelector("#object_editor_types_tab_header").onClick.listen((MouseEvent e) {
      ObjectEditorTypes.selectRow(0);
    });
  }
  
  static void addNewType(MouseEvent e) {
    World.types["New Type"] = new GameType("New Type");
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildMainHtml();
    buildEffectivenessHtml();
    
    // highlight the selected row
    if(querySelector("#type_row_${selected}") != null) {
      querySelector("#type_row_${selected}").classes.add("selected");
      querySelector("#object_editor_types_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(World.types, "type");
    
    List<String> attrs = [
      "name"
    ];
    for(int i=0; i<World.types.keys.length; i++) {
      Editor.attachInputListeners("type_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#type_row_${i}", (Event e) {
        if(querySelector("#type_row_${i}") != null) {
          selectRow(i);
        }
      });
      
      List<String> advancedAttrs = [];
      for(int j=0; j<World.types.keys.length; j++) {
        advancedAttrs.add("effectiveness_${j}");
      }
      
      Editor.attachInputListeners("type_${i}", advancedAttrs, onInputChange);
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.types.keys.length; j++) {
      // un-highlight other rows
      querySelector("#type_row_${j}").classes.remove("selected");
      
      // hide the advanced containers for other rows
      querySelector("#type_${j}_effectiveness_container").classes.add("hidden");
    }
    
    if(querySelector("#type_row_${i}") == null) {
      return;
    }
    
    // hightlight the selected row
    querySelector("#type_row_${i}").classes.add("selected");
    
    // show the advanced area
    querySelector("#object_editor_types_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected row
    querySelector("#type_${i}_effectiveness_container").classes.remove("hidden");
  }
  
  static void buildMainHtml() {
    String html = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Name</td><td></td>"+
      "  </tr>";
    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);
      
      html +=
        "<tr id='type_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input id='type_${i}_name' type='text' value='${gameType.name}' /></td>"+
        "  <td><button id='delete_type_${i}'>Delete</button></td>"+
        "</tr>";
    }
    html += "</table>";
    querySelector("#types_container").setInnerHtml(html);
  }
  
  static void buildEffectivenessHtml() {
    String html = "";
    
    for(int i=0; i<World.types.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      GameType gameType = World.types.values.elementAt(i);
      
      html += "<div id='type_${i}_effectiveness_container' ${visibleString}>";
      
      html += "<table>";
      html += "<tr><td>Num</td><td>Defending Type</td><td>Effectiveness</td></tr>";
      for(int j=0; j<World.types.keys.length; j++) {
        GameType defendingGameType = World.types.values.elementAt(j);
        
        html += "<tr>";
        html += "<td>${j}</td>";
        html += "<td>${defendingGameType.name}</td>";
        html += "<td><input id='type_${i}_effectiveness_${j}' type='text' class='number decimal' "+
            "value='${gameType.getEffectiveness(defendingGameType.name)}' /></td>";
        html += "</tr>";
      }
      html += "</table>";

      html += "</div>";
    }
    
    querySelector("#type_effectiveness_container").setInnerHtml(html);
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.types);
    
    World.types = new Map<String, GameType>();
    for(int i=0; querySelector('#type_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue("#type_${i}_name");
        World.types[name] = new GameType(name);
      } catch(e) {
        // could not update this type
        print("Error updating type: " + e.toString());
      }
    }
    
    for(int i=0; i<World.types.keys.length; i++) {
      try {
        GameType attackingType = World.types.values.elementAt(i);
        
        // iterate through effectiveness
        for(int j=0; j<World.types.keys.length; j++) {
          attackingType.setEffectiveness(
            World.types.keys.elementAt(j),
            Editor.getTextInputDoubleValue("#type_${i}_effectiveness_${j}", 1.0)
          );
        }
      } catch(e) {
        // could not update this type
        print("Error updating type effectiveness: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> typesJson = {};
    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);
      
      Map<String, Object> typeJson = {};
      typeJson["name"] = gameType.name;
      
      Map<String, double> typeEffectivenessJson = {};
      
      // iterate through effectiveness
      for(int j=0; j<World.types.length; j++) {
        typeEffectivenessJson[World.types.keys.elementAt(j)] = gameType.getEffectiveness(World.types.keys.elementAt(j));
      }
      
      typeJson["effectiveness"] = typeEffectivenessJson;
      
      typesJson[gameType.name] = typeJson;
    }
    
    exportJson["types"] = typesJson;
  }
}