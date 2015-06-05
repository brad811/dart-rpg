library dart_rpg.map_editor_battlers;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'map_editor.dart';

class MapEditorBattlers {
  static Map<String, List<BattlerChance<Battler, double>>> battlerChances = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_battler_button").onClick.listen((MouseEvent e) {
      battlerChances[Main.world.curMap].add(
        new BattlerChance(
          new Battler( World.battlerTypes.keys.first, World.battlerTypes.values.first, 2, [] ),
          1.0
        )
      );
      
      Editor.update();
    });
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      battlerChances[key] = [];
      
      for(BattlerChance battlerChance in Main.world.maps[key].battlerChances) {
        battlerChances[key].add(battlerChance);
      }
    }
  }
  
  static void update() {
    String battlersHtml;
    battlersHtml = "<table>"+
      "  <tr>"+
      "    <td>#</td><td>Battler Type</td><td>Level</td><td>Chance</td><td></td>"+
      "  </tr>";
    for(int i=0; i<battlerChances[Main.world.curMap].length; i++) {
      battlersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td>";
      
      battlersHtml += "<select id='map_battler_type_${i}'>";
      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        battlersHtml += "<option value='${battlerType.name}'>${battlerType.name}</option>";
      });
      battlersHtml += "</select>";
      
      battlersHtml +=
        "  </td>"+
        "  <td><input id='map_battler_level_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].battler.level }' /></td>"+
        "  <td><input id='map_battler_chance_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].chance }' /></td>"+
        "  <td><button id='delete_map_battler_${i}'>Delete</button></td>" +
        "</tr>";
    }
    battlersHtml += "</table>";
    querySelector("#battlers_container").innerHtml = battlersHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<battlerChances[Main.world.curMap].length; i++) {
        try {
          /*
          battlerChances[Main.world.curMap][i].battler = new Battler(
            int.parse((querySelector('#battlers_sprite_${i}') as InputElement).value),
            (querySelector('#battlers_name_${i}') as InputElement).value,
            int.parse((querySelector('#battlers_health_${i}') as InputElement).value),
            int.parse((querySelector('#battlers_attack_${i}') as InputElement).value),
            int.parse((querySelector('#battlers_speed_${i}') as InputElement).value),
            [],
            0
          );
          */
        } catch(e) {
          // could not update this battler
          print("Error updating battler! ( ${e} )");
        }
      }
      
      MapEditor.updateMap(shouldExport: true);
    };
    
    for(int i=0; i<battlerChances[Main.world.curMap].length; i++) {
      List<String> attrs = [/*"name", */"type", "level"];
      for(String attr in attrs) {
        if(listeners["#battlers_${attr}_${i}"] != null)
          listeners["#battlers_${attr}_${i}"].cancel();
        
        listeners["#battlers_${attr}_${i}"] = 
            querySelector('#battlers_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void export(Map jsonMap, String key) {
    jsonMap["battlers"] = [];
    for(BattlerChance battlerChance in battlerChances[key]) {
      jsonMap["battlers"].add({
        "name": battlerChance.battler.name,
        "type": battlerChance.battler.battlerType.name,
        "level": battlerChance.battler.level
      });
    }
  }
}