library dart_rpg.inventory_game_event;

import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class InventoryGameEvent implements GameEvent {
  static final String type = "inventory";
  Function function, callback;
  
  String
    characterLabel,
    itemLabel;
  int quantity;
  
  InventoryGameEvent(this.characterLabel, this.itemLabel, this.quantity, [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    Character character;
    
    if(characterLabel == "____player") {
      character = Main.player.getCurCharacter();
    } else {
      character = World.characters[characterLabel];
    }

    if(quantity >= 0) {
      character.inventory.addItem(World.items[itemLabel], quantity);
    } else {
      character.inventory.removeItem(itemLabel, quantity);
    }
    
    callback();
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<JsObject> characterOptions = [];
    characterOptions.add(
      option({'value': '____player'}, "Player")
    );
    World.characters.forEach((String curCharacterLabel, Character character) {
      characterOptions.add(
        option({'value': curCharacterLabel}, curCharacterLabel)
      );
    });

    List<JsObject> itemOptions = [];
    World.items.forEach((String curItemLabel, Item item) {
      itemOptions.add(
        option({'value': curItemLabel}, curItemLabel)
      );
    });

    return table({}, tbody({},
      tr({},
        td({}, "Character"),
        td({}, "Item"),
        td({}, "Quantity")
      ),
      tr({},
        td({},
          select({
            'id': '${prefix}_character',
            'disabled': readOnly,
            'value': characterLabel,
            'onChange': onInputChange
          }, characterOptions)
        ),
        td({},
          select({
            'id': '${prefix}_item',
            'disabled': readOnly,
            'value': itemLabel,
            'onChange': onInputChange
          }, itemOptions)
        ),
        td({},
          Editor.generateInput({
            'id': '${prefix}_quantity',
            'type': 'text',
            'className': 'number',
            'value': quantity,
            'readOnly': readOnly,
            'onChange': onInputChange
          })
        )
      )
    ));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    InventoryGameEvent inventoryGameEvent = new InventoryGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_character"),
        Editor.getSelectInputStringValue("#${prefix}_item"),
        Editor.getTextInputIntValue("#${prefix}_quantity", 1)
      );
    
    if(inventoryGameEvent.characterLabel == "") {
      inventoryGameEvent.characterLabel = "____player";
    }

    return inventoryGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["character"] = characterLabel;
    gameEventJson["item"] = itemLabel;
    gameEventJson["quantity"] = quantity;
    
    return gameEventJson;
  }
}