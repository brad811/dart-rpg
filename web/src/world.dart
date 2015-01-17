library World;

import 'sprite.dart';
import 'tile.dart';

class World {
  List<List<Tile>> map = [];
  
  World() {
    map.add([]);
    for(var i=0; i<20; i++) {
      map[0].add(new Tile(Tile.WALL, true));
    }
  
    for(var i=1; i<15; i++) {
      map.add([]);
      map[i].add(new Tile(Tile.WALL, true));
      for(var j=0; j<18; j++) {
        map[i].add(new Tile(Tile.GROUND, false));
      }
      map[i].add(new Tile(Tile.WALL, true));
    }
  
    map.add([]);
    for(var i=0; i<20; i++) {
      map[15].add(new Tile(Tile.WALL, true));
    }
  }

  void render(List<List<Sprite>> renderList) {
    for(var y=0; y<map.length; y++) {
      for(var x=0; x<map[y].length; x++) {
        renderList[Sprite.LAYER_GROUND].add(
          new Sprite.int(map[y][x].type, 1, 1, x, y)
        );
      }
    }
  }
}