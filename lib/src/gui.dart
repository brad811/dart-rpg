library Gui;

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/sprite.dart';

class Gui {
  static final int
      WINDOW_TOP_LEFT = 232,
      WINDOW_TOP_MIDDLE = 233,
      WINDOW_TOP_RIGHT = 234,
      WINDOW_MIDDLE_LEFT = 264,
      WINDOW_MIDDLE_MIDDLE = 265,
      WINDOW_MIDDLE_RIGHT = 266,
      WINDOW_BOTTOM_LEFT = 296,
      WINDOW_BOTTOM_MIDDLE = 297,
      WINDOW_BOTTOM_RIGHT = 298,
      
      charsPerLine = 35;
  
  static final double
    textX = 9.75,
    textY = 23.5,
    verticalLineSpacing = 1.5;
  
  static List<List<List<Sprite>>> screen;
  static bool inConversation = false;
  static String text = "";
  
  static void render() {
    if(inConversation) {
      renderConversationWindow();
    }
  }
  
  static void renderConversationWindow() {
    // Text window
    Gui.renderWindow(4, 11, 15, 4);
    
    // Picture window
    Gui.renderWindow(1, 11, 3, 3);
    
    // Picture
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
            id = WINDOW_TOP_LEFT;
          else if(i == posX + sizeX - 1)
            id = WINDOW_TOP_RIGHT;
          else
            id = WINDOW_TOP_MIDDLE;
        }
        else if(j == posY + sizeY - 1) {
          if(i == posX)
            id = WINDOW_BOTTOM_LEFT;
          else if(i == posX + sizeX - 1)
            id = WINDOW_BOTTOM_RIGHT;
          else
            id = WINDOW_BOTTOM_MIDDLE;
        }
        else {
          if(i == posX)
            id = WINDOW_MIDDLE_LEFT;
          else if(i == posX + sizeX - 1)
            id = WINDOW_MIDDLE_RIGHT;
          else
            id = WINDOW_MIDDLE_MIDDLE;
        }
        
        Sprite window = new Sprite.int(id, i, j);
        window.renderStatic();
      }
    }
  }
}