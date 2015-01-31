library ChoiceEvent;

import 'dart:html';

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';

class ChoiceGameEvent extends GameEvent implements InputHandler {
  InteractableInterface interactable;
  List<String> choices = [];
  int curChoice = 0;
  List<List<GameEvent>> callbacks = [];
  Function window;
  int addWidth;
  
  ChoiceGameEvent(this.interactable, this.choices, this.callbacks) : super() {
    int maxLength = 0;
    for(int i=0; i<choices.length; i++) {
      if(choices[i].length > maxLength)
        maxLength = choices[i].length;
    }
    
    addWidth = ((maxLength - 3) / 2).round();
  }
  
  void trigger() {
    Main.focusObject = this;
    
    // reverse the list so they get rendered in order
    List<String> myChoices = choices.reversed.toList();
    
    window = () {
      Gui.renderWindow(
        16 - (addWidth*0.75).round(), 9 - myChoices.length + 1,
        3 + (addWidth*0.75).round(), 2 + myChoices.length - 1
      );
      
      for(int i=myChoices.length-1; i>=0; i--) {
        Font.renderStaticText(34.0 - addWidth*1.45, 18.0 - (i-1)*1.75, myChoices[i]);
      }
      
      Font.renderStaticText(
        32.75 - addWidth*1.45,
        19.75 - (myChoices.length - curChoice - 1)*1.75,
        new String.fromCharCode(128)
      );
    };
    
    Gui.windows.add(window);
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(KeyCode.UP)) {
      curChoice--;
      if(curChoice < 0) {
        curChoice = choices.length - 1;
      }
    } else if(keyCodes.contains(KeyCode.DOWN)) {
      curChoice++;
      if(curChoice > choices.length - 1) {
        curChoice = 0;
      }
    } else if(keyCodes.contains(KeyCode.X)) {
      Gui.windows.remove(window);
      Interactable.chainGameEvents(interactable, callbacks[curChoice]);
      interactable.gameEvent.trigger();
    }
  }
}