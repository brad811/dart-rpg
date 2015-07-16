library dart_rpg.quantity_choice_game_event;

import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

class QuantityChoiceGameEvent extends ChoiceGameEvent implements InputHandler {
  int price = -1;
  
  QuantityChoiceGameEvent(int min, int max,
      {Function callback, GameEvent cancelEvent, GameEvent onChangeEvent, this.price})
      : super(new Map<String, String>(),
          cancelEvent: cancelEvent, onChangeEvent: onChangeEvent) {
    for(int i=max; i>=min; i--) {
      List<GameEvent> events = [new GameEvent((_) { callback(i); })];
      
      World.gameEventChains["tmp_choice_${i}"] = events;
      
      this.choiceGameEventChains[i.toString()] = "tmp_choice_${i}";
    }
    
    this.posX = 10;
    this.posY = 10;
    this.sizeX = 10;
    this.sizeY = 2;
    this.curChoice = this.choiceGameEventChains.keys.length - 1;
  }
  
  void trigger(InteractableInterface interactable) {
    Main.focusObject = this;
    
    window = () {
      int curChoiceValue = int.parse(choiceGameEventChains.keys.toList().elementAt(curChoice));
      
      // show the currently selected quantity
      Gui.renderWindow(
        posX, posY,
        sizeX, sizeY
      );
      
      Font.renderStaticText(
        posX*2 + 14.0,
        posY*2 + 1.75,
        choiceGameEventChains.keys.toList().elementAt(curChoice)
      );
      
      Font.renderStaticText(
        posX*2 - 2 - addWidth*1.45,
        posY*2 + 1.75,
        "How many?"
      );
      
      // if we're purchasing something, show the total cost for the selected quantity
      if(price != -1) {
        Gui.renderWindow(
          0, posY,
          sizeX, sizeY
        );
        
        Font.renderStaticText(
          0 + 14.0,
          posY*2 + 1.75,
          (curChoiceValue * price).toString()
        );
        
        Font.renderStaticText(
          0 - 2 - addWidth*1.45,
          posY*2 + 1.75,
          "Total cost:"
        );
      }
    };
    
    Gui.addWindow(window);
  }
}