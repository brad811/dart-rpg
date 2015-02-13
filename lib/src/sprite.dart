library Sprite;

import 'package:dart_rpg/src/main.dart';

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
  
  void render() {
    Main.ctx.drawImageScaledFromSource(
      Main.spritesImage,
      
      pixelsPerSprite * (id%spriteSheetSize), // sx
      pixelsPerSprite * (id/spriteSheetSize).floor(), // sy
      
      pixelsPerSprite, pixelsPerSprite, // swidth, sheight
      
      posX*scaledSpriteSize - Main.player.x + Main.canvasWidth/2 - scaledSpriteSize, // x
      posY*scaledSpriteSize - Main.player.y + Main.canvasHeight/2, // y
      
      scaledSpriteSize, scaledSpriteSize // width, height
    );
  }
  
  void renderStatic() {
    Main.ctx.drawImageScaledFromSource(
      Main.spritesImage,
      
      pixelsPerSprite * (id%spriteSheetSize), // sx
      pixelsPerSprite * (id/spriteSheetSize).floor(), // sy
      
      pixelsPerSprite, pixelsPerSprite, // swidth, sheight
      
      posX*scaledSpriteSize, // x
      posY*scaledSpriteSize, // y
      
      scaledSpriteSize, scaledSpriteSize // width, height
    );
  }
  
  void renderStaticSized(int sizeX, int sizeY) {
    int originalId = id;
    double originalPosX = posX;
    double originalPosY = posY;
    
    for(int j=0; j<sizeY; j++) {
      posX = originalPosX;
      for(int i=0; i<sizeX; i++) {
        id = originalId + (j*spriteSheetSize) + i;
        renderStatic();
        posX++;
      }
      posY++;
    }
    
    id = originalId;
    posX = originalPosX;
    posY = originalPosY;
  }
}