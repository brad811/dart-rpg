library World;

import 'dart:html';

import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class World {
  static final int
    LAYER_GROUND = 0,
    LAYER_BELOW = 1,
    LAYER_PLAYER = 2,
    LAYER_ABOVE = 3;
  
  static final List<int> layers = [
    LAYER_GROUND,
    LAYER_BELOW,
    LAYER_PLAYER,
    LAYER_ABOVE
  ];
  
  List<List<List<Tile>>> map = [];
  
  World() {
    int xSize = (Main.canvasWidth/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
    int ySize = (Main.canvasHeight/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
    for(var y=0; y<ySize; y++) {
      map.add([]);
      for(var x=0; x<xSize; x++) {
        // TODO: I'd like to have this be like: map[y].add( [ new List(layers.length) ] );
        map[y].add( [ [], [], [], [] ] );
        if(y == 0 || y == 15 || x == 0 || x == 19) {
          map[y][x][LAYER_GROUND] = new Tile(
            true,
            new Sprite.int(Tile.WALL, x, y)
          );
        } else {
          map[y][x][LAYER_GROUND] = new Tile(
            false,
            new Sprite.int(Tile.GROUND, x, y)
          );
        }
      }
    }
    
    addObject(
      Tile.HOUSE,
      10, 6, LAYER_ABOVE,
      6, 2,
      false
    );
    
    addObject(
      Tile.HOUSE + 64,
      10, 8, LAYER_BELOW,
      6, 3,
      true
    );
    
    addInteractableObject(
      Tile.SIGN,
      9, 10, LAYER_BELOW,
      1, 1,
      true,
      (int keyCode) {
        if(keyCode == KeyCode.X || keyCode == KeyCode.Z) {
          return InteractableTile.ACTION_CLOSE;
        }
      }
    );
  }
  
  void addInteractableObject(
      int spriteId, int posX, int posY, int layer, int sizeX, int sizeY, bool solid,
      void handler(int keyCode)) {
    for(var y=0; y<sizeY; y++) {
      for(var x=0; x<sizeX; x++) {
        map[posY+y][posX+x][layer] = new InteractableTile(
          solid,
          new Sprite.int(
            spriteId + x + (y*Sprite.spriteSheetSize),
            posX+x, posY+y
          ),
          handler
        );
      }
    }
  }
  
  void addObject(int spriteId, int posX, int posY, int layer, int sizeX, int sizeY, bool solid) {
    for(var y=0; y<sizeY; y++) {
      for(var x=0; x<sizeX; x++) {
        map[posY+y][posX+x][layer] = new Tile(
          solid,
          new Sprite.int(
            spriteId + x + (y*Sprite.spriteSheetSize),
            posX+x, posY+y
          )
        );
      }
    }
  }
  
  bool isSolid(int x, int y) {
    for(int layer in layers) {
      if(map[y][x][layer] is Tile && map[y][x][layer].solid) {
        return true;
      }
    }
    
    return false;
  }
  
  bool isInteractable(int x, int y) {
    for(int layer in layers) {
      if(map[y][x][layer] is InteractableTile) {
        return true;
      }
    }
    
    return false;
  }
  
  void interact(int x, int y) {
    for(int layer in layers) {
      if(map[y][x][layer] is InteractableTile) {
        InteractableTile tile = map[y][x][layer] as InteractableTile;
        tile.interact();
        return;
      }
    }
  }

  void render(List<List<Tile>> renderList) {
    for(var y=0; y<map.length; y++) {
      for(var x=0; x<map[y].length; x++) {
        for(int layer in layers) {
          if(map[y][x][layer] is Tile) {
            renderList[layer].add(
              map[y][x][layer]
            );
          }
        }
      }
    }
  }
}