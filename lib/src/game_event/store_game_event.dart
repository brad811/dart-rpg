library dart_rpg.store_game_event;

import 'dart:js';
import 'dart:math' as math;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';
import 'package:dart_rpg/src/game_event/quantity_choice_game_event.dart';

// TODO: perhaps change to shop
// TODO: should money belong to player instead of player's characters?

class StoreGameEvent implements GameEvent {
  static final String type = "store";
  Function function, callback;
  
  Character character;
  
  StoreGameEvent([this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    character = interactable as Character;
    
    GuiItemsMenu.trigger(character, purchaseItem, true, character);
  }
  
  void purchaseItem(Item item) {
    // TODO: decide which windows should be shown during quantity choice game event
    Gui.clear();
    
    if(item != null && Main.player.getCurCharacter().inventory.money >= item.basePrice) {
      // calculate min and max from number available and money available
      int max = math.min(
          character.inventory.getQuantity(item.name),
          (Main.player.getCurCharacter().inventory.money/item.basePrice).floor()
        );
      new QuantityChoiceGameEvent(1, max,
        callback: (int quantity) {
          GameEvent purchaseConfirm = new GameEvent((_) {
            Main.player.getCurCharacter().inventory.money -= item.basePrice * quantity;
            character.inventory.money += item.basePrice * quantity;
            character.inventory.removeItem(item.name, quantity);
            Main.player.getCurCharacter().inventory.addItem(item, quantity);
            
            new TextGameEvent(237, "Thank you! Here you go.", () {
              Gui.clear();
              GuiItemsMenu.trigger(character, purchaseItem, true, character);
            }).trigger(character);
          });
          
          GameEvent purchaseCancel = new GameEvent((_) {
            Gui.clear();
            GuiItemsMenu.trigger(character, purchaseItem, true, character);
          });
          
          // show a confirmation message before completing purchase
          new TextGameEvent.choice(237, "Buy $quantity of ${item.name} for \$${item.basePrice * quantity}?",
            new ChoiceGameEvent(
              ChoiceGameEvent.generateChoiceMap(
                "store_purchase",
                {
                  "Yes": [purchaseConfirm],
                  "No": [purchaseCancel]
                }
              )
            )
          ).trigger(character);
        },
        cancelEvent: new GameEvent((_) { // onCancel event
          Gui.clear();
          GuiItemsMenu.trigger(character, purchaseItem, true, character);
        }),
        price: item.basePrice).trigger(character);
    } else if(item != null && Main.player.getCurCharacter().inventory.money < item.basePrice) {
      new TextGameEvent(237, "You don't have enough money to buy this item.", () {
        Gui.clear();
        GuiItemsMenu.trigger(character, purchaseItem, true, character);
      }).trigger(character);
    } else {
      callback();
    }
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    return null;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    StoreGameEvent storeGameEvent = new StoreGameEvent();
    
    return storeGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    
    return gameEventJson;
  }
}