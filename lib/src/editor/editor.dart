library Editor;

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
  
  static int
    canvasWidth = 100,
    canvasHeight = 100;
  
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
    
    for(int y=0; y<10; y++) {
      Main.world.map.add([]);
      for(int x=0; x<10; x++) {
        Main.world.map[y].add([]);
        for(int i=0; i<World.layers.length; i++) {
          Main.world.map[y][x].add(null);
        }
      }
    }
    
    for(int y=0; y<10; y++) {
      for(int x=0; x<10; x++) {
        Main.world.map[y][x][World.LAYER_GROUND] = new Tile(
          false,
          new Sprite.int(Tile.GROUND, x, y)
        );
      }
    }
    
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
    
    c.onClick.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      
      if(y >= Main.world.map.length || x >= Main.world.map[0].length)
        return;
      
      Main.world.map[y][x][World.LAYER_GROUND] = new Tile(
        false,
        new Sprite.int(selectedTile, x, y)
      );
      updateMap();
    });
    
    sc.onClick.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      selectSprite(y*Sprite.spriteSheetSize + x + 1);
    });
    
    updateMap();
  }
  
  static void updateMap() {
    canvasHeight = Main.world.map.length * Sprite.scaledSpriteSize;
    canvasWidth = Main.world.map[0].length * Sprite.scaledSpriteSize;
    
    c.width = canvasWidth;
    c.height = canvasHeight;
    
    ctx.imageSmoothingEnabled = false;
    
    // Draw pink background
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    renderList = [];
    for(int i=0; i<World.layers.length; i++) {
      renderList.add([]);
    }
    
    renderWorld(renderList);
    
    for(Character character in Main.world.characters) {
      character.render(renderList);
    }
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        renderStaticSprite(
          ctx, tile.sprite.id,
          tile.sprite.posX.round(), tile.sprite.posY.round()
        );
      }
    }
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
  
  static void renderWorld(List<List<Tile>> renderList) {
    for(var y=0; y<Main.world.map.length; y++) {
      for(var x=0; x<Main.world.map[y].length; x++) {
        for(int layer in World.layers) {
          if(Main.world.map[y][x][layer] is Tile) {
            renderList[layer].add(
              Main.world.map[y][x][layer]
            );
          }
        }
      }
    }
  }
}