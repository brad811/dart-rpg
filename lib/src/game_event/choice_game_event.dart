library dart_rpg.choice_game_event;

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

class ChoiceGameEvent extends GameEvent implements InputHandler {
  InteractableInterface interactable;
  final Map<String, String> choiceGameEventChains;
  GameEvent cancelEvent;
  GameEvent onChangeEvent;
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
  
  ChoiceGameEvent(this.choiceGameEventChains, {this.cancelEvent, this.onChangeEvent}) : super() {
    int maxLength = 0;
    for(int i=0; i<choiceGameEventChains.keys.toList().length; i++) {
      if(choiceGameEventChains.keys.toList()[i].length > maxLength)
        maxLength = choiceGameEventChains.keys.toList()[i].length;
    }
    
    addWidth = ((maxLength - 3) / 2).round();
  }
  
  factory ChoiceGameEvent.custom(
      InteractableInterface interactable,
      Map<String, String> choiceGameEventChains,
      int posX, int posY, int sizeX, int sizeY, {GameEvent cancelEvent, GameEvent onChangeEvent}) {
    ChoiceGameEvent choiceGameEvent = new ChoiceGameEvent(
        choiceGameEventChains,
        cancelEvent: cancelEvent,
        onChangeEvent: onChangeEvent
      );
    choiceGameEvent.addWidth = 0;
    choiceGameEvent.posX = posX;
    choiceGameEvent.posY = posY;
    choiceGameEvent.sizeX = sizeX;
    choiceGameEvent.sizeY = sizeY;
    
    choiceGameEvent.isCustom = true;
    
    return choiceGameEvent;
  }
  
  void trigger(InteractableInterface interactable) {
    this.interactable = interactable;
    Main.focusObject = this;
    
    // reverse the list so they get rendered in order
    List<String> myChoices = choiceGameEventChains.keys.toList().reversed.toList();
    
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
    
    Gui.addWindow(window);
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(Input.UP)) {
      curChoice--;
      if(curChoice < 0) {
        curChoice = choiceGameEventChains.keys.toList().length - 1;
      }
      
      if(onChangeEvent != null)
        onChangeEvent.trigger(interactable);
    } else if(keyCodes.contains(Input.DOWN)) {
      curChoice++;
      if(curChoice > choiceGameEventChains.keys.toList().length - 1) {
        curChoice = 0;
      }
      
      if(onChangeEvent != null)
        onChangeEvent.trigger(interactable);
    } else if(keyCodes.contains(Input.CONFIRM)) {
      if(remove)
        Gui.removeWindow(window);
      
      List<GameEvent> choice = World.gameEventChains[choiceGameEventChains.values.toList()[curChoice]];
      
      Interactable.chainGameEvents(interactable, choice).trigger(interactable);
    } else if(keyCodes.contains(Input.BACK) && cancelEvent != null) {
      Gui.removeWindow(window);
      
      Interactable.chainGameEvents(interactable, [cancelEvent]).trigger(interactable);
    }
  }
}