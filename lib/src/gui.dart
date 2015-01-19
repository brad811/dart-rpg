library Gui;

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/sprite.dart';

class Gui {
  static final int
      TOP_LEFT = 232,
      TOP_MIDDLE = 233,
      TOP_RIGHT = 234,
      MIDDLE_LEFT = 264,
      MIDDLE_MIDDLE = 265,
      MIDDLE_RIGHT = 266,
      BOTTOM_LEFT = 296,
      BOTTOM_MIDDLE = 297,
      BOTTOM_RIGHT = 298,
      
      charsPerLine = 35;
  
  static final double
    textX = 9.75,
    textY = 23.5,
    verticalLineSpacing = 1.5;
  
  static void renderConversationWindow() {
    // Text window
    Gui.renderWindow(4, 11, 15, 4);
    
    // Picture window
    Gui.renderWindow(1, 11, 3, 3);
    
    new Sprite.int(235, 1, 11).renderStatic();
    new Sprite.int(236, 2, 11).renderStatic();
    new Sprite.int(237, 3, 11).renderStatic();
    new Sprite.int(267, 1, 12).renderStatic();
    new Sprite.int(268, 2, 12).renderStatic();
    new Sprite.int(269, 3, 12).renderStatic();
    new Sprite.int(299, 1, 13).renderStatic();
    new Sprite.int(300, 2, 13).renderStatic();
    new Sprite.int(301, 3, 13).renderStatic();
    
    String text = "This seems to be working! This is what a full screen" +
        " of text would look like given 4 lines and ${charsPerLine} characters per line.";
    
    List<String> tokens = text.split(" ");
    int lineNumber = 0;
    String curLine;
    while(tokens.length > 0) {
      curLine = "";
      while(tokens.length > 0 && curLine.length + tokens[0].length < 35) {
        if(curLine.length > 0) {
          curLine += " ";
        }
        curLine += tokens[0];
        tokens.removeAt(0);
      }
      Font.renderStaticText(textX, textY + verticalLineSpacing*lineNumber, curLine);
      lineNumber++;
    }
  }
  
  static void renderWindow(int posX, int posY, int sizeX, int sizeY) {
    int id;
    for(int j=posY; j<posY+sizeY; j++) {
      for(int i=posX; i<posX+sizeX; i++) {
        if(j == posY) {
          if(i == posX)
            id = TOP_LEFT;
          else if(i == posX + sizeX - 1)
            id = TOP_RIGHT;
          else
            id = TOP_MIDDLE;
        }
        else if(j == posY + sizeY - 1) {
          if(i == posX)
            id = BOTTOM_LEFT;
          else if(i == posX + sizeX - 1)
            id = BOTTOM_RIGHT;
          else
            id = BOTTOM_MIDDLE;
        }
        else {
          if(i == posX)
            id = MIDDLE_LEFT;
          else if(i == posX + sizeX - 1)
            id = MIDDLE_RIGHT;
          else
            id = MIDDLE_MIDDLE;
        }
        
        Sprite window = new Sprite.int(id, i, j);
        window.renderStatic();
      }
    }
  }
}