library dart_rpg.object_editor_battler_types;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'object_editor.dart';

class ObjectEditorBattlerTypes {
  static Map<String, StreamSubscription> listeners = {};
  
  // TODO: give battler types a display name and a unique name
  //   so people can name them stuff like "end_boss_1"
  //   but still have a pretty display name like "Bob"
  
  static void setUp() {
    querySelector("#add_battler_type_button").onClick.listen(addNewBattlerType);
  }
  
  static void addNewBattlerType(MouseEvent e) {
    World.battlerTypes["New Battler Type"] = new BattlerType(
        0, "New Battler",
        0, 0, 0, 0, 0, 0,
        {}, 1.0
      );
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    String battlerTypesHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Name</td>"+
      "    <td>Health</td>"+
      "    <td>Physical<br />Attack</td>"+
      "    <td>Magical<br />Attack</td>"+
      "    <td>Physical<br />Defense</td>"+
      "    <td>Magical<br />Defense</td>"+
      "    <td>Speed</td>"+
      "    <td>Level Attacks</td>"+
      "    <td>Rarity</td>"+
      "  </tr>";
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String key = World.battlerTypes.keys.elementAt(i);
      
      battlerTypesHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input class='number' id='battler_types_sprite_id_${i}' type='text' value='${ World.battlerTypes[key].spriteId }' /></td>"+
        "  <td><input id='battler_types_name_${i}' type='text' value='${ World.battlerTypes[key].name }' /></td>"+
        "  <td><input class='number' id='battler_types_health_${i}' type='text' value='${ World.battlerTypes[key].baseHealth }' /></td>"+
        "  <td><input class='number' id='battler_types_physical_attack_${i}' type='text' value='${ World.battlerTypes[key].basePhysicalAttack }' /></td>"+
        "  <td><input class='number' id='battler_types_magical_attack_${i}' type='text' value='${ World.battlerTypes[key].baseMagicalAttack }' /></td>"+
        "  <td><input class='number' id='battler_types_physical_defense_${i}' type='text' value='${ World.battlerTypes[key].basePhysicalDefense }' /></td>"+
        "  <td><input class='number' id='battler_types_magical_defense_${i}' type='text' value='${ World.battlerTypes[key].baseMagicalDefense }' /></td>"+
        "  <td><input class='number' id='battler_types_speed_${i}' type='text' value='${ World.battlerTypes[key].baseSpeed }' /></td>"+
        "  <td>";
      
      int j = 0;
      World.battlerTypes[key].levelAttacks.forEach((int level, Attack levelAttack) {
        battlerTypesHtml += "<input class='number' id='battler_types_${i}_attack_${j}_level' type='text' value='${level}' />";
        battlerTypesHtml += "<select id='battler_types_${i}_attack_${j}_name'>";
        World.attacks.forEach((String name, Attack attack) {
          battlerTypesHtml += "<option ";
          if(name == levelAttack.name) {
            battlerTypesHtml += "selected";
          }
          battlerTypesHtml += ">${attack.name}</option>";
        });
        battlerTypesHtml += "</select>";
        battlerTypesHtml += "<button id='delete_battler_type_${i}_attack_${j}'>Delete attack</button><br />";
        
        j++;
      });
      
      battlerTypesHtml += "<button id='add_battler_type_${i}_attack'>Add attack</button>";
        
      battlerTypesHtml +=
        "  </td>"+
        "  <td><input class='number' id='battler_types_rarity_${i}' type='text' value='${ World.battlerTypes[key].rarity }' /></td>"+
        "  <td><button id='delete_battler_type_${i}'>Delete battler type</button></td>" +
        "</tr>";
    }
    battlerTypesHtml += "</table>";
    querySelector("#battler_types_container").setInnerHtml(battlerTypesHtml);
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      querySelector("#add_battler_type_${i}_attack").onClick.listen((MouseEvent e) {
        BattlerType battlerType = World.battlerTypes.values.elementAt(i);
        int nextLevel = 1;
        for(;  battlerType.levelAttacks[nextLevel] != null; nextLevel++);
        battlerType.levelAttacks[nextLevel] = World.attacks.values.first;
        Editor.update();
      });
    }
    
    Editor.setMapDeleteButtonListeners(World.battlerTypes, "battler_type", listeners);
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);
      Editor.setMapDeleteButtonListeners(battlerType.levelAttacks, "battler_type_${i}_attack", listeners);
    }
    
    // TODO: perhaps move into base editor class
    List<String> attrs = [
      "sprite_id", "name",
      "health", "physical_attack", "magical_attack",
      "physical_defense", "magical_defense", "speed",
      "rarity"
    ];
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      for(String attr in attrs) {
        if(listeners["#battler_types_${attr}_${i}"] != null)
          listeners["#battler_types_${attr}_${i}"].cancel();
        
        listeners["#battler_types_${attr}_${i}"] = 
            querySelector('#battler_types_${attr}_${i}').onInput.listen(onInputChange);
      }
    }
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      for(int j=0; j<World.battlerTypes.values.elementAt(i).levelAttacks.values.length; j++) {
        if(listeners["#battler_types_${i}_attack_${j}_level"] != null)
          listeners["#battler_types_${i}_attack_${j}_level"].cancel();
        
        listeners["#battler_types_${i}_attack_${j}_level"] = 
            querySelector('#battler_types_${i}_attack_${j}_level').onInput.listen(onInputChange);
        
        if(listeners["#battler_types_${i}_attack_${j}_name"] != null)
          listeners["#battler_types_${i}_attack_${j}_name"].cancel();
        
        listeners["#battler_types_${i}_attack_${j}_name"] = 
            querySelector('#battler_types_${i}_attack_${j}_name').onInput.listen(onInputChange);
      }
    }
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains("battler_types_name_") && World.battlerTypes.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.battlerTypes.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      } else if(target.id.contains("battler_types_magical_") || target.id.contains("battler_types_physical_")
          || target.id.contains("battler_types_health_") || target.id.contains("battler_types_sprite_")
          || target.id.contains("battler_types_speed_") || target.id.contains("_level")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      } else if(target.id.contains("battler_types_rarity_")) {
        target.value = target.value.replaceAll(new RegExp(r'[^0-9\.]'), "");
      }
    }
    
    World.battlerTypes = new Map<String, BattlerType>();
    for(int i=0; querySelector('#battler_types_name_${i}') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue('#battler_types_name_${i}');
        
        Map<int, Attack> levelAttacks = new Map<int, Attack>();
        for(int j=0; querySelector("#battler_types_${i}_attack_${j}_level") != null; j++) {
          int level = Editor.getTextInputIntValue("#battler_types_${i}_attack_${j}_level", 1);
          String attackName = Editor.getSelectInputStringValue("#battler_types_${i}_attack_${j}_name");
          Attack attack = World.attacks[attackName];
          
          levelAttacks[level] = attack;
        }
        
        World.battlerTypes[name] = new BattlerType(
          Editor.getTextInputIntValue('#battler_types_sprite_id_${i}', 1),
          name,
          Editor.getTextInputIntValue('#battler_types_health_${i}', 1),
          Editor.getTextInputIntValue('#battler_types_physical_attack_${i}', 1),
          Editor.getTextInputIntValue('#battler_types_magical_attack_${i}', 1),
          Editor.getTextInputIntValue('#battler_types_physical_defense_${i}', 1),
          Editor.getTextInputIntValue('#battler_types_magical_defense_${i}', 1),
          Editor.getTextInputIntValue('#battler_types_speed_${i}', 1),
          levelAttacks,
          Editor.getTextInputDoubleValue('#battler_types_rarity_${i}', 1.0)
        );
      } catch(e, stackTrace) {
        // could not update this battler type
        print("Error updating battler type: " + e.toString());
        print(stackTrace);
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> battlerTypesJson = {};
    World.battlerTypes.forEach((String key, BattlerType battlerType) {
      Map<String, Object> battlerTypeJson = {};
      
      battlerTypeJson["spriteId"] = battlerType.spriteId.toString();
      battlerTypeJson["health"] = battlerType.baseHealth.toString();
      battlerTypeJson["physicalAttack"] = battlerType.basePhysicalAttack.toString();
      battlerTypeJson["magicalAttack"] = battlerType.baseMagicalAttack.toString();
      battlerTypeJson["physicalDefense"] = battlerType.basePhysicalDefense.toString();
      battlerTypeJson["magicalDefense"] = battlerType.baseMagicalDefense.toString();
      battlerTypeJson["speed"] = battlerType.baseSpeed.toString();
      
      Map<String, String> levelAttacks = {};
      battlerType.levelAttacks.forEach((int level, Attack attack) {
        levelAttacks[level.toString()] = attack.name;
      });
      battlerTypeJson["levelAttacks"] = levelAttacks;
      
      battlerTypeJson["rarity"] = battlerType.rarity.toString();
      
      battlerTypesJson[battlerType.name] = battlerTypeJson;
    });
    
    exportJson["battlerTypes"] = battlerTypesJson;
  }
}