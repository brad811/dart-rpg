library Editor;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Editor {
  static ImageElement spritesImage;
  static CanvasElement c, sc, ssc;
  static CanvasRenderingContext2D ctx, sctx, ssctx;
  
  static List<List<Tile>> renderList;
  static int selectedTile;
  
  static void init() {
    c = querySelector('#editor_main_canvas');
    ctx = c.getContext("2d");
    ctx.imageSmoothingEnabled = false;
    
    sc = querySelector('#editor_sprite_canvas');
    sctx = sc.getContext("2d");
    sctx.imageSmoothingEnabled = false;
    
    ssc = querySelector('#editor_selected_sprite_canvas');
    ssctx = ssc.getContext("2d");
    ssctx.imageSmoothingEnabled = false;
    
    spritesImage = new ImageElement(src: "sprite_sheet.png");
    spritesImage.onLoad.listen((e) {
        start();
    });
  }
  
  static void start() {
    Main.player = new Player(0, 0);
    
    Main.world = new World();
    Main.world.map = [];
    Main.world.characters = [];
    
    sctx.fillStyle = "#ff00ff";
    sctx.fillRect(
      0, 0,
      Sprite.scaledSpriteSize*Sprite.spriteSheetSize,
      Sprite.scaledSpriteSize*Sprite.spriteSheetSize
    );
    
    // render sprite picker
    int
      maxCol = 32,
      col = 0,
      row = 0;
    for(int y=0; y<Sprite.spriteSheetSize; y++) {
      for(int x=0; x<Sprite.spriteSheetSize; x++) {
        renderStaticSprite(sctx, y*Sprite.spriteSheetSize + (x+1), col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    selectSprite(Tile.GROUND);
    
    sc.onClick.listen((MouseEvent e) {
      //selectSprite();
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      selectSprite(y*Sprite.spriteSheetSize + x + 1);
    });
    
    tick();
  }
  
  static void tick() {
    // Draw pink background
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, Main.canvasWidth, Main.canvasHeight);
    
    renderList = [];
    for(int i=0; i<World.layers.length; i++) {
      renderList.add([]);
    }
    
    Main.world.render(renderList);
    
    for(Character character in Main.world.characters) {
      character.render(renderList);
    }
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        tile.render();
      }
    }

    new Timer(new Duration(milliseconds: Main.timeDelay), () => tick());
  }
  
  static void selectSprite(int id) {
    selectedTile = id;
    ssctx.fillStyle = "#ff00ff";
    ssctx.fillRect(0, 0, 32, 32);
    renderStaticSprite(ssctx, id, 0, 0);
  }
  
  static void renderStaticSprite(CanvasRenderingContext2D ctx, int id, int posX, int posY) {
    ctx.drawImageScaledFromSource(
      spritesImage,
      
      Sprite.pixelsPerSprite * (id%Sprite.spriteSheetSize - 1), // sx
      Sprite.pixelsPerSprite * (id/Sprite.spriteSheetSize).floor(), // sy
      
      Sprite.pixelsPerSprite, Sprite.pixelsPerSprite, // swidth, sheight
      
      posX*Sprite.scaledSpriteSize, // x
      posY*Sprite.scaledSpriteSize, // y
      
      Sprite.scaledSpriteSize, Sprite.scaledSpriteSize // width, height
    );
  }
}