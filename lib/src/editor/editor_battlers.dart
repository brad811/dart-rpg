library dart_rpg.editor_battlers;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class EditorBattlers {
  static Map<String, List<BattlerChance>> battlerChances = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_battler_button").onClick.listen((MouseEvent e) {
      battlerChances[Main.world.curMap].add(
        new BattlerChance(
          new Battler( "Common", World.battlerTypes["Common"], 2, [] ),
          0
        )
      );
      update();
      Editor.updateMap();
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
      "    <td>Num</td><td>Sprite</td><td>Name</td><td>Health</td><td>Attack</td><td>Speed</td>"+
      "  </tr>";
    for(int i=0; i<battlerChances[Main.world.curMap].length; i++) {
      battlersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='battlers_sprite_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].battler.spriteId }' /></td>"+
        "  <td><input id='battlers_name_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].battler.name }' /></td>"+
        "  <td><input id='battlers_health_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].battler.baseHealth }' /></td>"+
        "  <td><input id='battlers_attack_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].battler.baseAttack }' /></td>"+
        "  <td><input id='battlers_speed_${i}' type='text' value='${ battlerChances[Main.world.curMap][i].battler.baseSpeed }' /></td>"+
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
      Editor.updateMap();
    };
    
    for(int i=0; i<battlerChances[Main.world.curMap].length; i++) {
      List<String> attrs = ["sprite", "name", "health", "attack", "speed"];
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
        "sprite": battlerChance.battler.spriteId,
        "name": battlerChance.battler.name,
        "health": battlerChance.battler.baseHealth,
        "attack": battlerChance.battler.baseAttack,
        "speed": battlerChance.battler.baseSpeed
      });
    }
  }
}