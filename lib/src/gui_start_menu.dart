library dart_rpg.gui_start_menu;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/gui_items_menu.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class GuiStartMenu {
  static ChoiceGameEvent start = new ChoiceGameEvent.custom(
    Main.player,
    ChoiceGameEvent.generateChoiceMap("start_menu", {
      "Stats": [stats],
      "Powers": [exit],
      "Items": [items],
      "Save": [exit],
      "Exit": [exit]
    }),
    15, 0,
    5, 6,
    cancelEvent: exit
  );
  
  static GameEvent items = new GameEvent((Function a) {
    GuiItemsMenu.trigger(Main.player, (Item item) {
      GameEvent confirmItemUse = new GameEvent((_) {
        item = Main.player.inventory.removeItem(item.name);
        
        GameEvent gameEvent = item.use(Main.player.battler, new GameEvent((_) {
          Main.focusObject = Main.player;
          items.trigger(Main.player);
        }));
        
        gameEvent.trigger(Main.player);
      });
      
      GameEvent cancelItemUse = new GameEvent((_) {
        Gui.clear();
        items.trigger(Main.player);
      });
      
      Gui.clear();
      if(item == null) {
        start.trigger(Main.player);
      } else {
        // confirm dialog before using item from start menu
        new TextGameEvent.choice(237, "Use the ${item.name}?",
            new ChoiceGameEvent(
              ChoiceGameEvent.generateChoiceMap("start_menu_use_item",
                {
                  "Yes": [confirmItemUse],
                  "No": [cancelItemUse]
                }
              )
            )
        ).trigger(Main.player);
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
      GuiStartMenu.start.trigger(Main.player);
    });
    
    new ChoiceGameEvent.custom(
        Main.player,
        ChoiceGameEvent.generateChoiceMap("start_menu_powers",
          {
            "Back": [powersBack]
          }
        ),
        15, 0,
        5, 2,
        cancelEvent: powersBack
    ).trigger(Main.player);
  });
}