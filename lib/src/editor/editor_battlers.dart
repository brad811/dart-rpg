library EditorBattlers;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class EditorBattlers {
  static Map<String, List<Battler>> battlers = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_battler_button").onClick.listen((MouseEvent e) {
      battlers[Main.world.curMap].add(
        new Battler(
          0, "Battler",
          0, 0, 0,
          [],
          0
        )
      );
      update();
      Editor.updateMap();
    });
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      battlers[key] = [];
      
      for(Battler battler in Main.world.maps[key].battlers) {
        battlers[key].add(battler);
      }
    }
  }
  
  static void update() {
    String battlersHtml;
    battlersHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>Sprite</td><td>Name</td><td>Health</td><td>Attack</td><td>Speed</td>"+
      "  </tr>";
    for(int i=0; i<battlers[Main.world.curMap].length; i++) {
      battlersHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='battlers_sprite_${i}' type='text' value='${ battlers[Main.world.curMap][i].spriteId }' /></td>"+
        "  <td><input id='battlers_name_${i}' type='text' value='${ battlers[Main.world.curMap][i].name }' /></td>"+
        "  <td><input id='battlers_health_${i}' type='text' value='${ battlers[Main.world.curMap][i].baseHealth }' /></td>"+
        "  <td><input id='battlers_attack_${i}' type='text' value='${ battlers[Main.world.curMap][i].baseAttack }' /></td>"+
        "  <td><input id='battlers_speed_${i}' type='text' value='${ battlers[Main.world.curMap][i].baseSpeed }' /></td>"+
        "</tr>";
    }
    battlersHtml += "</table>";
    querySelector("#battlers_container").innerHtml = battlersHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<battlers[Main.world.curMap].length; i++) {
        try {
          battlers[Main.world.curMap][i] = new Battler(
            int.parse((querySelector('#battlers_sprite_${i}') as InputElement).value),
            (querySelector('#battlers_name_${i}') as InputElement).value,
            int.parse((querySelector('#battlers_health_${i}') as InputElement).value),
            int.parse((querySelector('#battlers_attack_${i}') as InputElement).value),
            int.parse((querySelector('#battlers_speed_${i}') as InputElement).value),
            [],
            0
          );
        } catch(e) {
          // could not update this battler
          print("Error updating battler! ( ${e} )");
        }
      }
      Editor.updateMap();
    };
    
    for(int i=0; i<battlers[Main.world.curMap].length; i++) {
      List<String> attrs = ["sprite", "name", "health", "attack", "speed"];
      for(String attr in attrs) {
        if(listeners["#battlers_${attr}_${i}"] != null)
          listeners["#battlers_${attr}_${i}"].cancel();
        
        print("derp derp: #battlers_${attr}_${i}");
        listeners["#battlers_${attr}_${i}"] = 
            querySelector('#battlers_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void export(Map jsonMap, String key) {
    jsonMap["battlers"] = [];
    for(Battler battler in battlers[key]) {
      jsonMap["battlers"].add({
        "sprite": battler.spriteId,
        "name": battler.name,
        "health": battler.baseHealth,
        "attack": battler.baseAttack,
        "speed": battler.baseSpeed
      });
    }
  }
}