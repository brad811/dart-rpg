library Sprite;

import 'dart:html';

import 'player.dart';

class Sprite {
  static final int
    LAYER_GROUND = 0,
    LAYER_BELOW = 1,
    LAYER_PLAYER = 2,
    LAYER_ABOVE = 3;
  
  static final int
    pixelsPerSprite = 16,
    spriteSheetSize = 32,
    spriteScale = 2,
    scaledSpriteSize = pixelsPerSprite*spriteScale;
  
  int id, sizeX, sizeY;
  double posX, posY;
  
  Sprite(this.id, this.sizeX, this.sizeY, this.posX, this.posY);
  
  Sprite.int(this.id, this.sizeX, this.sizeY, int posX, int posY) {
    this.posX = posX.toDouble();
    this.posY = posY.toDouble();
  }
  
  void render(CanvasRenderingContext2D ctx, ImageElement spritesImage, int canvasWidth, int canvasHeight) {
    ctx.drawImageScaledFromSource(
      spritesImage,
      
      pixelsPerSprite * (id%spriteSheetSize - 1), // sx
      pixelsPerSprite * (id/spriteSheetSize).floor(), // sy
      
      sizeX*pixelsPerSprite, sizeY*pixelsPerSprite, // swidth, sheight
      
      posX*scaledSpriteSize - Player.x + canvasWidth/2 - scaledSpriteSize, // x
      posY*scaledSpriteSize - Player.y + canvasHeight/2, // y
      
      sizeX*pixelsPerSprite*spriteScale, sizeY*pixelsPerSprite*spriteScale // width, height
    );
  }
}