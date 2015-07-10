library dart_rpg.store_game_event;

import 'dart:math' as math;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';
import 'package:dart_rpg/src/game_event/quantity_choice_game_event.dart';

class StoreGameEvent extends GameEvent {
  Character character;
  
  StoreGameEvent(this.character, [Function callback]) : super(null, callback);
  
  void trigger() {
    Function itemPurchaseCallback;
    itemPurchaseCallback = (Item item) {
      // TODO: decide which windows should be shown during quantity choice game event
      Gui.clear();
      
      if(item != null && Main.player.inventory.money >= item.basePrice) {
        // calculate min and max from number available and money available
        int max = math.min(
            character.inventory.getQuantity(item.name),
            (Main.player.inventory.money/item.basePrice).floor()
          );
        new QuantityChoiceGameEvent(character, 1, max,
          callback: (int quantity) {
            // show a confirmation message before completing purchase
            new TextGameEvent.choice(237, "Buy $quantity of ${item.name} for \$${item.basePrice * quantity}?",
              new ChoiceGameEvent(character, {
                "Yes": [new GameEvent((_) {
                  Main.player.inventory.money -= item.basePrice * quantity;
                  character.inventory.money += item.basePrice * quantity;
                  character.inventory.removeItem(item.name, quantity);
                  Main.player.inventory.addItem(item, quantity);
                  
                  new TextGameEvent(237, "Thank you! Here you go.", () {
                    Gui.clear();
                    GuiItemsMenu.trigger(character, itemPurchaseCallback, true, character);
                  }).trigger();
                })],
                "No": [new GameEvent((_) {
                  Gui.clear();
                  GuiItemsMenu.trigger(character, itemPurchaseCallback, true, character);
                })]
              })
            ).trigger();
          },
          cancelEvent: new GameEvent((_) { // onCancel event
            Gui.clear();
            GuiItemsMenu.trigger(character, itemPurchaseCallback, true, character);
          }),
          price: item.basePrice).trigger();
      } else if(item != null && Main.player.inventory.money < item.basePrice) {
        new TextGameEvent(237, "You don't have enough money to buy this item.", () {
          Gui.clear();
          GuiItemsMenu.trigger(character, itemPurchaseCallback, true, character);
        }).trigger();
      } else {
        callback();
      }
    };
    
    GuiItemsMenu.trigger(character, itemPurchaseCallback, true, character);
  }
}