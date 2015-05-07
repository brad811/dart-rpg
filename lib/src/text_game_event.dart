library dart_rpg.text_game_event;

import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class TextGameEvent extends GameEvent {
  int pictureSpriteId;
  String text;
  ChoiceGameEvent choiceGameEvent;
  
  static List<String>
      originalTextLines = [],
      textLines = [];
  
  static final int
    conversationWindowWidth = 15,
    maxLines = 4;
  
  static final double
    textX = 9.0,
    textY = 23.5;
  
  TextGameEvent(this.pictureSpriteId, this.text, [Function callback]) : super(null, callback);
  
  factory TextGameEvent.choice(int pictureSpriteId, String text, ChoiceGameEvent choice) {
    TextGameEvent textGameEvent = new TextGameEvent(pictureSpriteId, text);
    textGameEvent.choiceGameEvent = choice;
    return textGameEvent;
  }
  
  void trigger() {
    textLines = Gui.splitText(text, conversationWindowWidth);
    
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
      // Close the text box
      close();
    }
  }
  
  static void renderConversationWindow() {
    // Text window
    Gui.renderWindow(4, 11, conversationWindowWidth, 4);
    
    // Picture window
    Gui.renderWindow(1, 11, 3, 3);
    
    // Picture
    for(int row=0; row<3; row++) {
      for(int col=0; col<3; col++) {
        new Sprite.int(Gui.pictureSpriteId + 32*row + col, 1 + col, 11 + row).renderStatic();
      }
    }
    
    // Text
    for(int i=0; i<textLines.length && i<maxLines; i++) {
      Font.renderStaticText(textX, textY + Gui.verticalLineSpacing*i, textLines[i]);
    }
    
    if(textLines.length > maxLines) {
      // draw arrow indicating there is more text
      Font.renderStaticText(36.25, 28.5, new String.fromCharCode(127));
    }
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(Input.CONFIRM) || keyCodes.contains(Input.BACK)) {
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