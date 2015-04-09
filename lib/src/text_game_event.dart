library dart_rpg.text_game_event;

import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/main.dart';

class TextGameEvent extends GameEvent {
  int pictureSpriteId;
  String text;
  ChoiceGameEvent choiceGameEvent;
  
  List<String>
      originalTextLines = [],
      textLines = [];
  
  TextGameEvent(this.pictureSpriteId, this.text, [Function callback]) : super(null, callback) {
    textLines = Gui.splitText(text, 15);
  }
  
  factory TextGameEvent.choice(int pictureSpriteId, String text, ChoiceGameEvent choice) {
    TextGameEvent textGameEvent = new TextGameEvent(pictureSpriteId, text);
    textGameEvent.choiceGameEvent = choice;
    return textGameEvent;
  }
  
  void trigger() {
    // Take input focus and show the GUI window
    Gui.inConversation = true;
    Gui.textLines = textLines;
    Gui.pictureSpriteId = pictureSpriteId;
    Main.focusObject = this;
    
    if(textLines.length <= Gui.maxLines && choiceGameEvent != null) {
      choiceGameEvent.trigger();
    }
  }
  
  void continueText() {
    if(textLines.length > Gui.maxLines) {
      // Remove the top lines so the next lines will show
      textLines.removeRange(0, Gui.maxLines);
      
      if(textLines.length <= Gui.maxLines && choiceGameEvent != null) {
        // TODO: is this line still needed?
        //choiceGameEvent.callbacks = [callback];
        choiceGameEvent.trigger();
      }
    } else {
      // Close the text box and reset the text
      close();
      textLines = new List<String>.from(originalTextLines);
    }
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(Input.CONFIRM)) {
      continueText();
    }
  }
  
  void close() {
    // Set focus back on the player and hide the GUI window
    Gui.inConversation = false;
    Main.focusObject = Main.player;
    if(callback != null) {
      callback();
    }
  }
}