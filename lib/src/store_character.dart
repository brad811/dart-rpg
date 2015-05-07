library dart_rpg.store_character;

import 'dart:math' as math;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/quantity_choice_game_event.dart';
import 'package:dart_rpg/src/text_game_event.dart';

class StoreCharacter extends Character {
  StoreCharacter(int spriteId, int pictureId,
        int mapX, int mapY, int layer, int sizeX, int sizeY, bool solid,
        String helloMessage, String goodbyeMessage, Map<Item, int> storeItemQuantities) : super(
            spriteId, pictureId, mapX, mapY, layer, sizeX, sizeY, solid) {
    
    this.inventory.itemQuantities = storeItemQuantities;
    
    List<GameEvent> storeClerkGameEvents = [];
    storeClerkGameEvents = [
      new TextGameEvent(237, helloMessage),
      new GameEvent((callback) {
        Function itemPurchaseCallback;
        itemPurchaseCallback = (Item item) {
          // TODO: decide which windows should be shown during quantity choice game event
          Gui.clear();
          
          if(item != null && Main.player.inventory.money >= item.basePrice) {
            // calculate min and max from number available and money available
            int max = math.min(
                this.inventory.itemQuantities[item],
                (Main.player.inventory.money/item.basePrice).floor()
              );
            new QuantityChoiceGameEvent(this, 1, max, (int quantity) {
              // show a confirmation message before completing purchase
              new TextGameEvent.choice(237, "Buy $quantity of ${item.name} for \$${item.basePrice * quantity}?",
                new ChoiceGameEvent(this, {
                  "Yes": [new GameEvent((_) {
                    Main.player.inventory.money -= item.basePrice * quantity;
                    this.inventory.money += item.basePrice * quantity;
                    this.inventory.removeItem(item, quantity);
                    Main.player.inventory.addItem(item, quantity);
                    
                    new TextGameEvent(237, "Thank you! Here you go.", () {
                      Gui.clear();
                      GuiItemsMenu.trigger(this, itemPurchaseCallback, true, this);
                    }).trigger();
                  })],
                  "No": [new GameEvent((_) {
                    Gui.clear();
                    GuiItemsMenu.trigger(this, itemPurchaseCallback, true, this);
                  })]
                })
              ).trigger();
            }, new GameEvent((_) { // onCancel event
              Gui.clear();
              GuiItemsMenu.trigger(this, itemPurchaseCallback, true, this);
            }), null, item.basePrice).trigger();
          } else if(item != null && Main.player.inventory.money < item.basePrice) {
            new TextGameEvent(237, "You don't have enough money to buy this item.", () {
              Gui.clear();
              GuiItemsMenu.trigger(this, itemPurchaseCallback, true, this);
            }).trigger();
          } else {
            callback();
          }
        };
        
        GuiItemsMenu.trigger(this, itemPurchaseCallback, true, this);
      }),
      new TextGameEvent(237, goodbyeMessage)
    ];
    
    Interactable.chainGameEvents(this, storeClerkGameEvents);
  }
}