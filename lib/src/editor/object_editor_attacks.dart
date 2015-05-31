library dart_rpg.object_editor_attacks;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/attack.dart';

import 'editor.dart';
import 'object_editor.dart';

class ObjectEditorAttacks {
  static Map<String, Attack> attacks = {};
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_attack_button").onClick.listen((MouseEvent e) {
      // TODO: will have to use unique ids or something, like a database, so they can be deleted cleanly
      attacks["New Attack"] = new Attack("New Attack", Attack.CATEGORY_PHYSICAL, 0);
      update();
      ObjectEditor.update();
    });
    
    // TODO: read in attacks from saved json file
  }
  
  static void update() {
    String attacksHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>Name</td><td>Category</td><td>Power</td>"+
      "  </tr>";
    for(int i=0; i<attacks.keys.length; i++) {
      // TODO: change these div ids to be more specific so they don't collide with anything in the map editor
      String key = attacks.keys.elementAt(i);
      
      attacksHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='attacks_name_${i}' type='text' value='${ attacks[key].name }' /></td>"+
        // TODO: make category a dropdown
        "  <td>"+
        "    <select id='attacks_category_${i}'>"+
        "      <option>Physical</option>"+
        "      <option>Magical</option>"+
        "    </select>"+
        "  </td>"+
        
        "  <td><input id='attacks_category_${i}' type='text' value='${ attacks[key].category }' /></td>"+
        "  <td><input id='attacks_power_${i}' type='text' value='${ attacks[key].power }' /></td>"+
        "  <td><button id='delete_attack_${i}'>Delete</button></td>" +
        "</tr>";
    }
    attacksHtml += "</table>";
    querySelector("#attacks_container").innerHtml = attacksHtml;
    
    setAttackDeleteButtonListeners();
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<attacks.keys.length; i++) {
        try {
          attacks[attacks.keys.elementAt(i)] = new Attack(
            (querySelector('#attacks_name_${i}') as InputElement).value,
            int.parse((querySelector('#attacks_category_${i}') as InputElement).value),
            int.parse((querySelector('#attacks_power_${i}') as InputElement).value)
          );
        } catch(e) {
          // could not update this attack
        }
      }
      
      // TODO: make it so this doesn't de-focus the input
      InputElement target = e.target;
      // TODO: need to find a way to update here without losing input focus and position
      //   This is so other elements that reference this attack also get updated
      InputElement inputElement = querySelector('#' + target.id);
      int position = inputElement.selectionStart;
      Editor.update();
      inputElement = querySelector('#' + target.id);
      inputElement.focus();
      inputElement.setSelectionRange(position, position);
    };
    
    List<String> attrs = ["name", "category", "power"];
    for(int i=0; i<attacks.keys.length; i++) {
      for(String attr in attrs) {
        if(listeners["#attacks_${attr}_${i}"] != null)
          listeners["#attacks_${attr}_${i}"].cancel();
        
        listeners["#attacks_${attr}_${i}"] = 
            querySelector('#attacks_${attr}_${i}').onInput.listen(inputChangeFunction);
      }
    }
  }
  
  // TODO: generalize functions like this and put in main editor class
  static void setAttackDeleteButtonListeners() {
    for(int i=0; i<attacks.keys.length; i++) {
      if(listeners["#delete_attack_${i}"] != null)
        listeners["#delete_attack_${i}"].cancel();
      
      listeners["#delete_attack_${i}"] = querySelector("#delete_attack_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this attack?');
        if(confirm) {
          attacks.remove(attacks.keys.elementAt(i));
          Editor.update();
        }
      });
    }
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> attacksJson = {};
    attacks.forEach((String key, Attack attack) {
      Map<String, String> attackJson = {};
      attackJson["category"] = attack.category.toString();
      attackJson["power"] = attack.power.toString();
      attacksJson[attack.name] = attackJson;
    });
    
    exportJson["attacks"] = attacksJson;
  }
}