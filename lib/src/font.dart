library dart_rpg.font;

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class Font {
  static final int
    startId = 1664,
    fontSheetWidth = 16,
    pixelsPerFontSprite = 8,
    scaledSpriteSize = pixelsPerFontSprite*Sprite.spriteScale;
  
  static void renderStaticText(double posX, double posY, String text) {
    for(int i=0; i<text.length; i++) {
      renderStatic(text.codeUnits[i], posX + i*(6/8), posY - 0.25);
    }
  }
  
  static void renderStatic(int id, double posX, double posY) {
    int fontId = startId + ((id/fontSheetWidth).floor()*Sprite.spriteSheetSize) + (id%fontSheetWidth);
    
    Main.ctx.drawImageScaledFromSource(
      Main.spritesImage,
      
      pixelsPerFontSprite * (fontId%Sprite.spriteSheetSize), // sx
      pixelsPerFontSprite * (fontId/Sprite.spriteSheetSize).round(), // sy
      
      pixelsPerFontSprite, pixelsPerFontSprite, // swidth, sheight
      
      posX*scaledSpriteSize, // x
      posY*scaledSpriteSize, // y
      
      scaledSpriteSize, scaledSpriteSize // width, height
    );
  }
}