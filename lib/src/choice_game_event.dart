library ChoiceEvent;

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';

class ChoiceGameEvent extends GameEvent implements InputHandler {
  final InteractableInterface interactable;
  final Map<String, List<GameEvent>> choices;
  GameEvent cancelEvent;
  Function window;
  bool
    remove = true,
    isCustom = false;
  
  int
    curChoice = 0,
    addWidth,
    posX = 16,
    posY = 9,
    sizeX = 3,
    sizeY = 2;
  
  ChoiceGameEvent(this.interactable, this.choices) : super() {
    int maxLength = 0;
    for(int i=0; i<choices.keys.toList().length; i++) {
      if(choices.keys.toList()[i].length > maxLength)
        maxLength = choices.keys.toList()[i].length;
    }
    
    addWidth = ((maxLength - 3) / 2).round();
  }
  
  factory ChoiceGameEvent.custom(
      InteractableInterface interactable,
      Map<String, List<GameEvent>> choices,
      int posX, int posY, int sizeX, int sizeY) {
    ChoiceGameEvent choiceGameEvent = new ChoiceGameEvent(interactable, choices);
    choiceGameEvent.addWidth = 0;
    choiceGameEvent.posX = posX;
    choiceGameEvent.posY = posY;
    choiceGameEvent.sizeX = sizeX;
    choiceGameEvent.sizeY = sizeY;
    
    choiceGameEvent.isCustom = true;
    
    return choiceGameEvent;
  }
  
  void trigger() {
    Main.focusObject = this;
    
    // reverse the list so they get rendered in order
    List<String> myChoices = choices.keys.toList().reversed.toList();
    
    window = () {
      if(isCustom) {
        Gui.renderWindow(
          posX, posY,
          sizeX, sizeY
        );
        
        for(int i=myChoices.length-1; i>=0; i--) {
          Font.renderStaticText(
            posX*2 + 2 - addWidth*1.45,
            posY*2 - (i-myChoices.length-0.25)*1.75,
            myChoices[i]
          );
        }
        
        Font.renderStaticText(
          posX*2 + 0.75 - addWidth*1.45,
          posY*2 + 1.75 + (curChoice+0.25)*1.75,
          new String.fromCharCode(128)
        );
      } else {
        Gui.renderWindow(
          posX - (addWidth*0.75).round(), posY - myChoices.length + 1,
          sizeX + (addWidth*0.75).round(), sizeY + myChoices.length - 1
        );
        
        for(int i=myChoices.length-1; i>=0; i--) {
          Font.renderStaticText(posX*2 + 2 - addWidth*1.45, posY*2 - (i-1)*1.75, myChoices[i]);
        }
        
        Font.renderStaticText(
          posX*2 + 0.75 - addWidth*1.45,
          posY*2 + 1.75 - (myChoices.length - curChoice - 1)*1.75,
          new String.fromCharCode(128)
        );
      }
    };
    
    Gui.windows.add(window);
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(Input.UP)) {
      curChoice--;
      if(curChoice < 0) {
        curChoice = choices.keys.toList().length - 1;
      }
    } else if(keyCodes.contains(Input.DOWN)) {
      curChoice++;
      if(curChoice > choices.keys.toList().length - 1) {
        curChoice = 0;
      }
    } else if(keyCodes.contains(Input.CONFIRM)) {
      if(remove)
        Gui.windows.remove(window);
      
      Interactable.chainGameEvents(interactable, choices.values.toList()[curChoice]);
      interactable.gameEvent.trigger();
    } else if(keyCodes.contains(Input.BACK) && cancelEvent != null) {
      Gui.windows.remove(window);
      
      Interactable.chainGameEvents(interactable, [cancelEvent]);
      interactable.gameEvent.trigger();
    }
  }
}