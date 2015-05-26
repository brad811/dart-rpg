library dart_rpg.object_editor_attacks;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/attack.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'object_editor.dart';

class ObjectEditorAttacks {
  static List<Attack> attacks = [];
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
    querySelector("#add_attack_button").onClick.listen((MouseEvent e) {
      // TODO: will have to use unique ids or something, like a database, so they can be deleted cleanly
      attacks.add( new Attack("Attack", Attack.CATEGORY_PHYSICAL, 0) );
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
    for(int i=0; i<attacks.length; i++) {
      // TODO: change these div ids to be more specific so they don't collide with anything in the map editor
      attacksHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='attacks_name_${i}' type='text' value='${ attacks[i].name }' /></td>"+
        // TODO: make category a dropdown
        "  <td><input id='attacks_category_${i}' type='text' value='${ attacks[i].category }' /></td>"+
        "  <td><input id='attacks_power_${i}' type='text' value='${ attacks[i].power }' /></td>"+
        "  <td><button id='delete_attack_${i}'>Delete</button></td>" +
        "</tr>";
    }
    attacksHtml += "</table>";
    querySelector("#attacks_container").innerHtml = attacksHtml;
    
    setAttackDeleteButtonListeners();
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<attacks.length; i++) {
        try {
          attacks[i] = new Attack(
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
      ObjectEditor.update();
      querySelector('#' + target.id).focus();
    };
    
    for(int i=0; i<attacks.length; i++) {
      List<String> attrs = ["name", "category", "power"];
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
    for(int i=0; i<attacks.length; i++) {
      if(listeners["#delete_attack_${i}"] != null)
        listeners["#delete_attack_${i}"].cancel();
      
      listeners["#delete_attack_${i}"] = querySelector("#delete_attack_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this attack?');
        if(confirm) {
          attacks.removeAt(i);
          Editor.update();
        }
      });
    }
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    // TODO: update export format to include object editor objects
  }
}