library dart_rpg.object_editor_battler_types;

import 'dart:html';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'map_editor.dart';
import 'object_editor.dart';

class ObjectEditorBattlerTypes {
  // TODO: give battler types a display name and a unique name
  //   so people can name them stuff like "end_boss_1"
  //   but still have a pretty display name like "Bob"
  static List<String> advancedTabs = ["battler_type_stats", "battler_type_attacks"];
  static int selected;
  
  static CanvasElement canvas;
  static CanvasRenderingContext2D ctx;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_battler_type_button", addNewBattlerType);
    
    canvas = querySelector("#battler_type_picture_canvas");
    ctx = canvas.context2D;
    
    MapEditor.fixImageSmoothing(
      canvas,
      (Sprite.scaledSpriteSize * 3).round(),
      (Sprite.scaledSpriteSize * 3).round()
    );
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
  
  static void addLevel(MouseEvent e) {
    BattlerType selectedBattlerType = World.battlerTypes.values.elementAt(selected);
    int level = Editor.getTextInputIntValue("#battler_type_level", 1);
    if(selectedBattlerType.levelAttacks[level] != null) {
      return;
    }
    
    selectedBattlerType.levelAttacks[level] = [];
    
    Map<int, List<Attack>> levelAttacks = {};
    levelAttacks.addAll(selectedBattlerType.levelAttacks);
    
    List<int> sortedLevels = levelAttacks.keys.toList();
    sortedLevels.sort();
    
    selectedBattlerType.levelAttacks.clear();
    sortedLevels.forEach((int level) {
      selectedBattlerType.levelAttacks[level] = levelAttacks[level];
    });
    
    update();
    ObjectEditor.update();
  }
  
  static void addAttack(int battler, int level) {
    BattlerType battlerType = World.battlerTypes.values.elementAt(battler);
    List<Attack> attacks = battlerType.levelAttacks[level];
    
    for(int i=0; i<World.attacks.values.length; i++) {
      Attack attack = World.attacks.values.elementAt(i);
      if(!attacks.contains(attack)) {
        attacks.add(attack);
        
        update();
        ObjectEditor.update();
        return;
      }
    }
  }
  
  static void update() {
    buildMainHtml();
    buildStatsHtml();
    buildAttacksHtml();
    
    selectSprite();
    
    Editor.attachButtonListener("#add_battler_type_level_button", addLevel);
    
    Editor.setMapDeleteButtonListeners(World.battlerTypes, "battler_type");
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);
      
      // delete the level
      Editor.setMapDeleteButtonListeners(battlerType.levelAttacks, "battler_type_${i}_level");
      
      for(int j=0; j<battlerType.levelAttacks.keys.length; j++) {
        int level = battlerType.levelAttacks.keys.elementAt(j);
        List<Attack> attacks = battlerType.levelAttacks[level];
        
        Editor.setListDeleteButtonListeners(attacks, "battler_type_${i}_level_${level}_attack");
        
        for(int k=0; k<attacks.length; k++) {
          Editor.attachInputListeners("battler_type_${i}_level_${level}_attack_${k}", ["name"], onInputChange);
        }
        
        Editor.attachButtonListener("#add_battler_type_${i}_level_${level}_attack", (_) { addAttack(i, level); });
      }
    }
    
    List<String> attrs = [
      "sprite_id", "name",
      "health", "physical_attack", "magical_attack",
      "physical_defense", "magical_defense", "speed",
      "rarity"
    ];
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      Editor.attachInputListeners("battler_type_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#battler_type_row_${i}", (Event e) {
        if(querySelector("#battler_type_row_${i}") != null) {
          selectRow(i);
        }
      });
    }
  }
  
  static void selectSprite() {
    if(selected == null || selected == -1)
      return;
    
    String key = World.battlerTypes.keys.elementAt(selected);
    
    if(key == null)
      return;
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, Sprite.scaledSpriteSize * 3, Sprite.scaledSpriteSize * 3);
    
    for(int i=0; i<3; i++) {
      for(int j=0; j<3; j++) {
        MapEditor.renderStaticSprite(ctx, World.battlerTypes[key].spriteId + (i) + (j*Sprite.spriteSheetWidth), i, j);
      }
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.battlerTypes.keys.length; j++) {
      // un-highlight other battler type rows
      querySelector("#battler_type_row_${j}").classes.remove("selected");
      
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
    
    selectSprite();
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
        "  <td><input id='battler_type_${i}_sprite_id' type='text' class='number' value='${ World.battlerTypes[key].spriteId }' /></td>"+
        "  <td><input id='battler_type_${i}_name' type='text' value='${ World.battlerTypes[key].name }' /></td>"+
        "  <td><input id='battler_type_${i}_rarity' type='text' class='number decimal' value='${ World.battlerTypes[key].rarity }' /></td>"+
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
    
    html += "<input id='battler_type_level' type='text' class='number' />";
    html += "<button id='add_battler_type_level_button'>Add level</button><hr />";
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String visibleString = "class='hidden'";
      if(selected == i) {
        visibleString = "";
      }
      
      html += "<table id='battler_type_${i}_attacks_table' ${visibleString}>";
      html += "<tr><td>Level</td><td>Attacks</td><td></td></tr>";
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);
      
      int levelNum = 0;
      
      battlerType.levelAttacks.forEach((int level, List<Attack> attacks) {
        int j=0;
        
        html += "<tr><td id='battler_type_${i}_level_num_${levelNum}'>${level}</td><td>";
        
        attacks.forEach((Attack attack) {
          html += "<select id='battler_type_${i}_level_${level}_attack_${j}_name'>";
          World.attacks.keys.forEach((String name) {
            // skip attacks that already exist for this level
            if(attacks.contains(World.attacks[name]) && name != attack.name) {
              return;
            }
            
            html += "<option ";
            if(name == attack.name) {
              html += "selected";
            }
            html += ">${name}</option>";
          });
          html += "</select> ";
          html += "<button id='delete_battler_type_${i}_level_${level}_attack_${j}'>Delete</button><br />";
          
          j += 1;
        });
        
        html += "<button id='add_battler_type_${i}_level_${level}_attack'>Add level ${level} attack</button>";
        
        html += "</td><td><button id='delete_battler_type_${i}_level_${levelNum}'>Delete level</button></td></tr>";
        
        levelNum += 1;
      });
      
      html += "</table>";
    }
    
    querySelector("#battler_type_attacks_container").setInnerHtml(html);
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.battlerTypes);
    
    World.battlerTypes = new Map<String, BattlerType>();
    for(int i=0; querySelector('#battler_type_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue('#battler_type_${i}_name');
        
        Map<int, List<Attack>> levelAttacks = new Map<int, List<Attack>>();
        for(int j=0; querySelector("#battler_type_${i}_level_num_${j}") != null; j++) {
          int level = int.parse(querySelector("#battler_type_${i}_level_num_${j}").innerHtml);
          for(int k=0; querySelector("#battler_type_${i}_level_${level}_attack_${k}_name") != null; k++) {
            String attackName = Editor.getSelectInputStringValue("#battler_type_${i}_level_${level}_attack_${k}_name");
            Attack attack = World.attacks[attackName];
            
            if(levelAttacks[level] == null) {
              levelAttacks[level] = [];
            }
            
            levelAttacks[level].add(attack);
          }
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
      
      Map<String, List<String>> levelAttacks = {};
      battlerType.levelAttacks.forEach((int level, List<Attack> attacks) {
        List<String> attackNames = [];
        attacks.forEach((Attack attack) {
          attackNames.add(attack.name);
        });
        levelAttacks[level.toString()] = attackNames;
      });
      battlerTypeJson["levelAttacks"] = levelAttacks;
      
      battlerTypeJson["rarity"] = battlerType.rarity.toString();
      
      battlerTypesJson[battlerType.name] = battlerTypeJson;
    });
    
    exportJson["battlerTypes"] = battlerTypesJson;
  }
}