library Sprite;

import 'dart:html';

import 'package:dart_rpg/src/player.dart';

class Sprite {
  static final int
    pixelsPerSprite = 16,
    spriteSheetSize = 32,
    spriteScale = 2,
    scaledSpriteSize = pixelsPerSprite*spriteScale;
  
  int id;
  double posX, posY;
  
  Sprite(this.id, this.posX, this.posY);
  
  Sprite.int(this.id, int posX, int posY) {
    this.posX = posX.toDouble();
    this.posY = posY.toDouble();
  }
  
  void render(CanvasRenderingContext2D ctx, ImageElement spritesImage, int canvasWidth, int canvasHeight) {
    ctx.drawImageScaledFromSource(
      spritesImage,
      
      pixelsPerSprite * (id%spriteSheetSize - 1), // sx
      pixelsPerSprite * (id/spriteSheetSize).floor(), // sy
      
      pixelsPerSprite, pixelsPerSprite, // swidth, sheight
      
      posX*scaledSpriteSize - Player.x + canvasWidth/2 - scaledSpriteSize, // x
      posY*scaledSpriteSize - Player.y + canvasHeight/2, // y
      
      pixelsPerSprite*spriteScale, pixelsPerSprite*spriteScale // width, height
    );
  }
}