library dart_rpg.object_editor_attacks;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

// TODO: make sure all these update everywhere when renamed: battler type, game event, character

class ObjectEditorAttacks extends Component {
  bool shouldScrollIntoView = false;

  getInitialState() => {
    'selected': -1
  };

  void update() {
    this.setState({});
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    if(state['selected'] > World.attacks.keys.length - 1) {
      setState({
        'selected': World.attacks.keys.length - 1
      });
    }

    if(shouldScrollIntoView) {
      shouldScrollIntoView = false;
      querySelector('#attack_row_${state['selected']}').scrollIntoView();
    }
  }

  void removeDeleted() {
    // remove references to deleted attacks
    for(BattlerType battlerType in World.battlerTypes.values) {
      List<int> levels = battlerType.levelAttacks.keys;
      for(int level in levels) {
        List<Attack> attacks = battlerType.levelAttacks[level].toList();
        for(Attack attack in attacks) {
          if(!World.attacks.values.contains(attack)) {
            battlerType.levelAttacks[level].remove(attack);
          }
        }
      }
    }

    update();
  }

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
        tr({
          'id': 'attack_row_${i}',
          'className': state['selected'] == i ? 'selected' : '',
          'onClick': (MouseEvent e) { setState({'selected': i}); }
        },
          td({}, i),
          td({},
            input({
              'id': 'attack_${i}_name',
              'type': 'text',
              'value': World.attacks[key].name,
              'onChange': onInputChange
            })
          ),
          td({},
            select({'id': 'attack_${i}_category', 'value': World.attacks[key].category, 'onChange': onInputChange}, [
              option({'value': Attack.CATEGORY_PHYSICAL}, "Physical"),
              option({'value': Attack.CATEGORY_MAGICAL}, "Magical")
            ])
          ),
          td({},
            select({
              'id': 'attack_${i}_type',
              'value': World.attacks[key].type,
              'onChange': onInputChange}, options
            )
          ),
          td({},
            input({
              'id': 'attack_${i}_power',
              'type': 'text',
              'className': 'number',
              'value': World.attacks[key].power,
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_attack_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(World.attacks, key, "attack", removeDeleted, atLeastOneRequired: true)
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'object_editor_attacks_container', 'className': 'object_editor_tab_container'},

        table({'id': 'object_editor_attacks_advanced', 'className': 'object_editor_advanced_tab'},
          tr({},
            td({'className': 'tab_headers'},
              div({'className': 'tab_header'}, "")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'className': 'tab'})
            )
          )
        ),

        div({'id': 'object_editor_attacks_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'},
            button({'id': 'add_attack_button', 'onClick': addNewAttack}, span({'className': 'fa fa-plus-circle'}), " Add new attack"),
            hr({}),
            div({'id': 'attacks_container'},
              table({'className': 'editor_table'}, tbody({}, tableRows))
            )
          )
        )

      );
  }

  void addNewAttack(MouseEvent e) {
    String name = Editor.getUniqueName("New Attack", World.attacks);
    World.attacks[name] = new Attack(name, Attack.CATEGORY_PHYSICAL, World.types.keys.first, 0);
    
    shouldScrollIntoView = true;
    this.setState({
      'selected': World.attacks.keys.length - 1
    });
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
    
    update();

    Editor.debounceExport();
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
