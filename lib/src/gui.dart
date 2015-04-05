library dart_rpg.gui;

import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/delayed_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/gui_start_menu.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class Gui {
  static final int
    // sprite IDs for the window frame
    WINDOW_TOP_LEFT = 231,
    WINDOW_TOP_MIDDLE = 232,
    WINDOW_TOP_RIGHT = 233,
    WINDOW_MIDDLE_LEFT = 263,
    WINDOW_MIDDLE_MIDDLE = 264,
    WINDOW_MIDDLE_RIGHT = 265,
    WINDOW_BOTTOM_LEFT = 295,
    WINDOW_BOTTOM_MIDDLE = 296,
    WINDOW_BOTTOM_RIGHT = 297,
    
    FADE_WHITE_FULL = 3,
    FADE_WHITE_MED = 2,
    FADE_WHITE_LOW = 1,
    FADE_NORMAL = 0,
    FADE_BLACK_LOW = -1,
    FADE_BLACK_MED = -2,
    FADE_BLACK_FULL = -3,
    
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
  
  static List<Function> windows = [];
  
  static int fadeOutLevel = FADE_NORMAL;
  
  static void render() {
    if(inConversation) {
      renderConversationWindow();
    }
    
    if(fadeOutLevel != FADE_NORMAL) {
      renderFade();
    }
    
    for(Function window in windows) {
      window();
    }
  }
  
  static void renderFade() {
    int
      scaledWidth = (Main.canvasWidth * window.devicePixelRatio).round(),
      scaledHeight = (Main.canvasHeight * window.devicePixelRatio).round();
    
    ImageData imageData = Main.ctx.getImageData(0, 0, scaledWidth, scaledHeight);
    
    for(int y=0; y<scaledHeight; y++) {
      int pos = y*scaledWidth*4;
      for(int x=0; x<scaledWidth; x++) {
        int value = imageData.data[pos];
        imageData.data[pos] = math.min(255, math.max(0, value + 85*fadeOutLevel));
        imageData.data[pos+1] = math.min(255, math.max(0, value + 85*fadeOutLevel));
        imageData.data[pos+2] = math.min(255, math.max(0, value + 85*fadeOutLevel));
        pos += 4;
      }
    }
    
    Main.ctx.putImageData(imageData, 0, 0);
  }
  
  static void fadeDarkAction(Function action, [Function callback]) {
    List<int> fadeLevels = [
      FADE_BLACK_LOW,
      FADE_BLACK_MED,
      FADE_BLACK_FULL,
      FADE_BLACK_MED,
      FADE_BLACK_LOW,
      FADE_NORMAL
    ];
    fadeAction(fadeLevels, action, callback);
  }
  
  static void fadeLightAction(Function action, [Function callback]) {
    List<int> fadeLevels = [
      FADE_WHITE_LOW,
      FADE_WHITE_MED,
      FADE_WHITE_FULL,
      FADE_WHITE_MED,
      FADE_WHITE_LOW,
      FADE_NORMAL
    ];
    fadeAction(fadeLevels, action, callback);
  }
  
  static void fadeAction(List<int> fadeLevels, Function action, [Function callback]) {
    Main.timeScale = 0.0;
    fadeOutLevel = fadeLevels[0];
    
    DelayedGameEvent.executeDelayedEvents([
      new DelayedGameEvent(100, () {
        fadeOutLevel = fadeLevels[1];
      }),
      
      new DelayedGameEvent(100, () {
        fadeOutLevel = fadeLevels[2];
        action();
      }),
      
      new DelayedGameEvent(100, () {
        fadeOutLevel = fadeLevels[3];
      }),
      
      new DelayedGameEvent(100, () {
        fadeOutLevel = fadeLevels[4];
      }),
      
      new DelayedGameEvent(100, () {
        fadeOutLevel = fadeLevels[5];
        Main.timeScale = 1.0;
        
        if(callback != null)
          callback();
      })
    ]);
  }
  
  // TODO: allow rendering custom text window
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
    
    if(textLines.length > maxLines) {
      // draw arrow indicating there is more text
      Font.renderStaticText(36.25, 28.5, new String.fromCharCode(127));
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
  
  static void showStartMenu() {
    GuiStartMenu.start.trigger();
  }
}