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
      "    <td>Base Stats</td>"+
      "    <td>Level Attacks</td>"+
      "    <td>Rarity</td>"+
      "  </tr>";
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String key = World.battlerTypes.keys.elementAt(i);
      
      battlerTypesHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input class='number' id='battler_type_${i}_sprite_id' type='text' value='${ World.battlerTypes[key].spriteId }' /></td>"+
        "  <td><input id='battler_type_${i}_name' type='text' value='${ World.battlerTypes[key].name }' /></td>"+
        
        "  <td>"+
        "    <table>"+
        "      <tr>"+
        "        <td>Health: </td><td><input class='number' id='battler_type_${i}_health' type='text' value='${ World.battlerTypes[key].baseHealth }' /></td>"+
        "      </tr><tr>"+
        "        <td>Speed: </td><td><input class='number' id='battler_type_${i}_speed' type='text' value='${ World.battlerTypes[key].baseSpeed }' /></td>"+
        "      </tr><tr>"+
        "        <td>Phys Atk: </td><td><input class='number' id='battler_type_${i}_physical_attack' type='text' value='${ World.battlerTypes[key].basePhysicalAttack }' /></td>"+
        "      </tr><tr>"+
        "        <td>Magic Atk: </td><td><input class='number' id='battler_type_${i}_magical_attack' type='text' value='${ World.battlerTypes[key].baseMagicalAttack }' /></td>"+
        "      </tr><tr>"+
        "        <td>Phys Def: </td><td><input class='number' id='battler_type_${i}_physical_defense' type='text' value='${ World.battlerTypes[key].basePhysicalDefense }' /></td>"+
        "      </tr><tr>"+
        "        <td>Magic Def: </td><td><input class='number' id='battler_type_${i}_magical_defense' type='text' value='${ World.battlerTypes[key].baseMagicalDefense }' /></td>"+
        "      </tr>"+
        "    </table>"+
        "  </td>"+
        
        "  <td>";
      
      int j = 0;
      World.battlerTypes[key].levelAttacks.forEach((int level, Attack levelAttack) {
        battlerTypesHtml += "<input class='number' id='battler_type_${i}_attack_${j}_level' type='text' value='${level}' />";
        battlerTypesHtml += "<select id='battler_type_${i}_attack_${j}_name'>";
        World.attacks.forEach((String name, Attack attack) {
          battlerTypesHtml += "<option ";
          if(name == levelAttack.name) {
            battlerTypesHtml += "selected";
          }
          battlerTypesHtml += ">${attack.name}</option>";
        });
        battlerTypesHtml += "</select>";
        battlerTypesHtml += "<button id='delete_battler_type_${i}_attack_${j}'>Delete</button><br />";
        
        j++;
      });
      
      battlerTypesHtml += "<button id='add_battler_type_${i}_attack'>Add attack</button>";
        
      battlerTypesHtml +=
        "  </td>"+
        "  <td><input class='number' id='battler_type_${i}_rarity' type='text' value='${ World.battlerTypes[key].rarity }' /></td>"+
        "  <td><button id='delete_battler_type_${i}'>Delete battler</button></td>" +
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
    
    List<String> attrs = [
      "sprite_id", "name",
      "health", "physical_attack", "magical_attack",
      "physical_defense", "magical_defense", "speed",
      "rarity"
    ];
    
    List<String> attackAttrs = [
      "level", "name"
    ];
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      Editor.attachListeners(listeners, "battler_type_${i}", attrs, onInputChange);
      
      for(int j=0; j<World.battlerTypes.values.elementAt(i).levelAttacks.values.length; j++) {
        Editor.attachListeners(listeners, "battler_type_${i}_attack_${j}", attackAttrs, onInputChange);
      }
    }
  }
  
  static void onInputChange(Event e) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains("_name") && World.battlerTypes.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; World.battlerTypes.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      } else if(target.id.contains("_magical_") || target.id.contains("_physical_")
          || target.id.contains("_health") || target.id.contains("_sprite")
          || target.id.contains("_speed") || target.id.contains("_level")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      } else if(target.id.contains("_rarity")) {
        target.value = target.value.replaceAll(new RegExp(r'[^0-9\.]'), "");
      }
    }
    
    World.battlerTypes = new Map<String, BattlerType>();
    for(int i=0; querySelector('#battler_type_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue('#battler_type_${i}_name');
        
        Map<int, Attack> levelAttacks = new Map<int, Attack>();
        for(int j=0; querySelector("#battler_type_${i}_attack_${j}_level") != null; j++) {
          int level = Editor.getTextInputIntValue("#battler_type_${i}_attack_${j}_level", 1);
          String attackName = Editor.getSelectInputStringValue("#battler_type_${i}_attack_${j}_name");
          Attack attack = World.attacks[attackName];
          
          levelAttacks[level] = attack;
        }
        
        World.battlerTypes[name] = new BattlerType(
          Editor.getTextInputIntValue('#battler_type_${i}_sprite_id', 1),
          name,
          Editor.getTextInputIntValue('#battler_type_${i}_health', 1),
          Editor.getTextInputIntValue('#battler_type_${i}_physical_attack', 1),
          Editor.getTextInputIntValue('#battler_type_${i}_magical_attack', 1),
          Editor.getTextInputIntValue('#battler_type_${i}_physical_defense', 1),
          Editor.getTextInputIntValue('#battler_type_${i}_magical_defense', 1),
          Editor.getTextInputIntValue('#battler_type_${i}_speed', 1),
          levelAttacks,
          Editor.getTextInputDoubleValue('#battler_type_${i}_rarity', 1.0)
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