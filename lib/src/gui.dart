library dart_rpg.gui;

import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/game_event/delayed_game_event.dart';
import 'package:dart_rpg/src/gui_start_menu.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

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
    verticalLineSpacing = 1.5;
  
  static List<List<List<Sprite>>> screen;
  static bool inConversation = false;
  static List<String> textLines = [];
  static int pictureSpriteId;
  
  static List<Function> _windows = [];
  
  static int fadeOutLevel = FADE_NORMAL;
  
  static void render() {
    if(inConversation) {
      TextGameEvent.renderConversationWindow();
    }
    
    if(fadeOutLevel != FADE_NORMAL) {
      renderFade();
    }
    
    for(Function window in _windows) {
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
  
  // fade to black and then back to normal, and then perform an action
  static void fadeDarkAction(Function action, [Function callback]) {
    List<int> fadeLevels = [
      FADE_BLACK_LOW,
      FADE_BLACK_MED,
      FADE_BLACK_FULL,
      FADE_BLACK_MED,
      FADE_BLACK_LOW,
      FADE_NORMAL
    ];
    fullFadeAction(fadeLevels, action, callback);
  }
  
  // fade to white and then back to normal, and then perform an action
  static void fadeLightAction(Function action, [Function callback]) {
    List<int> fadeLevels = [
      FADE_WHITE_LOW,
      FADE_WHITE_MED,
      FADE_WHITE_FULL,
      FADE_WHITE_MED,
      FADE_WHITE_LOW,
      FADE_NORMAL
    ];
    fullFadeAction(fadeLevels, action, callback);
  }
  
  static void fullFadeAction(List<int> fadeLevels, Function action, [Function callback]) {
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
  
  static List<String> splitText(String text, int w) {
    // find out how many characters will fit on each line in this window
    int charsPerLine = ((w - 1) * (8 / 3)).floor();
    
    List<String> textLines = new List<String>();
    List<String> tokens = text.split(" ");
    String curLine;
    
    // Split the text into lines of proper length
    while(tokens.length > 0) {
      curLine = "";
      
      while(tokens.length > 0 && curLine.length + tokens[0].length < charsPerLine) {
        if(curLine.length > 0)
          curLine += " ";
        
        curLine += tokens[0];
        tokens.removeAt(0);
      }
      
      textLines.add(curLine);
    }
    
    return textLines;
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
    GuiStartMenu.start.trigger(Main.player);
  }
  
  static void addWindow(Function window) {
    _windows.add(window);
  }
  
  static void removeWindow(Function window) {
    _windows.remove(window);
  }
  
  static void clear() {
    _windows = [];
    inConversation = false;
  }
}