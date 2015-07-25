library dart_rpg.object_editor_battler_types;

import 'dart:html';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'object_editor.dart';

class ObjectEditorBattlerTypes {
  // TODO: give battler types a display name and a unique name
  //   so people can name them stuff like "end_boss_1"
  //   but still have a pretty display name like "Bob"
  static List<String> advancedTabs = ["battler_type_stats", "battler_type_attacks"];
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_battler_type_button", addNewBattlerType);
    Editor.attachButtonListener("#add_battler_type_attack_button", addAttack);
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
  
  static void addAttack(MouseEvent e) {
    BattlerType selectedBattlerType = World.battlerTypes.values.elementAt(selected);
    for(int i=0; i<100; i++) {
      if(selectedBattlerType.levelAttacks[i] == null) {
        selectedBattlerType.levelAttacks[i] = World.attacks.values.first;
        break;
      }
    }
    
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    buildMainHtml();
    buildStatsHtml();
    buildAttacksHtml();
    
    Editor.attachButtonListener("#add_battler_type_attack_button", (MouseEvent e) {
      BattlerType battlerType = World.battlerTypes.values.elementAt(selected);
      int nextLevel = 1;
      for(;  battlerType.levelAttacks[nextLevel] != null; nextLevel++);
      battlerType.levelAttacks[nextLevel] = World.attacks.values.first;
      Editor.update();
    });
    
    Editor.setMapDeleteButtonListeners(World.battlerTypes, "battler_type");
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);
      Editor.setMapDeleteButtonListeners(battlerType.levelAttacks, "battler_type_${i}_attack");
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
      Editor.attachInputListeners("battler_type_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#battler_type_row_${i}", (Event e) {
        if(querySelector("#battler_type_row_${i}") != null) {
          selectRow(i);
        }
      });
      
      for(int j=0; j<World.battlerTypes.values.elementAt(i).levelAttacks.values.length; j++) {
        Editor.attachInputListeners("battler_type_${i}_attack_${j}", attackAttrs, onInputChange);
      }
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.battlerTypes.keys.length; j++) {
      // un-highlight other battler type rows
      querySelector("#battler_type_row_${j}").classes.remove("selected");
      
      // TODO: make sure this is right
      // hide the advanced areas for other battler types
      querySelector("#battler_type_${j}_stats_table").classes.add("hidden");
      querySelector("#battler_type_${j}_attacks_table").classes.add("hidden");
    }
    
    // hightlight the selected battler type row
    querySelector("#battler_type_row_${i}").classes.add("selected");
    
    // show the battler types advanced area
    querySelector("#battler_types_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected battler type
    querySelector("#battler_type_${i}_stats_table").classes.remove("hidden");
    querySelector("#battler_type_${i}_attacks_table").classes.remove("hidden");
  }
  
  static void buildMainHtml() {
    String battlerTypesHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td>"+
      "    <td>Sprite Id</td>"+
      "    <td>Name</td>"+
      "    <td>Rarity</td>"+
      "  </tr>";
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String key = World.battlerTypes.keys.elementAt(i);
      
      battlerTypesHtml +=
        "<tr id='battler_type_row_${i}'>"+
        "  <td>${i}</td>"+
        "  <td><input class='number' id='battler_type_${i}_sprite_id' type='text' value='${ World.battlerTypes[key].spriteId }' /></td>"+
        "  <td><input id='battler_type_${i}_name' type='text' value='${ World.battlerTypes[key].name }' /></td>"+
        "  <td><input class='number' id='battler_type_${i}_rarity' type='text' value='${ World.battlerTypes[key].rarity }' /></td>"+
        "  <td><button id='delete_battler_type_${i}'>Delete battler</button></td>" +
        "</tr>";
    }
    battlerTypesHtml += "</table>";
    querySelector("#battler_types_container").setInnerHtml(battlerTypesHtml);
  }
  
  static void buildStatsHtml() {
    String html = "";
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      html += "<table id='battler_type_${i}_stats_table' ${visibleString}>";
      html += "<tr><td>Stat</td><td>Value</td></tr>";
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);
      
      html += "<tr>";
      html += "<td>Health</td>";
      html += "<td><input id='battler_type_${i}_health' type='text' class='number' value='${battlerType.baseHealth}' /></td>";
      html += "</tr>";
      
      html += "<tr>";
      html += "<td>Physical Attack</td>";
      html += "<td><input id='battler_type_${i}_physical_attack' type='text' class='number' value='${battlerType.basePhysicalAttack}' /></td>";
      html += "</tr>";
      
      html += "<tr>";
      html += "<td>Physical Defense</td>";
      html += "<td><input id='battler_type_${i}_physical_defense' type='text' class='number' value='${battlerType.basePhysicalDefense}' /></td>";
      html += "</tr>";
      
      html += "<tr>";
      html += "<td>Magical Attack</td>";
      html += "<td><input id='battler_type_${i}_magical_attack' type='text' class='number' value='${battlerType.baseMagicalAttack}' /></td>";
      html += "</tr>";
      
      html += "<tr>";
      html += "<td>Magical Defense</td>";
      html += "<td><input id='battler_type_${i}_magical_defense' type='text' class='number' value='${battlerType.baseMagicalDefense}' /></td>";
      html += "</tr>";
      
      html += "<tr>";
      html += "<td>Speed</td>";
      html += "<td><input id='battler_type_${i}_speed' type='text' class='number' value='${battlerType.baseSpeed}' /></td>";
      html += "</tr>";
      
      html += "</table>";
    }
    
    querySelector("#battler_type_stats_container").setInnerHtml(html);
  }
  
  static void buildAttacksHtml() {
    String html = "";
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      html += "<table id='battler_type_${i}_attacks_table' ${visibleString}>";
      html += "<tr><td>Level</td><td>Attack</td><td></td></tr>";
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);
      
      int j=0;
      battlerType.levelAttacks.forEach((int level, Attack attack) {
        html += "<tr><td>";
        html += "<input class='number' id='battler_type_${i}_attack_${j}_level' type='text' value='${level}' />";
        html += "</td><td>";
        html += "<select id='battler_type_${i}_attack_${j}_name'>";
        World.attacks.keys.forEach((String name) {
          html += "<option ";
          if(name == attack.name) {
            html += "selected";
          }
          html += ">${name}</option>";
        });
        html += "</select>";
        html += "</td><td>";
        html += "<button id='delete_battler_type_${i}_attack_${j}'>Delete</button><br />";
        html += "</td></tr>";
        
        j += 1;
      });
      
      html += "</table>";
    }
    
    querySelector("#battler_type_attacks_container").setInnerHtml(html);
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