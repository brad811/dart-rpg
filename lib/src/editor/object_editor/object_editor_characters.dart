library dart_rpg.object_editor_characters;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_game_events.dart';

import 'package:react/react.dart';

// TODO: dimensions, where character is solid and interactable

class ObjectEditorCharacterComponent extends Component {
  void onInputChange() {
    // TODO: implement!
    print("ObjectEditorCharacterComponent.onInputChange not yet implemented!");
  }

  componentDidMount(a) {
    initSpritePickers();
  }

  componentDidUpdate(a, b, c) {
    initSpritePickers();
  }

  initSpritePickers() {
    int i = 0;
    for(String key in World.characters.keys) {
      Editor.initSpritePicker(
        "character_${i}_sprite_id",
        World.characters[key].spriteId,
        World.characters[key].sizeX, World.characters[key].sizeY,
        onInputChange
      );
      
      Editor.initSpritePicker(
        "character_${i}_picture_id",
        World.characters[key].pictureId,
        3, 3,
        onInputChange
      );
      
      i += 1;
    }
  }

  render() {
    List<JsObject> tableRows = [];

    tableRows.add(
      tr({}, [
        td({}, "Num"),
        td({}),
        td({}, "Sprite Id"),
        td({}, "Picture Id"),
        td({}, "Size"),
        td({}, "Map"),
        td({})
      ])
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
        tr({'id': 'character_row_${i}'}, [
          td({}, i),
          td({}, [
            "Label", br({}),
            input({'id': 'character_${i}_label', 'type': 'text', 'value': key}), br({}),
            "Name", br({}),
            input({'id': 'character_${i}_name', 'type': 'text', 'value': World.characters[key].name}), br({}),
            br({}),
            input({
              'id': 'character_${i}_player',
              'type': 'checkbox',
              'checked': Main.player.character.label == World.characters.keys.elementAt(i)
            }),
            "Player"
          ]),
          td({},
            Editor.generateSpritePickerHtml("character_${i}_sprite_id", World.characters[key].spriteId)
          ),
          td({},
            Editor.generateSpritePickerHtml("character_${i}_picture_id", World.characters[key].pictureId)
          ),
          td({}, [
            "X: ",
            input({'id': 'character_${i}_size_x', 'type': 'text', 'className': 'number', 'value': World.characters[key].sizeX}),
            br({}),
            "Y: ",
            input({'id': 'character_${i}_size_y', 'type': 'text', 'className': 'number', 'value': World.characters[key].sizeY})
          ]),
          td({},
            select({'id': 'character_${i}_map', 'value': World.characters[key].map}, options)
          ),
          td({},
            button({'id': 'delete_character_${i}'})
          )
        ])
      );
    }

    return table({'className': 'editor_table'}, tbody({}, tableRows));
  }
}

var objectEditorCharacterComponent = registerComponent(() => new ObjectEditorCharacterComponent());

class ObjectEditorCharacterInventoryComponent extends Component {
  int selected;

  render() {
    List<JsObject> inventoryContainers = [];

    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);

      List<JsObject> tableRows = [];

      tableRows.add(
        tr({}, [
          td({}, "Num"),
          td({}, "Item"),
          td({}, "Quantity"),
          td({})
        ])
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
              select({'id': 'character_${i}_inventory_${j}_item', 'value': curItemName})
            ),
            td({},
              input({
                'id': 'character_${i}_inventory_${j}_quantity',
                'type': 'text',
                'className': 'number',
                'value': character.inventory.getQuantity(curItemName)
              })
            ),
            td({'id': 'delete_character_${i}_item_${j}'}, "Delete")
          )
        );
      }

      inventoryContainers.add(
        div({'id': 'character_${i}_inventory_container', 'className': selected == i ? '' : 'hidden'}, [
          "Money: ",
          input({'id': 'character_${i}_money', 'type': 'text', 'className': 'number', 'value': character.inventory.money}),
          hr({}),
          table({}, tableRows)
        ])
      );
    }

    return div({}, inventoryContainers);
  }
}

var objectEditorCharacterInventoryComponent = registerComponent(() => new ObjectEditorCharacterInventoryComponent());

class ObjectEditorCharacterGameEventComponent extends Component {
  int selected;
  List<Function> callbacks = [];

  componentDidMount(a) {
    callCallbacks();
  }

  componentDidUpdate(a, b, c) {
    callCallbacks();
  }

  void callCallbacks() {
    if(callbacks != null) {
      for(Function callback in callbacks) {
        callback();
      }
    }
  }

  render() {
    this.callbacks = [];
    List<JsObject> gameEventContainers = [];

    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);

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
            ObjectEditorGameEvents.buildGameEventTableRowHtml(
              World.gameEventChains[character.getGameEventChain()][j],
              "character_${i}_game_event_${j}",
              j,
              readOnly: true, callbacks: this.callbacks
            )
          );
        }
      }

      gameEventContainers.add(
        div({'id': 'character_${i}_game_event_chain_container', 'className': selected == i ? '' : 'hidden'}, [
          "Game Event Chain: ",
          select({'id': 'character_${i}_game_event_chain'}, options),
          hr({}),
          "Sight distance: ",
          input({'id': 'character_${i}_sight_distance', 'type': 'text', 'className': 'number', 'value': character.sightDistance}),
          hr({}),
          table({'id': 'character_${i}_game_event_table'}, tableRows)
        ])
      );
    }

    return div({}, gameEventContainers);
  }
}

var objectEditorCharacterGameEventComponent = registerComponent(() => new ObjectEditorCharacterGameEventComponent());

class ObjectEditorCharacterBattleComponent extends Component {
  int selected;

  render() {
    List<JsObject> battleContainers = [];

    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);

      List<JsObject> options = [];

      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        options.add(
          option({'value': battlerType.name}, battlerType.name)
        );
      });

      battleContainers.add(
        table({'id': 'character_${i}_battle_container', 'className': selected == i ? '' : 'hidden'}, [
          tr({}, [
            td({}, "Battler Type"),
            td({}, "Level")
          ]),
          tr({}, [
            td({},
              select({'id': 'character_${i}_battler_type', 'value': character.battler.battlerType.name}, options)
            ),
            td({},
              input({'id': 'character_${i}_battler_level', 'type': 'text', 'className': 'number', 'value': character.battler.level})
            )
          ])
        ])
      );
    }

    return div({}, battleContainers);
  }
}

var objectEditorCharacterBattleComponent = registerComponent(() => new ObjectEditorCharacterBattleComponent());

class ObjectEditorCharacters {
  static List<String> advancedTabs = ["character_inventory", "character_game_event", "character_battle"];
  
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_character_button", addNewCharacter);
    Editor.attachButtonListener("#add_inventory_item_button", addInventoryItem);
    
    querySelector("#object_editor_characters_tab_header").onClick.listen((MouseEvent e) {
      ObjectEditorCharacters.selectRow(0);
    });
  }
  
  static void addNewCharacter(MouseEvent e) {
    Character newCharacter = new Character(
      "New Character",
      0, 0, 0, 0,
      layer: World.LAYER_BELOW,
      sizeX: 1, sizeY: 2,
      solid: true
    );
    
    BattlerType battlerType = World.battlerTypes.values.first;
    
    newCharacter.battler = new Battler(battlerType.name, battlerType, 2, battlerType.getAttacksForLevel(2));
    
    World.characters["New Character"] = newCharacter;
    
    update();
    Editor.update();
  }
  
  static void addInventoryItem(MouseEvent e) {
    Character selectedCharacter = World.characters.values.elementAt(selected);
    for(int i=0; i<World.items.keys.length; i++) {
      if(!selectedCharacter.inventory.itemNames().contains(World.items.keys.elementAt(i))) {
        // add the first possible item that is not already in the character's inventory
        selectedCharacter.inventory.addItem(World.items.values.elementAt(i));
        break;
      }
    }
    
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    render(objectEditorCharacterComponent({}), querySelector('#characters_container'));

    render(objectEditorCharacterInventoryComponent({}), querySelector('#inventory_container'));
    render(objectEditorCharacterGameEventComponent({}), querySelector('#character_game_event_container'));
    render(objectEditorCharacterBattleComponent({}), querySelector('#battle_container'));
    
    // highlight the selected row
    if(querySelector("#character_row_${selected}") != null) {
      querySelector("#character_row_${selected}").classes.add("selected");
      querySelector("#object_editor_characters_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(World.characters, "character");
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Editor.setMapDeleteButtonListeners(World.characters.values.elementAt(i).inventory.itemStacks, "character_${i}_item");
    }
    
    List<String> attrs = [
      // main
      "label", "name", "player",
      
      "sprite_id", "picture_id", "size_x", "size_y", "map",
      
      "money",
      
      // battle
      "battler_type", "battler_level", "sight_distance",
      
      // game event chain
      "game_event_chain"
    ];
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Editor.attachInputListeners("character_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#character_row_${i}", (Event e) {
        if(querySelector("#character_row_${i}") != null) {
          selectRow(i);
        }
      });
      
      Character character = World.characters.values.elementAt(i);
      
      for(int j=0; j<character.inventory.itemNames().length; j++) {
        Editor.attachInputListeners("character_${i}_inventory_${j}", ["item", "quantity"], onInputChange);
      }
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.characters.keys.length; j++) {
      // un-highlight other character rows
      querySelector("#character_row_${j}").classes.remove("selected");
      
      // hide the inventory items for other characters
      querySelector("#character_${j}_inventory_container").classes.add("hidden");
      querySelector("#character_${j}_game_event_chain_container").classes.add("hidden");
      querySelector("#character_${j}_battle_container").classes.add("hidden");
    }
    
    if(querySelector("#character_row_${i}") == null) {
      return;
    }
    
    // hightlight the selected character row
    querySelector("#character_row_${i}").classes.add("selected");
    
    // show the characters advanced area
    querySelector("#object_editor_characters_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected character
    querySelector("#character_${i}_inventory_container").classes.remove("hidden");
    querySelector("#character_${i}_game_event_chain_container").classes.remove("hidden");
    querySelector("#character_${i}_battle_container").classes.remove("hidden");
  }
  
  static void onInputChange(Event e) {
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
    
    World.characters = new Map<String, Character>();
    for(int i=0; querySelector('#character_${i}_label') != null; i++) {
      try {
        String labelBefore = charactersBefore.keys.elementAt(i);
        String label = Editor.getTextInputStringValue('#character_${i}_label');
        
        int mapX = 0, mapY = 0, layer = 1;
        if(charactersBefore[label] != null) {
          mapX = charactersBefore[label].mapX;
          mapY = charactersBefore[label].mapY;
          layer = charactersBefore[label].layer;
        } else if(charactersBefore[labelBefore] != null) {
          mapX = charactersBefore[labelBefore].mapX;
          mapY = charactersBefore[labelBefore].mapY;
          layer = charactersBefore[labelBefore].layer;
        }
        
        Character character = new Character(
          label,
          Editor.getTextInputIntValue('#character_${i}_sprite_id', 1),
          Editor.getTextInputIntValue('#character_${i}_picture_id', 1),
          mapX, mapY,
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
        
        World.characters[label] = character;
        
        if(selectedPlayer == "character_${i}_player") {
          Main.player.character = character;
        } else if(selectedPlayer != "") {
          (querySelector("#character_${i}_player") as CheckboxInputElement).checked = false;
        }
      } catch(e, stackTrace) {
        // could not update this character
        print("Error updating character: " + e.toString());
        print(stackTrace);
      }
    }
    
    for(int i=0; i<World.characters.keys.length; i++) {
      Character character = World.characters.values.elementAt(i);
      character.inventory = new Inventory([]);
      
      for(int j=0; querySelector('#character_${i}_inventory_${j}_item') != null; j++) {
        String itemName = Editor.getSelectInputStringValue('#character_${i}_inventory_${j}_item');
        int itemQuantity = Editor.getTextInputIntValue('#character_${i}_inventory_${j}_quantity', 1);
        character.inventory.addItem(World.items[itemName], itemQuantity);
      }
      
      character.inventory.money = Editor.getTextInputIntValue("#character_${i}_money", 0);
      
      character.setGameEventChain(Editor.getSelectInputStringValue("#character_${i}_game_event_chain"), 0);
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    World.characters.forEach((String key, Character character) {
      Map<String, Object> characterJson = {};
      characterJson["spriteId"] = character.spriteId;
      characterJson["pictureId"] = character.pictureId;
      characterJson["sizeX"] = character.sizeX;
      characterJson["sizeY"] = character.sizeY;
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
      
      if(Main.player.character.label == character.label) {
        characterJson["player"] = true;
      }
      
      charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
}