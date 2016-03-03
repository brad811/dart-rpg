library dart_rpg.object_editor_battler_types;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class ObjectEditorBattlerTypes extends Component {
  // TODO: give battler types a display name and a unique name
  //   so people can name them stuff like "end_boss_1"
  //   but still have a pretty display name like "Bob"
  bool shouldScrollIntoView = false;

  getInitialState() => {
    'selected': -1,
    'selectedAdvancedTab': 'stats'
  };

  componentDidMount(Element rootNode) {
    initSpritePickers();
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    initSpritePickers();
    if(state['selected'] > World.battlerTypes.length - 1) {
      setState({
        'selected': World.battlerTypes.length - 1
      });
    }

    if(shouldScrollIntoView) {
      shouldScrollIntoView = false;
      querySelector('#battler_type_row_${state['selected']}').scrollIntoView();
    }
  }

  void initSpritePickers() {
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      Editor.initSpritePicker("battler_type_${i}_sprite_id", World.battlerTypes.values.elementAt(i).spriteId, 3, 3, onInputChange);
    }
  }

  void update() {
    this.setState({});
  }

  void removeDeleted() {
    // remove references to deleted battler types from characters, replace with first battler type
    for(Character character in World.characters.values) {
      if(!World.battlerTypes.containsKey(character.battler.battlerType.name)) {
        BattlerType battlerType = World.battlerTypes.values.first;
        character.battler = new Battler(
          battlerType.name, battlerType, character.battler.level, battlerType.getAttacksForLevel(character.battler.level)
        );
      }
    }

    // remove battler chances from maps if the battler type no longer exists
    for(GameMap map in Main.world.maps.values) {
      map.battlerChances.removeWhere((battlerChance) => !World.battlerTypes.containsKey(battlerChance.battler.battlerType.name));
    }

    update();
  }

  JsObject getStatsTab() {
    List<JsObject> tables = [];
    
    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      BattlerType battlerType = World.battlerTypes.values.elementAt(i);

      tables.add(
        table({'id': 'battler_type_${i}_stats_table', 'className': state['selected'] == i ? '' : 'hidden'}, tbody({},
          tr({},
            td({}, "Stat"),
            td({}, "Value")
          ),
          tr({},
            td({}, "Health"),
            td({},
              input({
                'id': 'battler_type_${i}_health',
                'type': 'text',
                'className': 'number',
                'value': battlerType.baseHealth,
                'onChange': onInputChange
              })
            )
          ),

          tr({},
            td({}, "Physical Attack"),
            td({},
              input({
                'id': 'battler_type_${i}_physical_attack',
                'type': 'text',
                'className': 'number',
                'value': battlerType.basePhysicalAttack,
                'onChange': onInputChange
              })
            )
          ),
          tr({},
            td({}, "Physical Defense"),
            td({},
              input({
                'id': 'battler_type_${i}_physical_defense',
                'type': 'text',
                'className': 'number',
                'value': battlerType.basePhysicalDefense,
                'onChange': onInputChange
              })
            )
          ),
          tr({},
            td({}, "Magical Attack"),
            td({},
              input({
                'id': 'battler_type_${i}_magical_attack',
                'type': 'text',
                'className': 'number',
                'value': battlerType.baseMagicalAttack,
                'onChange': onInputChange
              })
            )
          ),
          tr({},
            td({}, "Magicl Defense"),
            td({},
              input({
                'id': 'battler_type_${i}_magical_defense',
                'type': 'text',
                'className': 'number',
                'value': battlerType.baseMagicalDefense,
                'onChange': onInputChange
              })
            )
          ),
          tr({},
            td({}, "Speed"),
            td({},
              input({
                'id': 'battler_type_${i}_speed',
                'type': 'text',
                'className': 'number',
                'value': battlerType.baseSpeed,
                'onChange': onInputChange
              })
            )
          )
        ))
      );
    }
    
    return div({'className': state['selectedAdvancedTab'] == 'stats' ? '' : 'hidden'}, tables);
  }

  JsObject getAttacksTab() {
    if(state['selected'] == -1 || World.battlerTypes.values.length == 0) {
      return div({});
    }

    BattlerType battlerType = World.battlerTypes.values.elementAt(state['selected']);

    List<JsObject> elements = [];

    elements.addAll([
      input({'id': 'battler_type_level', 'type': 'text', 'className': 'number'}),
      button({'id': 'add_battler_type_level_button', 'onClick': addLevel}, span({'className': 'fa fa-plus-circle'}), " Add level"),
      hr({})
    ]);
    
    List<JsObject> tableRows = [];

    tableRows.add(
      tr({},
        td({}, "Level"),
        td({}, "Attacks"),
        td({})
      )
    );

    int levelNum = 0;

    battlerType.levelAttacks.forEach((int level, List<Attack> attacks) {
      int j=0;

      List<JsObject> attackRows = [];

      attacks.forEach((Attack attack) {
        List<JsObject> options = [];

        World.attacks.keys.forEach((String name) {
          // skip attacks that already exist for this level
          if(attacks.contains(World.attacks[name]) && name != attack.name) {
            return;
          }

          options.add(option({}, name));
        });

        attackRows.addAll([
          select({
            'id': 'battler_type_${state['selected']}_level_${level}_attack_${j}_name',
            'value': attack.name,
            'onChange': onInputChange
          }, options),
          button({
            'id': 'delete_battler_type_${state['selected']}_level_${level}_attack_${j}',
            'onClick': Editor.generateConfirmDeleteFunction(
              World.battlerTypes.values.elementAt(state['selected']).levelAttacks[level],
              j, "level attack", update
            )
          }, span({'className': 'fa fa-trash'}), " Delete"),
          br({})
        ]);

        j += 1;
      });

      attackRows.add(
        button({
          'id': 'add_battler_type_${state['selected']}_level_${level}_attack',
          'onClick': (MouseEvent e) { addAttack(state['selected'], level); }
        }, span({'className': 'fa fa-plus-circle'}), " Add level ${level} attack")
      );

      tableRows.add(
        tr({},
          td({'id': 'battler_type_${state['selected']}_level_num_${levelNum}'}, level),
          td({}, attackRows),
          td({},
            button({
              'id': 'delete_battler_type_${state['selected']}_level_${levelNum}',
              'onClick': Editor.generateConfirmDeleteFunction(
                World.battlerTypes.values.elementAt(state['selected']).levelAttacks,
                level, "level", update
              )
            }, span({'className': 'fa fa-trash'}), " Delete level")
          )
        )
      );

      levelNum += 1;
    });

    elements.add(
      table({'id': 'battler_type_${state['selected']}_attacks_table'}, tbody({},
        tableRows
      ))
    );

    return div({'className': state['selectedAdvancedTab'] == 'attacks' ? '' : 'hidden'}, elements);
  }

  render() {
    List<JsObject> tableRows = [];

    tableRows.add(
      tr({},
        td({}, "Num"),
        td({}, "Sprite Id"),
        td({}, "Name"),
        td({}, "Type"),
        td({}, "Rarity")
      )
    );

    for(int i=0; i<World.battlerTypes.keys.length; i++) {
      String key = World.battlerTypes.keys.elementAt(i);

      List<JsObject> options = [];

      for(GameType gameType in World.types.values) {
        options.add(
          option({}, gameType.name)
        );
      }

      tableRows.add(
        tr({
          'id': 'battler_type_row_${i}',
          'className': state['selected'] == i ? 'selected' : '',
          'onClick': (MouseEvent e) { setState({'selected': i}); },
          'onFocus': (MouseEvent e) { setState({'selected': i}); }
        },
          td({}, i),
          td({}, Editor.generateSpritePickerHtml("battler_type_${i}_sprite_id", World.battlerTypes[key].spriteId)),
          td({},
            input({
              'id': 'battler_type_${i}_name',
              'type': 'text',
              'value': World.battlerTypes[key].name,
              'onChange': onInputChange
            })
          ),
          td({},
            select({'id': 'battler_type_${i}_type', 'value': World.battlerTypes[key].type, 'onChange': onInputChange}, options)
          ),
          td({},
            input({
              'id': 'battler_type_${i}_rarity',
              'type': 'text',
              'className': 'number decimal',
              'value': World.battlerTypes[key].rarity.toString(),
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_battler_type_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(
                World.battlerTypes, key, "battler type", removeDeleted, atLeastOneRequired: true
              ),
            }, span({'className': 'fa fa-trash'}), " Delete battler")
          )
        )
      );
    }

    return
      div({'id': 'object_editor_battler_types_container', 'className': 'object_editor_tab_container'},

        table({
          'id': 'object_editor_battler_types_advanced',
          'className': 'object_editor_advanced_tab'}, tbody({},
          tr({},
            td({'className': 'tab_headers'},
              div({
                'id': 'battler_type_stats_tab_header',
                'className': 'tab_header ' + (state['selectedAdvancedTab'] == 'stats' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedAdvancedTab': 'stats'}); }
              }, "Stats"),
              div({
                'id': 'battler_type_attacks_tab_header',
                'className': 'tab_header ' + (state['selectedAdvancedTab'] == 'attacks' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedAdvancedTab': 'attacks'}); }
              }, "Attacks")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'className': 'tab'},
                div({'id': 'battler_type_stats_container'}, getStatsTab()),
                div({'id': 'battler_type_attacks_container'}, getAttacksTab())
              )
            )
          )
        )),

        div({'id': 'object_editor_battler_types_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'}, [
            button({'id': 'add_battler_type_button', 'onClick': addNewBattlerType}, span({'className': 'fa fa-plus-circle'}), " Add new battler type"),
            hr({}),
            div({'id': 'battler_types_container'}, [
              table({'className': 'editor_table'}, tbody({}, tableRows))
            ])
          ])
        )

      );
  }

  void addNewBattlerType(MouseEvent e) {
    String name = Editor.getUniqueName("New Battler Type", World.battlerTypes);
    World.battlerTypes[name] = new BattlerType(
        0, name, World.types.keys.first,
        0, 0, 0, 0, 0, 0,
        {}, 1.0
      );

    shouldScrollIntoView = true;
    this.setState({
      'selected': World.battlerTypes.keys.length - 1
    });
  }

  void addLevel(MouseEvent e) {
    BattlerType selectedBattlerType = World.battlerTypes.values.elementAt(state['selected']);
    int level = Editor.getTextInputIntValue("#battler_type_level", 1);
    if(selectedBattlerType.levelAttacks[level] != null) {
      return;
    }

    // clear input field
    (querySelector("#battler_type_level") as TextInputElement).value = "";
    
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
  }
  
  void addAttack(int battler, int level) {
    BattlerType battlerType = World.battlerTypes.values.elementAt(battler);
    List<Attack> attacks = battlerType.levelAttacks[level];
    
    for(int i=0; i<World.attacks.values.length; i++) {
      Attack attack = World.attacks.values.elementAt(i);
      if(!attacks.contains(attack)) {
        attacks.add(attack);
        
        update();
        return;
      }
    }
  }

  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.battlerTypes);

    try {
      String oldName = World.battlerTypes.keys.elementAt(state['selected']);
      String name = Editor.getTextInputStringValue('#battler_type_${state['selected']}_name');

      Map<String, BattlerType> newBattlerTypes = {};

      World.battlerTypes.forEach((String key, BattlerType battlerType) {
        if(key != oldName) {
          newBattlerTypes[key] = battlerType;
        } else {
          Map<int, List<Attack>> levelAttacks = new Map<int, List<Attack>>();
          for(int j=0; querySelector("#battler_type_${state['selected']}_level_num_${j}") != null; j++) {
            int level = int.parse(querySelector("#battler_type_${state['selected']}_level_num_${j}").innerHtml);
            for(int k=0; querySelector("#battler_type_${state['selected']}_level_${level}_attack_${k}_name") != null; k++) {
              String attackName = Editor.getSelectInputStringValue("#battler_type_${state['selected']}_level_${level}_attack_${k}_name");
              Attack attack = World.attacks[attackName];
              
              if(levelAttacks[level] == null) {
                levelAttacks[level] = [];
              }
              
              levelAttacks[level].add(attack);
            }
          }
          
          newBattlerTypes[name] = new BattlerType(
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_sprite_id', 1),
            name,
            Editor.getSelectInputStringValue("#battler_type_${state['selected']}_type"),
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_health', 1),
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_physical_attack', 1),
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_magical_attack', 1),
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_physical_defense', 1),
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_magical_defense', 1),
            Editor.getTextInputIntValue('#battler_type_${state['selected']}_speed', 1),
            levelAttacks,
            Editor.getTextInputDoubleValue('#battler_type_${state['selected']}_rarity', 1.0)
          );
        }
      });

      World.battlerTypes = newBattlerTypes;
    } catch(e, stackTrace) {
      // could not update this battler type
      print("Error updating battler type: " + e.toString());
      print(stackTrace);
    }

    update();

    Editor.debounceExport();
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
      
      battlerTypeJson["type"] = battlerType.type;
      
      battlerTypeJson["rarity"] = battlerType.rarity.toString();
      
      battlerTypesJson[battlerType.name] = battlerTypeJson;
    });
    
    exportJson["battlerTypes"] = battlerTypesJson;
  }
}
