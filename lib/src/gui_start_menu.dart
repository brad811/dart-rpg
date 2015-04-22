library dart_rpg.gui_start_menu;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/text_game_event.dart';

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
  
  static GameEvent items = new GameEvent((Function a) {
    GuiItemsMenu.trigger(Main.player, (Item item) {
      Gui.clear();
      if(item == null) {
        start.trigger();
      } else {
        item = Main.player.inventory.removeItem(item);
        TextGameEvent text = item.use(Main.player.battler);
        text.callback = () {
          Main.focusObject = Main.player;
          items.trigger();
        };
        text.trigger();
      }
    });
  });
  
  static GameEvent exit = new GameEvent((Function a) {
    Gui.clear();
    Main.focusObject = Main.player;
  });
  
  static GameEvent stats = new GameEvent((Function a) {
    Gui.addWindow(() {
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
      Gui.clear();
      GuiStartMenu.start.trigger();
    });
    
    new ChoiceGameEvent.custom(
        Main.player, {"Back": [powersBack]},
        15, 0,
        5, 2,
        powersBack
    ).trigger();
  });
}