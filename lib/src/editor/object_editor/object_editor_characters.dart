library dart_rpg.object_editor_characters;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_game_events.dart';

import 'package:react/react.dart';

// TODO: dimensions, where character is solid and interactable

class ObjectEditorCharacters extends Component {
  List<Function> callbacks = [];
  bool shouldScrollIntoView = false;

  @override
  getInitialState() => {
    'selected': -1,
    'selectedAdvancedTab': 'inventory'
  };

  @override
  componentDidMount() {
    initSpritePickers();

    if(Editor.selectedSubTab == "characters" && Editor.selectedSubItemNumber != -1) {
      setState({'selected': Editor.selectedSubItemNumber});
      querySelector('#character_row_${Editor.selectedSubItemNumber}').scrollIntoView();
    }
  }

  @override
  componentWillUpdate(Map newProps, Map newState) {
    if(state['selected'] > World.characters.length - 1) {
      setState({
        'selected': World.characters.length - 1
      });
    }

    // handle player character being deleted
    if(!World.characters.values.contains(Main.player.getCurCharacter())) {
      Main.player.characters = [World.characters[World.characters.keys.first]].toSet();
    }
  }

  @override
  componentDidUpdate(Map prevProps, Map prevState) {
    initSpritePickers();
    callCallbacks();

    if(shouldScrollIntoView) {
      shouldScrollIntoView = false;
      querySelector('#character_row_${state['selected']}').scrollIntoView();
    }
  }

  void callCallbacks() {
    if(callbacks != null) {
      for(Function callback in callbacks) {
        callback();
      }
    }
  }

  void initSpritePickers() {
    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);

      Editor.initSpritePicker(
        "character_${i}_sprite_id",
        character.spriteId,
        character.sizeX, character.sizeY,
        onInputChange
      );

      Editor.initSpritePicker(
        "character_${i}_picture_id",
        character.pictureId,
        3, 3,
        onInputChange
      );
    }
  }

  void update() {
    setState({});
  }

  void removeDeleted() {
    // remove references to deleted characters
    World.gameEventChains.forEach((String label, List<GameEvent> gameEvents) {
      gameEvents.forEach((GameEvent gameEvent) {
        if(gameEvent is HealGameEvent && !World.characters.containsValue(gameEvent.character)) {
          gameEvent.character = World.characters.values.first;
        } else if(gameEvent is WarpGameEvent) {
          gameEvent.characterLabel = World.characters.keys.first;
        }
      });
    });
    
    update();
  }

  @override
  render() {
    List<JsObject> tableRows = [];

    tableRows.add(
      tr({},
        td({}, "Num"),
        td({}),
        td({}, "Sprite Id"),
        td({}, "Picture Id"),
        td({}, "Size"),
        td({}, "Map"),
        td({})
      )
    );

    for(int i=0; i<World.characters.keys.length; i++) {
      String key = World.characters.keys.elementAt(i);

      List<JsObject> options = [];

      Main.world.maps.keys.forEach((String mapName) {
        options.add(
          option({'value': mapName}, mapName)
        );
      });

      tableRows.add(
        tr({
          'id': 'character_row_${i}',
          'className': state['selected'] == i ? 'selected' : '',
          'onClick': (MouseEvent e) { setState({'selected': i}); },
          'onFocus': (MouseEvent e) { setState({'selected': i}); }
        },
          td({}, i),
          td({},
            "Label", br({}),
            Editor.generateInput({
              'id': 'character_${i}_label',
              'type': 'text',
              'value': key,
              'onChange': onInputChange
            }), br({}),
            "Name", br({}),
            Editor.generateInput({
              'id': 'character_${i}_name',
              'type': 'text',
              'value': World.characters[key].name,
              'onChange': onInputChange
            }), br({}),
            br({}),
            input({
              'id': 'character_${i}_player',
              'type': 'checkbox',
              'checked': Main.player.getCurCharacter().label == World.characters.keys.elementAt(i),
              'onChange': onInputChange
            }),
            "Player"
          ),
          td({},
            Editor.generateSpritePickerHtml("character_${i}_sprite_id", World.characters[key].spriteId)
          ),
          td({},
            Editor.generateSpritePickerHtml("character_${i}_picture_id", World.characters[key].pictureId)
          ),
          td({},
            "X: ",
            Editor.generateInput({
              'id': 'character_${i}_size_x',
              'type': 'text',
              'className': 'number',
              'value': World.characters[key].sizeX,
              'onChange': onInputChange
            }),
            br({}),
            "Y: ",
            Editor.generateInput({
              'id': 'character_${i}_size_y',
              'type': 'text',
              'className': 'number',
              'value': World.characters[key].sizeY,
              'onChange': onInputChange
            }),

            br({}),
            br({}),
            "Speed",
            br({}),
            "Walk: ",
            Editor.generateInput({
              'id': 'character_${i}_walk_speed',
              'type': 'text',
              'className': 'number',
              'value': World.characters[key].walkSpeed,
              'onChange': onInputChange
            }),
            br({}),
            "Run: ",
            Editor.generateInput({
              'id': 'character_${i}_run_speed',
              'type': 'text',
              'className': 'number',
              'value': World.characters[key].runSpeed,
              'onChange': onInputChange
            })
          ),
          td({},
            select({'id': 'character_${i}_map', 'value': World.characters[key].map, 'onChange': onInputChange}, options)
          ),
          td({},
            button({
              'id': 'delete_character_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(World.characters, key, "character", removeDeleted, atLeastOneRequired: true)
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'object_editor_characters_container', 'className': 'object_editor_tab_container'},

        table({
          'id': 'object_editor_characters_advanced',
          'className': 'object_editor_advanced_tab'}, tbody({},
          tr({},
            td({'className': 'tab_headers'},
              div({
                'id': 'character_inventory_tab_header',
                'className': 'tab_header ' + (state['selectedAdvancedTab'] == 'inventory' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedAdvancedTab': 'inventory'}); }
              }, "Inventory"),
              div({
                'id': 'character_game_event_tab_header',
                'className': 'tab_header ' + (state['selectedAdvancedTab'] == 'game_event' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedAdvancedTab': 'game_event'}); }
              }, "Game Event"),
              div({
                'id': 'character_battle_tab_header',
                'className': 'tab_header ' + (state['selectedAdvancedTab'] == 'battle' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedAdvancedTab': 'battle'}); }
              }, "Battle")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'className': 'tab'},
                div({'id': 'character_inventory_container'}, getInventoryTab()),
                div({'id': 'character_game_event_container'}, getGameEventTab()),
                div({'id': 'character_battle_container'}, getBattleTab())
              )
            )
          )
        )),

        div({'id': 'object_editor_characters_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'},
            button({'id': 'add_character_button', 'onClick': addNewCharacter}, span({'className': 'fa fa-plus-circle'}), " Add new character"),
            hr({}),
            div({'id': 'battler_types_container'},
              table({'className': 'editor_table'}, tbody({}, tableRows))
            )
          )
        )

      );
  }

  JsObject getInventoryTab() {
    if(state['selected'] == -1) {
      return div({});
    }

    List<JsObject> inventoryContainers = [];

    Character character = World.characters.values.elementAt(state['selected']);

    List<JsObject> tableRows = [];

    tableRows.add(
      tr({},
        td({}, "Num"),
        td({}, "Item"),
        td({}, "Quantity"),
        td({})
      )
    );

    for(int j=0; j<character.inventory.itemNames().length; j++) {
      String curItemName = character.inventory.itemNames().elementAt(j);

      List<JsObject> options = [];

      World.items.keys.forEach((String itemOptionName) {
        if(itemOptionName != curItemName && character.inventory.itemNames().contains(itemOptionName)) {
          // don't show items that are already somewhere else in the character's inventory
          return;
        }

        options.add(
          option({}, itemOptionName)
        );
      });

      tableRows.add(
        tr({},
          td({}, j),
          td({},
            select({
              'id': 'character_${state['selected']}_inventory_${j}_item',
              'value': curItemName,
              'onChange': onInputChange
            }, options)
          ),
          td({},
            Editor.generateInput({
              'id': 'character_${state['selected']}_inventory_${j}_quantity',
              'type': 'text',
              'className': 'number',
              'value': character.inventory.getQuantity(curItemName),
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_character_${state['selected']}_item_${j}',
              'onClick': Editor.generateConfirmDeleteFunction(
                World.characters.values.elementAt(state['selected']).inventory, curItemName, "inventory item", update
              )
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    inventoryContainers.add(
      div({'id': 'character_${state['selected']}_inventory_container'},
        button({
          'id': 'add_inventory_item_button',
          'onClick': addInventoryItem
        }, span({'className': 'fa fa-plus-circle'}), " Add new inventory item"),
        hr({}),
        "Money: ",
        Editor.generateInput({
          'id': 'character_${state['selected']}_money',
          'type': 'text',
          'className': 'number',
          'value': character.inventory.money,
          'onChange': onInputChange
        }),
        hr({}),
        table({}, tbody({}, tableRows))
      )
    );

    return div({'className': state['selectedAdvancedTab'] == 'inventory' ? '' : 'hidden'}, inventoryContainers);
  }

  JsObject getGameEventTab() {
    if(state['selected'] == -1) {
      return div({});
    }

    callbacks = [];

    List<JsObject> gameEventContainers = [];

    Character character = World.characters.values.elementAt(state['selected']);

    List<JsObject> options = [
      option({'value': ''}, "None")
    ];

    for(int j=0; j<World.gameEventChains.keys.length; j++) {
      String name = World.gameEventChains.keys.elementAt(j);

      options.add(
        option({'value': name}, name)
      );
    }

    List<JsObject> tableRows = [
      tr({}, [
        td({}, "Num"),
        td({}, "Event Type"),
        td({}, "Params"),
        td({})
      ])
    ];

    if(character.getGameEventChain() != null && character.getGameEventChain() != ""
        && World.gameEventChains[character.getGameEventChain()] != null) {
      for(int j=0; j<World.gameEventChains[character.getGameEventChain()].length; j++) {
        tableRows.add(
          ObjectEditorGameEvents.buildReadOnlyGameEventTableRowHtml(
            World.gameEventChains[character.getGameEventChain()][j],
            "character_${state['selected']}_game_event_${j}",
            j,
            callbacks
          )
        );
      }
    }

    gameEventContainers.add(
      div({'id': 'character_${state['selected']}_game_event_chain_container'}, [
        "Game Event Chain: ",
        select({
          'id': 'character_${state['selected']}_game_event_chain',
          'value': character.getGameEventChain(),
          'onChange': onInputChange
        }, options),
        hr({}),
        "Sight distance: ",
        Editor.generateInput({
          'id': 'character_${state['selected']}_sight_distance',
          'type': 'text',
          'className': 'number',
          'value': character.sightDistance,
          'onChange': onInputChange
        }),
        hr({}),
        table({'id': 'character_${state['selected']}_game_event_table'}, tbody({}, tableRows))
      ])
    );

    return div({'className': state['selectedAdvancedTab'] == 'game_event' ? '' : 'hidden'}, gameEventContainers);
  }

  JsObject getBattleTab() {
    if(state['selected'] == -1) {
      return div({});
    }

    Character character = World.characters.values.elementAt(state['selected']);

    List<JsObject> options = [];

    World.battlerTypes.forEach((String name, BattlerType battlerType) {
      options.add(
        option({'value': battlerType.name}, battlerType.name)
      );
    });

    return div({'className': state['selectedAdvancedTab'] == 'battle' ? '' : 'hidden'},
      table({'id': 'character_${state['selected']}_battle_container'}, tbody({},
        tr({}, [
          td({}, "Battler Type"),
          td({}, "Level")
        ]),
        tr({}, [
          td({},
            select({
              'id': 'character_${state['selected']}_battler_type',
              'value': character.battler.battlerType.name,
              'onChange': onInputChange
            }, options)
          ),
          td({},
            Editor.generateInput({
              'id': 'character_${state['selected']}_battler_level',
              'type': 'text',
              'className': 'number',
              'value': character.battler.level,
              'onChange': onInputChange
            })
          )
        ]))
      )
    );
  }
  
  void addNewCharacter(MouseEvent e) {
    String name = Editor.getUniqueName("New Character", World.characters);
    Character newCharacter = new Character(
      name,
      0, 0, 0, 0,
      2, 4,
      layer: 0,
      sizeX: 1, sizeY: 2,
      solid: true
    );
    
    BattlerType battlerType = World.battlerTypes.values.first;
    
    newCharacter.battler = new Battler(battlerType.name, battlerType, 2, battlerType.getAttacksForLevel(2));
    
    World.characters[name] = newCharacter;
    
    shouldScrollIntoView = true;
    setState({
      'selected': World.characters.keys.length - 1
    });
  }
  
  void addInventoryItem(MouseEvent e) {
    bool itemFound = false;
    Character selectedCharacter = World.characters.values.elementAt(state['selected']);
    for(int i=0; i<World.items.keys.length; i++) {
      if(!selectedCharacter.inventory.itemNames().contains(World.items.keys.elementAt(i))) {
        // add the first possible item that is not already in the character's inventory
        selectedCharacter.inventory.addItem(World.items.values.elementAt(i));
        itemFound = true;
        break;
      }
    }

    if(!itemFound) {
      window.alert("There are no items that can be added.");
    }
    
    update();
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_label", World.characters);
    
    String selectedPlayer = "";
    if(e != null) {
      Element element = e.target;
      if(element.getAttribute("type") == "checkbox" && element.id.contains("_player")) {
        if(Editor.getCheckboxInputBoolValue("#${element.id}")) {
          selectedPlayer = element.id;
        }
      }
    }
    
    Map<String, Character> charactersBefore = new Map<String, Character>();
    charactersBefore.addAll(World.characters);

    Map<String, Character> newCharacters = {};

    String oldLabel = World.characters.keys.elementAt(state['selected']);
    String newLabel = Editor.getTextInputStringValue('#character_${state['selected']}_label');
    
    for(int i=0; querySelector('#character_${i}_label') != null; i++) {
      String label = charactersBefore.keys.elementAt(i);
      if(label != oldLabel) {
        newCharacters[label] = World.characters[label];
      } else {
        try {
          int mapX = 0, mapY = 0, layer = 1;
          if(charactersBefore[label] != null) {
            mapX = charactersBefore[label].mapX;
            mapY = charactersBefore[label].mapY;
            layer = charactersBefore[label].layer;
          } else if(charactersBefore[oldLabel] != null) {
            mapX = charactersBefore[oldLabel].mapX;
            mapY = charactersBefore[oldLabel].mapY;
            layer = charactersBefore[oldLabel].layer;
          }
          
          Character character = new Character(
            newLabel,
            Editor.getTextInputIntValue('#character_${i}_sprite_id', 1),
            Editor.getTextInputIntValue('#character_${i}_picture_id', 1),
            mapX, mapY,
            Editor.getTextInputIntValue('#character_${i}_walk_speed', 2),
            Editor.getTextInputIntValue('#character_${i}_run_speed', 4),
            layer: layer,
            sizeX: Editor.getTextInputIntValue('#character_${i}_size_x', 1),
            sizeY: Editor.getTextInputIntValue('#character_${i}_size_y', 2),
            solid: true
          );
          
          character.name = Editor.getTextInputStringValue('#character_${i}_name');
          
          character.map = Editor.getSelectInputStringValue("#character_${i}_map");
          
          String battlerTypeName = Editor.getSelectInputStringValue('#character_${i}_battler_type');
          
          int level = Editor.getTextInputIntValue('#character_${i}_battler_level', 2);
          
          // TODO: add battler name field
          Battler battler = new Battler(
            "name",
            World.battlerTypes[battlerTypeName],
            level,
            World.battlerTypes[battlerTypeName].getAttacksForLevel(level)
          );
          
          character.battler = battler;
          character.sightDistance = Editor.getTextInputIntValue('#character_${i}_sight_distance', 0);

          character.inventory = new Inventory([]);
    
          for(int j=0; querySelector('#character_${state['selected']}_inventory_${j}_item') != null; j++) {
            String itemName = Editor.getSelectInputStringValue('#character_${state['selected']}_inventory_${j}_item');
            int itemQuantity = Editor.getTextInputIntValue('#character_${state['selected']}_inventory_${j}_quantity', 1);
            character.inventory.addItem(World.items[itemName], itemQuantity);
          }
          
          character.inventory.money = Editor.getTextInputIntValue("#character_${state['selected']}_money", 0);

          character.setGameEventChain(Editor.getSelectInputStringValue("#character_${state['selected']}_game_event_chain"), 0);
          
          newCharacters[newLabel] = character;
          
          if(selectedPlayer == "character_${i}_player") {
            Main.player.characters.add(character);
          } else if(selectedPlayer != "") {
            (querySelector("#character_${i}_player") as CheckboxInputElement).checked = false;
          }
        } catch(e, stackTrace) {
          // could not update this character
          print("Error updating character: " + e.toString());
          print(stackTrace);
        }
      }
    }

    World.characters = newCharacters;
    
    update();

    Editor.debounceExport();
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    World.characters.forEach((String key, Character character) {
      Map<String, Object> characterJson = {};
      characterJson["spriteId"] = character.spriteId;
      characterJson["pictureId"] = character.pictureId;
      characterJson["sizeX"] = character.sizeX;
      characterJson["sizeY"] = character.sizeY;
      characterJson["walkSpeed"] = character.walkSpeed;
      characterJson["runSpeed"] = character.runSpeed;
      characterJson["map"] = character.map;
      characterJson["name"] = character.name;
      
      // map information
      characterJson["mapX"] = character.mapX;
      characterJson["mapY"] = character.mapY;
      characterJson["layer"] = character.layer;
      characterJson["direction"] = character.direction;
      characterJson["solid"] = character.solid;
      
      // inventory
      List<Map<String, String>> inventoryJson = [];
      character.inventory.itemNames().forEach((String itemName) {
        Map<String, String> itemJson = {};
        itemJson["item"] = itemName;
        itemJson["quantity"] = character.inventory.getQuantity(itemName).toString();
        
        inventoryJson.add(itemJson);
      });
      
      characterJson["inventory"] = inventoryJson;
      
      characterJson["money"] = character.inventory.money;
      
      // game event chain
      characterJson["gameEventChain"] = character.getGameEventChain();
      
      // battle
      characterJson["battlerType"] = character.battler.battlerType.name;
      characterJson["battlerLevel"] = character.battler.level.toString();
      characterJson["sightDistance"] = character.sightDistance.toString();
      
      if(Main.player.characters.contains(character)) {
        characterJson["player"] = true;
      }
      
      charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
}