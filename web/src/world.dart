library World;

import 'sprite.dart';
import 'tile.dart';

class World {
  List<List<Tile>> map = [];
  
  World() {
    for(var y=0; y<16; y++) {
      map.add([]);
      for(var x=0; x<20; x++) {
        if(y == 0 || y == 15 || x == 0 || x == 19) {
          map[y].add(
            new Tile(
              true,
              new Sprite.int(Tile.WALL, 1, 1, x, y)
            )
          );
        } else {
          map[y].add(
            new Tile(
              false,
              new Sprite.int(Tile.GROUND, 1, 1, x, y)
            )
          );
        }
      }
    }
  }

  void render(List<List<Tile>> renderList) {
    for(var y=0; y<map.length; y++) {
      for(var x=0; x<map[y].length; x++) {
        renderList[Sprite.LAYER_GROUND].add(
          map[y][x]
        );
      }
    }
  }
}