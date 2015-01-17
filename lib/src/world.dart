library World;

import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class World {
  static final int
    LAYER_GROUND = 0,
    LAYER_BELOW = 1,
    LAYER_PLAYER = 2,
    LAYER_ABOVE = 3;
  
  List<int> layers = [
    LAYER_GROUND,
    LAYER_BELOW,
    LAYER_PLAYER,
    LAYER_ABOVE
  ];
  
  List<List<List<Tile>>> map = [];
  
  World() {
    for(var y=0; y<16; y++) {
      map.add([]);
      for(var x=0; x<20; x++) {
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
      Tile.HOUSE + 128 + 1,
      11, 10, LAYER_BELOW,
      1, 1,
      true
    );
  }
  
  void addInteractableObject(
      int spriteId, int posX, int posY, int layer, int sizeX, int sizeY, bool solid) {
    for(var y=0; y<sizeY; y++) {
      for(var x=0; x<sizeX; x++) {
        map[posY+y][posX+x][layer] = new InteractableTile(
          solid,
          new Sprite.int(
            spriteId + x + (y*Sprite.spriteSheetSize),
            posX+x, posY+y
          )
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