library Font;

import 'dart:html';

import 'package:dart_rpg/src/sprite.dart';

class Font {
  static final int
    startId = 1664,
    fontSheetWidth = 16,
    pixelsPerFontSprite = 8,
    scaledSpriteSize = pixelsPerFontSprite*Sprite.spriteScale;
  
  static void renderStaticText(
      CanvasRenderingContext2D ctx, ImageElement spritesImage, int canvasWidth, int canvasHeight,
      double posX, double posY, String text) {
    for(int i=0; i<text.length; i++) {
      renderStatic(ctx, spritesImage, canvasWidth, canvasHeight, text.codeUnits[i], posX + i*(6/8), posY - 0.25);
    }
  }
  
  static void renderStatic(
      CanvasRenderingContext2D ctx, ImageElement spritesImage, int canvasWidth, int canvasHeight,
      int id, double posX, double posY) {
    
    num fontId = startId + ((id/fontSheetWidth).floor()*Sprite.spriteSheetSize) + (id%fontSheetWidth);
    
    ctx.drawImageScaledFromSource(
      spritesImage,
      
      pixelsPerFontSprite * (fontId%Sprite.spriteSheetSize), // sx
      pixelsPerFontSprite * (fontId/Sprite.spriteSheetSize).round(), // sy
      
      pixelsPerFontSprite, pixelsPerFontSprite, // swidth, sheight
      
      posX*scaledSpriteSize, // x
      posY*scaledSpriteSize, // y
      
      scaledSpriteSize, scaledSpriteSize // width, height
    );
  }
}
