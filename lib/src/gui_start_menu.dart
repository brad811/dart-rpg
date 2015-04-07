library dart_rpg.gui_start_menu;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/item_stack.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class GuiStartMenu {
  static ChoiceGameEvent start = new ChoiceGameEvent.custom(
    Main.player,
    {
      "Stats": [stats],
      "Powers": [exit],
      "Items": [items],
      "Save": [exit],
      "Exit": [exit]
    },
    15, 0,
    5, 6,
    exit
  );
  
  static GameEvent exit = new GameEvent( (Function a) {
    Gui.windows = [];
    Main.focusObject = Main.player;
  });
  
  static GameEvent stats = new GameEvent((Function a) {
    Gui.windows.add(() {
      Gui.renderWindow(
        0, 0,
        12, 8
      );
      
      Battler battler = Main.player.battler;
      Font.renderStaticText(2.0, 2.0, "Player");
      Font.renderStaticText(2.75, 3.5, "Health: ${battler.startingHealth}");
      Font.renderStaticText(2.75, 5.0, "Physical Attack: ${battler.startingPhysicalAttack}");
      Font.renderStaticText(2.75, 6.5, "Physical Defence: ${battler.startingPhysicalDefense}");
      Font.renderStaticText(2.75, 8.0, "Magical Attack: ${battler.startingMagicalAttack}");
      Font.renderStaticText(2.75, 9.5, "Magical Defense: ${battler.startingMagicalDefense}");
      Font.renderStaticText(2.75, 11.0, "Speed: ${battler.startingSpeed}");
      
      Font.renderStaticText(2.75, 13.0, "Next Level: ${battler.nextLevelExperience() - battler.experience}");
    });
    
    GameEvent powersBack = new GameEvent((Function a) {
      Gui.windows = [];
      GuiStartMenu.start.trigger();
    });
    
    new ChoiceGameEvent.custom(
        Main.player, {"Back": [powersBack]},
        15, 0,
        5, 2,
        powersBack
    ).trigger();
  });
  
  // TODO: move this into its own class?
  //   because the item screen will also be used in battle
  //   perhaps that class could return the item selected
  static GameEvent items = new GameEvent((Function a) {
    Map<String, List<GameEvent>> items = new Map<String, List<GameEvent>>();
    for(ItemStack itemStack in Main.player.inventory.itemStacks) {
      String name = itemStack.quantity.toString();
      if(name.length == 1)
        name = "0" + name;
      
      name += " x ";
      name += itemStack.item.name;
      items.addAll({name: [exit]});
    }
    items.addAll({"Back": [start]});
    
    ChoiceGameEvent itemChoice;
    Function descriptionWindow;
    
    GameEvent onCancel = new GameEvent((Function a) {
      Gui.windows.remove(descriptionWindow);
      start.trigger();
    });
    
    // TODO: somehow use existing logic to break words in other windows
    GameEvent onChange = new GameEvent((Function a) {
      Gui.windows.remove(descriptionWindow);
      if(itemChoice.curChoice < Main.player.inventory.itemStacks.length) {
        Item curItem = Main.player.inventory.itemStacks[itemChoice.curChoice].item;
        Sprite curSprite = new Sprite.int(curItem.pictureId, 13, 1);
        descriptionWindow = () {
          Gui.renderWindow(10, 0, 9, 9);
          Font.renderStaticText(21.0, 9.0, curItem.description);
          curSprite.renderStaticSized(3, 3);
        };
        Gui.windows.add(descriptionWindow);
      }
    });
    
    itemChoice = new ChoiceGameEvent.custom(
        Main.player, items,
        0, 0,
        10, 10,
        onCancel,
        onChange
    );
    
    onChange.trigger();
    
    itemChoice.trigger();
  });
}