library Sign;

import 'dart:html';

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/sprite.dart';

class Sign extends InteractableTile implements Interactable, InputHandler {
  List<String>
    originalTextLines = [],
    textLines = [];
  
  Sign(bool solid, Sprite sprite, String text) : super(solid, sprite, null) {
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
    Gui.textLines = textLines;
  }
  
  void continueText() {
    if(textLines.length > Gui.maxLines) {
      // Remove the top lines so the next lines will show
      textLines.removeRange(0, Gui.maxLines);
    } else {
      // Close the sign and reset the text
      close();
      textLines = new List<String>.from(originalTextLines);
      Gui.textLines = textLines;
    }
  }
  
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(KeyCode.X)) {
      continueText();
    }
  }
}