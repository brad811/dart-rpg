library dart_rpg.gui_items_menu;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class GuiItemsMenu {
  static final double
    textX = 21.0,
    textY = 9.0;
  
  static final int
    itemDescriptionWindowWidth = 9;
  
  static Item selectedItem;
  static Function selectCallback;
  static bool backEnabled = true;
  static bool storeMode = false;
  static Character character;
  static Character storeCharacter;
  
  static Function playerMoneyWindow = () {
    Gui.renderWindow(0, 10, 10, 2);
    Font.renderStaticText(1.0, 21.75, "Money: " + Main.player.inventory.money.toString());
  };
  
  static Function storeMoneyWindow = () {
    Gui.renderWindow(10, 10, 10, 2);
    Font.renderStaticText(21.0, 21.75, "Store: " + storeCharacter.inventory.money.toString());
  };
  
  static GameEvent selectItem = new GameEvent((Function callback) {
    selectCallback(selectedItem);
  });
  
  static GameEvent items = new GameEvent((Function callback) {
    GameEvent callbackEvent = new GameEvent((Function c){
      callback(null);
    });
    selectCallback = callback;
    
    Map<String, List<GameEvent>> items = new Map<String, List<GameEvent>>();
    for(String itemName in character.inventory.itemNames()) {
      String text = character.inventory.getQuantity(itemName).toString();
      if(text.length == 1)
        text = "0" + text;
      
      text += " x ";
      text += itemName;
      items.addAll({text: [selectItem]});
    }
    
    if(backEnabled) {
      items.addAll({"Back": [callbackEvent]});
    }
    
    ChoiceGameEvent itemChoice;
    Function descriptionWindow;
    
    GameEvent onCancel = new GameEvent((Function a) {
      Gui.removeWindow(descriptionWindow);
      callbackEvent.trigger(Main.player);
    });
    
    GameEvent onChange = new GameEvent((Function callback) {
      Gui.removeWindow(descriptionWindow);
      
      if(itemChoice.curChoice < character.inventory.itemNames().length) {
        String selectedItemName = character.inventory.itemNames()[itemChoice.curChoice];
        selectedItem = character.inventory.getItem(selectedItemName);
        Sprite curSprite = new Sprite.int(selectedItem.pictureId, 13, 1);
        descriptionWindow = () {
          Gui.renderWindow(10, 0, itemDescriptionWindowWidth, 10);
          
          // TODO: calculate max lines based on window height
          List<String> textLines = Gui.splitText(selectedItem.description, itemDescriptionWindowWidth);
          for(int i=0; i<textLines.length && i<8; i++) {
            Font.renderStaticText(textX, textY + Gui.verticalLineSpacing*i, textLines[i]);
          }
          
          String priceText;
          if(GuiItemsMenu.storeMode) {
            priceText = "Price: ${selectedItem.basePrice}";
          } else {
            priceText = "Value: ${selectedItem.basePrice}";
          }
          
          // TODO: perhaps calculate these values only once to save CPU cycles
          Font.renderStaticText(
              textX + 10 - (selectedItem.basePrice.toString().length / 1.75),
              textY + Gui.verticalLineSpacing*6,
              priceText
          );
          
          curSprite.renderStaticSized(3, 3);
        };
        
        Gui.addWindow(descriptionWindow);
      }
    });
    
    Map<String, List<GameEvent>> itemChoices = new Map<String, List<GameEvent>>();
    
    int i = 0;
    items.forEach((String key, List<GameEvent> chain) {
      itemChoices[key] = chain;
      
      i += 1;
    });
    
    itemChoice = new ChoiceGameEvent.custom(
        Main.player,
        ChoiceGameEvent.generateChoiceMap("start_menu_items", itemChoices),
        0, 0,
        10, 10,
        cancelEvent: onCancel,
        onChangeEvent: onChange
    );
    
    onChange.trigger(Main.player);
    
    itemChoice.trigger(Main.player);
  });
  
  static trigger(Character character, Function callback,
      [bool backEnabled = true, Character storeCharacter]) {
    GuiItemsMenu.character = character;
    GuiItemsMenu.backEnabled = backEnabled;
    
    Gui.addWindow(playerMoneyWindow);
    
    GuiItemsMenu.storeMode = storeCharacter != null;
    if(storeMode) {
      Gui.addWindow(storeMoneyWindow);
      GuiItemsMenu.storeCharacter = storeCharacter;
    }
    
    items.callback = callback;
    items.trigger(Main.player);
  }
}