library dart_rpg.object_editor_battler_types;

import 'dart:async';
import 'dart:html';

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
    querySelector("#add_battler_type_button").onClick.listen((MouseEvent e) {
      // TODO: make rarity map-specific
      World.battlerTypes["New Battler Type"] = new BattlerType(
          0, "Battler",
          0, 0, 0, 0, 0, 0,
          {}, 1.0
        );
      update();
      ObjectEditor.update();
    });
  }
  
  static void update() {
    String battlerTypesHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Base Health</td>"+
      "    <td>Base Physical Attack</td>"+
      "    <td>Base Magical Attack</td>"+
      "    <td>Base Physical Defense</td>"+
      "    <td>Base Magical Defense</td>"+
      "    <td>Base Speed</td>"+
      "    <td>Level Attacks</td>"+
      "    <td>Rarity</td>"+
      "  </tr>";
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String key = World.battlerTypes.keys.elementAt(i);
      
      battlerTypesHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='battler_types_sprite_id_${i}' type='text' value='${ World.battlerTypes[key].spriteId }' /></td>"+
        "  <td><input id='battler_types_name_${i}' type='text' value='${ World.battlerTypes[key].name }' /></td>"+
        "  <td><input id='battler_types_base_health_${i}' type='text' value='${ World.battlerTypes[key].baseHealth }' /></td>"+
        "  <td><input id='battler_types_base_physical_attack_${i}' type='text' value='${ World.battlerTypes[key].basePhysicalAttack }' /></td>"+
        "  <td><input id='battler_types_base_magical_attack_${i}' type='text' value='${ World.battlerTypes[key].baseMagicalAttack }' /></td>"+
        "  <td><input id='battler_types_base_physical_defense_${i}' type='text' value='${ World.battlerTypes[key].basePhysicalDefense }' /></td>"+
        "  <td><input id='battler_types_base_magical_defense_${i}' type='text' value='${ World.battlerTypes[key].baseMagicalDefense }' /></td>"+
        "  <td><input id='battler_types_base_speed_${i}' type='text' value='${ World.battlerTypes[key].baseSpeed }' /></td>"+
        "  <td>Level Attacks</td>"+
        "  <td><input id='battler_types_rarity_${i}' type='text' value='${ World.battlerTypes[key].rarity }' /></td>"+
        "  <td><button id='delete_battler_type_${i}'>Delete</button></td>" +
        "</tr>";
    }
    battlerTypesHtml += "</table>";
    querySelector("#battler_types_container").innerHtml = battlerTypesHtml;
    
    Editor.setDeleteButtonListeners(World.battlerTypes, "battler_type", listeners);
    
    Function inputChangeFunction = (Event e) {
      if(e.target is InputElement) {
        InputElement target = e.target;
        
        if(target.id.contains("battler_types_name_") && World.battlerTypes.keys.contains(target.value)) {
          // avoid name collisions
          int i = 0;
          for(; World.battlerTypes.keys.contains(target.value + "_${i}"); i++) {}
          target.value += "_${i}";
        } else if(target.id.contains("battler_types_power_")) {
          // enforce number format
          target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
        }
      }
      
      World.battlerTypes = new Map<String, BattlerType>();
      for(int i=0; querySelector('#battler_types_name_${i}') != null; i++) {
        try {
          String name = (querySelector('#battler_types_name_${i}') as InputElement).value;
          World.battlerTypes[name] = new BattlerType(
            int.parse((querySelector('#battler_types_sprite_id_${i}') as InputElement).value),
            name,
            int.parse((querySelector('#battler_types_base_health_${i}') as InputElement).value),
            int.parse((querySelector('#battler_types_base_physical_attack_${i}') as InputElement).value),
            int.parse((querySelector('#battler_types_base_magical_attack_${i}') as InputElement).value),
            int.parse((querySelector('#battler_types_base_physical_defense_${i}') as InputElement).value),
            int.parse((querySelector('#battler_types_base_magical_defense_${i}') as InputElement).value),
            int.parse((querySelector('#battler_types_base_speed_${i}') as InputElement).value),
            {},
            double.parse((querySelector('#battler_types_rarity_${i}') as InputElement).value)
          );
        } catch(e) {
          // could not update this battler type
          print("Error updating battler type: " + e.toString());
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
      }
    };
    
    // TODO: perhaps move into base editor class
    List<String> attrs = [
      "sprite_id", "name",
      "base_health", "base_physical_attack", "base_magical_attack",
      "base_physical_defense", "base_magical_defense", "base_speed",
      /* level attacks? */ "rarity"
    ];
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      for(String attr in attrs) {
        if(listeners["#battler_types_${attr}_${i}"] != null)
          listeners["#battler_types_${attr}_${i}"].cancel();
        
        listeners["#battler_types_${attr}_${i}"] = 
            querySelector('#battler_types_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> battlerTypesJson = {};
    World.battlerTypes.forEach((String key, BattlerType battlerType) {
      Map<String, String> battlerTypeJson = {};
      
      battlerTypeJson["sprite_id"] = battlerType.spriteId.toString();
      battlerTypeJson["base_health"] = battlerType.baseHealth.toString();
      battlerTypeJson["base_physical_attack"] = battlerType.basePhysicalAttack.toString();
      battlerTypeJson["base_magical_attack"] = battlerType.baseMagicalAttack.toString();
      battlerTypeJson["base_physical_defense"] = battlerType.basePhysicalDefense.toString();
      battlerTypeJson["base_magical_defense"] = battlerType.baseMagicalDefense.toString();
      battlerTypeJson["base_speed"] = battlerType.baseSpeed.toString();
      battlerTypeJson["level_attacks"] = battlerType.levelAttacks.toString();
      battlerTypeJson["rarity"] = battlerType.rarity.toString();
      
      battlerTypesJson[battlerType.name] = battlerTypeJson;
    });
    
    exportJson["battlerTypes"] = battlerTypesJson;
  }
}