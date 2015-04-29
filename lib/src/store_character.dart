library dart_rpg.store_character;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/item_stack.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/text_game_event.dart';

class StoreCharacter extends Character {
  StoreCharacter(int spriteId, int pictureId,
        int mapX, int mapY, int layer, int sizeX, int sizeY, bool solid,
        String helloMessage, String goodbyeMessage, List<ItemStack> storeItems) : super(
            spriteId, pictureId, mapX, mapY, layer, sizeX, sizeY, solid) {
    
    for(ItemStack itemStack in storeItems) {
      this.inventory.addItem(itemStack.item, itemStack.quantity);
    }
    
    List<GameEvent> storeClerkGameEvents = [];
    storeClerkGameEvents = [
      new TextGameEvent(237, helloMessage),
      new GameEvent((callback) {
        // TODO: add quantity option when purchasing items
        Function itemPurchaseCallback;
        itemPurchaseCallback = (Item item) {
          Gui.clear();
          
          if(item != null && Main.player.inventory.money >= item.basePrice) {
            new TextGameEvent.choice(237, "Buy this for real?",
              new ChoiceGameEvent(this, {
                "Yes": [new GameEvent((_) {
                  Main.player.inventory.money -= item.basePrice;
                  this.inventory.money += item.basePrice;
                  this.inventory.removeItem(item);
                  Main.player.inventory.addItem(item);
                  
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