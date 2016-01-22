library dart_rpg.object_editor_attacks;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';

import 'package:react/react.dart';

// TODO: make sure all these update everywhere when renamed: battler type, game event, character

class ObjectEditorAttacks extends Component {
  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "Name"),
        td({}, "Category"),
        td({}, "Type"),
        td({}, "Power")
      )
    ];

    for(int i=0; i<World.attacks.keys.length; i++) {
      String key = World.attacks.keys.elementAt(i);

      List<JsObject> options = [];

      for(GameType gameType in World.types.values) {
        options.add(
          option({}, gameType.name)
        );
      }

      tableRows.add(
        tr({},
          td({},
            input({'id': 'attack_${i}_name', 'type': 'text', 'defaultValue': World.attacks[key].name, 'onChange': onInputChange})
          ),
          td({},
            select({'id': 'attack_${i}_category', 'defaultValue': World.attacks[key].category, 'onChange': onInputChange}, [
              option({'defaultValue': Attack.CATEGORY_PHYSICAL}, "Physical"),
              option({'defaultValue': Attack.CATEGORY_MAGICAL}, "Magical")
            ])
          ),
          td({},
            select({'id': 'attack_${i}_type', 'defaultValue': World.attacks[key].type, 'onChange': onInputChange}, options)
          ),
          td({},
            input({'id': 'attack_${i}_power', 'type': 'text', 'className': 'number', 'defaultValue': World.attacks[key].power, 'onChange': onInputChange})
          ),
          td({},
            button({
              'id': 'delete_attack_${i}',
              'onClick': (MouseEvent e) { Editor.confirmMapDelete(World.attacks, key, "attack", props['update']); },
              'onChange': onInputChange
            }, "Delete")
          )
        )
      );
    }

    return
      div({'id': 'object_editor_attacks_container', 'className': 'object_editor_tab_container'}, [

        table({'id': 'object_editor_attacks_advanced', 'className': 'object_editor_advanced_tab'}, [
          tr({},
            td({'className': 'tab_headers'},
              div({'id': 'type_effectiveness_tab_header', 'className': 'tab_header'}, "")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'className': 'tab'})
            )
          )
        ]),

        div({'id': 'object_editor_attacks_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'}, [
            button({'id': 'add_attack_button', 'onClick': addNewAttack}, "Add new attack"),
            hr({}),
            div({'id': 'attacks_container'}, [
              table({'className': 'editor_table'}, tbody({}, tableRows))
            ])
          ])
        )

      ]);
  }

  void addNewAttack(MouseEvent e) {
    World.attacks["New Attack"] = new Attack("New Attack", Attack.CATEGORY_PHYSICAL, World.types.keys.first, 0);
    props['update']();
    ObjectEditor.update();
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.attacks);
    
    Map<String, Attack> oldAttacks = new Map<String, Attack>();
    oldAttacks.addAll(World.attacks);
    
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
        
        // check if attack name was changed
        if(name != oldAttacks.keys.elementAt(i)) {
          // update battler type attack names
          for(BattlerType battlerType in World.battlerTypes.values) {
            for(int attackLevel in battlerType.levelAttacks.keys) {
              for(Attack attack in battlerType.levelAttacks[attackLevel]) {
                if(attack.name == oldAttacks.keys.elementAt(i)) {
                  World.battlerTypes[battlerType.name].levelAttacks[attackLevel].remove(attack);
                  World.battlerTypes[battlerType.name].levelAttacks[attackLevel].add(World.attacks[name]);
                }
              }
            }
          }
        }
      } catch(e) {
        // could not update this attack
        print("Error updating attack: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e, props['update']);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> attacksJson = {};
    World.attacks.forEach((String key, Attack attack) {
      Map<String, String> attackJson = {};
      attackJson["category"] = attack.category.toString();
      attackJson["type"] = attack.type;
      attackJson["power"] = attack.power.toString();
      attacksJson[attack.name] = attackJson;
    });
    
    exportJson["attacks"] = attacksJson;
  }
}
