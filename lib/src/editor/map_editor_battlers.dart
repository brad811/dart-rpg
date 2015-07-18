library dart_rpg.map_editor_battlers;

import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';

class MapEditorBattlers {
  static void setUp() {
    Editor.attachButtonListener("#add_battler_button", addNewBattler);
  }
  
  static void addNewBattler(MouseEvent e) {
    Main.world.maps[Main.world.curMap].battlerChances.add(
      new BattlerChance(
        new Battler( World.battlerTypes.keys.first, World.battlerTypes.values.first, 1, [] ),
        1.0
      )
    );
    
    Editor.update();
  }
  
  static void update() {
    String battlersHtml;
    battlersHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>#</td><td>Battler Type</td><td>Level</td><td>Chance</td><td></td>"+
      "  </tr>";
    
    double totalChance = 0.0;
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      totalChance += Main.world.maps[Main.world.curMap].battlerChances[i].chance;
    }
    
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      int percentChance = 0;
      if(totalChance != 0)
        percentChance = (Main.world.maps[Main.world.curMap].battlerChances[i].chance / totalChance * 100).round();
      
      battlersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td>";
      
      battlersHtml += "<select id='map_battler_${i}_type'>";
      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        battlersHtml += "<option value='${battlerType.name}'";
        if(Main.world.maps[Main.world.curMap].battlerChances[i].battler.name == name) {
          battlersHtml += " selected";
        }
        
        battlersHtml += ">${battlerType.name}</option>";
      });
      battlersHtml += "</select>";
      
      battlersHtml +=
        "  </td>"+
        "  <td><input id='map_battler_${i}_level' type='text' value='${ Main.world.maps[Main.world.curMap].battlerChances[i].battler.level }' /></td>"+
        "  <td><input id='map_battler_${i}_chance' type='text' value='${ Main.world.maps[Main.world.curMap].battlerChances[i].chance }' /> ${percentChance}%</td>"+
        "  <td><button id='delete_map_battler_${i}'>Delete</button></td>" +
        "</tr>";
    }
    battlersHtml += "</table>";
    querySelector("#battlers_container").setInnerHtml(battlersHtml);
    
    setMapBattlerDeleteButtonListeners();
    
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      Editor.attachInputListeners("map_battler_${i}", ["type", "level", "chance"], onInputChange);
    }
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      // enforce number format
      if(target.id.contains("_level")) {
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      } else if(target.id.contains("_chance")) {
        target.value = target.value.replaceAll(new RegExp(r'[^0-9\.]'), "");
      }
    }
    
    Main.world.maps[Main.world.curMap].battlerChances = new List<BattlerChance>();
    for(int i=0; querySelector('#map_battler_${i}_type') != null; i++) {
      try {
        String battlerTypeName = Editor.getSelectInputStringValue('#map_battler_${i}_type');
        int battlerTypeLevel = Editor.getTextInputIntValue('#map_battler_${i}_level', 1);
        double battlerTypeChance = Editor.getTextInputDoubleValue('#map_battler_${i}_chance', 1.0);
        
        Battler battler = new Battler(
          null,
          World.battlerTypes[battlerTypeName],
          battlerTypeLevel,
          World.battlerTypes[battlerTypeName].levelAttacks.values.toList()
        );
        
        BattlerChance battlerChance = new BattlerChance(battler, battlerTypeChance);
        Main.world.maps[Main.world.curMap].battlerChances.add(battlerChance);
      } catch(e) {
        // could not update this map battler
        print("Error updating map battler: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void setMapBattlerDeleteButtonListeners() {
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      Editor.setListDeleteButtonListeners(
        Main.world.maps[Main.world.curMap].battlerChances,
        "map_battler"
      );
    }
  }
  
  static void export(Map jsonMap, String key) {
    jsonMap["battlers"] = [];
    for(BattlerChance battlerChance in Main.world.maps[Main.world.curMap].battlerChances) {
      jsonMap["battlers"].add({
        "name": battlerChance.battler.name,
        "type": battlerChance.battler.name,
        "level": battlerChance.battler.level,
        "chance": battlerChance.chance
      });
    }
  }
}