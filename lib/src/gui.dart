library Gui;

import 'dart:html';

import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

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
      BOTTOM_RIGHT = 298;
  List<List<List<Tile>>> map = [];
  
  static renderWindow(
      CanvasRenderingContext2D ctx, ImageElement spritesImage, int canvasWidth, int canvasHeight,
      int posX, int posY, int sizeX, int sizeY) {
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
        window.renderStatic(ctx, spritesImage, canvasWidth, canvasHeight);
      }
    }
  }
}