library TextGameEvent;

import 'dart:html';

import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';

class TextGameEvent extends GameEvent {
  int pictureSpriteId;
  String text;
  
  List<String>
      originalTextLines = [],
      textLines = [];
  
  TextGameEvent(this.pictureSpriteId, this.text, var callback) : super(callback) {
    List<String> tokens = text.split(" ");
    int lineNumber = 0;
    String curLine;
    
    // Split the text into lines of proper length
    while(tokens.length > 0) {
      curLine = "";
      while(tokens.length > 0 && curLine.length + tokens[0].length < 35) {
        if(curLine.length > 0) {
          curLine += " ";
        }
        curLine += tokens[0];
        tokens.removeAt(0);
      }
      originalTextLines.add(curLine);
      lineNumber++;
    }
    
    textLines = new List<String>.from(originalTextLines);
  }
  
  void interact() {
    // Take input focus and show the GUI window
    Gui.inConversation = true;
    Gui.textLines = textLines;
    Gui.pictureSpriteId = pictureSpriteId;
  }
  
  void continueText() {
    if(textLines.length > Gui.maxLines) {
      // Remove the top lines so the next lines will show
      textLines.removeRange(0, Gui.maxLines);
    } else {
      // Close the text box and reset the text
      close();
      textLines = new List<String>.from(originalTextLines);
    }
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(KeyCode.X)) {
      continueText();
    }
  }
  
  void close() {
    // Set focus back on the player and hide the GUI window
    Gui.inConversation = false;
    callback();
  }
}