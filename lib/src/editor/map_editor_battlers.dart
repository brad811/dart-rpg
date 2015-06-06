library dart_rpg.map_editor_battlers;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';

class MapEditorBattlers {
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_battler_button").onClick.listen((MouseEvent e) {
      Main.world.maps[Main.world.curMap].battlerChances.add(
        new BattlerChance(
          new Battler( World.battlerTypes.keys.first, World.battlerTypes.values.first, 2, [] ),
          1.0
        )
      );
      
      Editor.update();
    });
  }
  
  static void update() {
    String battlersHtml;
    battlersHtml = "<table>"+
      "  <tr>"+
      "    <td>#</td><td>Battler Type</td><td>Level</td><td>Chance</td><td></td>"+
      "  </tr>";
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      battlersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td>";
      
      battlersHtml += "<select id='map_battler_type_${i}'>";
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
        "  <td><input id='map_battler_level_${i}' type='text' value='${ Main.world.maps[Main.world.curMap].battlerChances[i].battler.level }' /></td>"+
        "  <td><input id='map_battler_chance_${i}' type='text' value='${ Main.world.maps[Main.world.curMap].battlerChances[i].chance }' /></td>"+
        "  <td><button id='delete_map_battler_${i}'>Delete</button></td>" +
        "</tr>";
    }
    battlersHtml += "</table>";
    querySelector("#battlers_container").innerHtml = battlersHtml;
    
    Function inputChangeFunction = (Event e) {
      if(e.target is InputElement) {
        InputElement target = e.target;
        
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
      
      Main.world.maps[Main.world.curMap].battlerChances = new List<BattlerChance>();
      for(int i=0; querySelector('#map_battler_type_${i}') != null; i++) {
        try {
          String battlerTypeName = (querySelector('#map_battler_type_${i}') as SelectElement).value;
          int battlerTypeLevel = int.parse((querySelector('#map_battler_level_${i}') as InputElement).value);
          double battlerTypeChance = double.parse((querySelector('#map_battler_chance_${i}') as InputElement).value);
          Battler battler = new Battler(null, World.battlerTypes[battlerTypeName], battlerTypeLevel, World.battlerTypes[battlerTypeName].levelAttacks.values.toList());
          BattlerChance battlerChance = new BattlerChance(battler, battlerTypeChance);
          Main.world.maps[Main.world.curMap].battlerChances.add(battlerChance);
        } catch(e) {
          // could not update this map battler
          print("Error updating map battler: " + e.toString());
        }
      }
      
      // TODO: perhaps move into base editor class
      if(e.target is InputElement) {
        // save the cursor location
        InputElement target = e.target;
        InputElement inputElement = querySelector('#' + target.id);
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
    
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      List<String> attrs = [/*"name", */"type", "level"];
      for(String attr in attrs) {
        if(listeners["#map_battler_${attr}_${i}"] != null)
          listeners["#map_battler_${attr}_${i}"].cancel();
        
        listeners["#map_battler_${attr}_${i}"] = 
            querySelector('#map_battler_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void export(Map jsonMap, String key) {
    jsonMap["battlers"] = [];
    for(BattlerChance battlerChance in Main.world.maps[Main.world.curMap].battlerChances) {
      jsonMap["battlers"].add({
        "name": battlerChance.battler.name,
        "type": battlerChance.battler.battlerType.name,
        "level": battlerChance.battler.level
      });
    }
  }
}