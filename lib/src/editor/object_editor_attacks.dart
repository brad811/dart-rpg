library dart_rpg.object_editor_attacks;

import 'dart:html';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';

// TODO: handle renaming attacks by updating everywhere
// (otherwise they just disappear)

// TODO: make sure all these update: attack, battler type, game event, character

class ObjectEditorAttacks {
  static void setUp() {
    Editor.attachButtonListener("#add_attack_button", addNewAttack);
  }
  
  static void addNewAttack(MouseEvent e) {
    World.attacks["New Attack"] = new Attack("New Attack", Attack.CATEGORY_PHYSICAL, World.types.keys.first, 0);
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    String attacksHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>Name</td><td>Category</td><td>Type</td><td>Power</td>"+
      "  </tr>";
    for(int i=0; i<World.attacks.keys.length; i++) {
      String key = World.attacks.keys.elementAt(i);
      
      attacksHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='attack_${i}_name' type='text' value='${ World.attacks[key].name }' /></td>"+
        "  <td>";
      
      attacksHtml += "<select id='attack_${i}_category'>";
      String physical_selected = "", magical_selected = "";
      if(World.attacks[key].category == Attack.CATEGORY_PHYSICAL) {
        physical_selected = "selected";
      } else if(World.attacks[key].category == Attack.CATEGORY_MAGICAL) {
        magical_selected = "selected";
      }
      attacksHtml += "  <option value='${Attack.CATEGORY_PHYSICAL}' ${physical_selected}>Physical</option>";
      attacksHtml += "  <option value='${Attack.CATEGORY_MAGICAL}' ${magical_selected}>Magical</option>";
      attacksHtml += "</select>";
      
      attacksHtml += "</td>";
      attacksHtml += "<td>";
      
      attacksHtml += "<select id='attack_${i}_type'>";
      for(GameType gameType in World.types.values) {
        attacksHtml += "<option ";
        if(World.attacks[key].type == gameType.name) {
          attacksHtml += " selected";
        }
        attacksHtml += ">${ gameType.name }</option>";
      }
      attacksHtml += "</select>";
      
      attacksHtml +=
        "  </td>"+
        "  <td><input class='number' id='attack_${i}_power' type='text' value='${ World.attacks[key].power }' /></td>"+
        "  <td><button id='delete_attack_${i}'>Delete</button></td>"+
        "</tr>";
    }
    attacksHtml += "</table>";
    querySelector("#attacks_container").setInnerHtml(attacksHtml);
    
    Editor.setMapDeleteButtonListeners(World.attacks, "attack");
    
    List<String> attrs = ["name", "category", "type", "power"];
    for(int i=0; i<World.attacks.keys.length; i++) {
      Editor.attachInputListeners("attack_${i}", attrs, onInputChange);
    }
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.attacks);
    
    World.attacks = new Map<String, Attack>();
    for(int i=0; querySelector('#attack_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue('#attack_${i}_name');
        World.attacks[name] = new Attack(
          name,
          Editor.getSelectInputIntValue('#attack_${i}_category', 0),
          Editor.getSelectInputStringValue('#attack_${i}_type'),
          Editor.getTextInputIntValue('#attack_${i}_power', 1)
        );
      } catch(e) {
        // could not update this attack
        print("Error updating attack: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> attacksJson = {};
    World.attacks.forEach((String key, Attack attack) {
      Map<String, String> attackJson = {};
      attackJson["category"] = attack.category.toString();
      attackJson["power"] = attack.power.toString();
      attacksJson[attack.name] = attackJson;
    });
    
    exportJson["attacks"] = attacksJson;
  }
}