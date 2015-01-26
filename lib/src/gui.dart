library Gui;

import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class Gui {
  static final int
    // sprite IDs for the window frame
    WINDOW_TOP_LEFT = 232,
    WINDOW_TOP_MIDDLE = 233,
    WINDOW_TOP_RIGHT = 234,
    WINDOW_MIDDLE_LEFT = 264,
    WINDOW_MIDDLE_MIDDLE = 265,
    WINDOW_MIDDLE_RIGHT = 266,
    WINDOW_BOTTOM_LEFT = 296,
    WINDOW_BOTTOM_MIDDLE = 297,
    WINDOW_BOTTOM_RIGHT = 298,
    
    charsPerLine = 35,
    maxLines = 4;
  
  static final double
    textX = 9.75,
    textY = 23.5,
    verticalLineSpacing = 1.5;
  
  static List<List<List<Sprite>>> screen;
  static bool inConversation = false;
  static List<String> textLines = [];
  static int pictureSpriteId;
  
  static final int
    FADE_WHITE_FULL = 3,
    FADE_WHITE_MED = 2,
    FADE_WHITE_LOW = 1,
    FADE_NORMAL = 0,
    FADE_BLACK_LOW = -1,
    FADE_BLACK_MED = -2,
    FADE_BLACK_FULL = -3;
  
  static int fadeOutLevel = FADE_NORMAL;
  
  static void render() {
    if(inConversation) {
      renderConversationWindow();
    }
    if(fadeOutLevel != FADE_NORMAL) {
      renderFade();
    }
  }
  
  static void renderFade() {
    ImageData imageData = Main.ctx.getImageData(0, 0, Main.canvasWidth, Main.canvasHeight);
    
    for(int y=0; y<Main.canvasHeight; y++) {
      int pos = y*Main.canvasWidth*4;
      for(int x=0; x<Main.canvasWidth; x++) {
        int value = imageData.data[pos];
        imageData.data[pos] = math.min(255, math.max(0, value + 85*fadeOutLevel));
        imageData.data[pos+1] = math.min(255, math.max(0, value + 85*fadeOutLevel));
        imageData.data[pos+2] = math.min(255, math.max(0, value + 85*fadeOutLevel));
        pos += 4;
      }
    }
    
    Main.ctx.putImageData(imageData, 0, 0);
  }
  
  static void renderConversationWindow() {
    // Text window
    Gui.renderWindow(4, 11, 15, 4);
    
    // Picture window
    Gui.renderWindow(1, 11, 3, 3);
    
    // Picture
    for(int row=0; row<3; row++) {
      for(int col=0; col<3; col++) {
        new Sprite.int(pictureSpriteId + 32*row + col, 1 + col, 11 + row).renderStatic();
      }
    }
    
    // Text
    for(int i=0; i<textLines.length && i<maxLines; i++) {
      Font.renderStaticText(textX, textY + verticalLineSpacing*i, textLines[i]);
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