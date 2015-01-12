import 'dart:html';

var canvasWidth = 640,
  canvasHeight = 512;

ImageElement spritesImage;
var ctx;

World world;
Player player;

void main() {
  CanvasElement c = querySelector('canvas');
  ctx = c.getContext("2d");
  ctx.imageSmoothingEnabled = false;
  
  spritesImage = new ImageElement(src: "sprite_sheet.png");
  spritesImage.onLoad.listen((e) {
      start();
  });
  
  ctx.fillStyle = "#333333";
  ctx.fillRect(0, 0, canvasWidth, canvasHeight);
}

void start() {
  world = new World();
  player = new Player();
  
  tick();
}

void tick() {
  world.render();
  player.render();
  
  //var timer = new Timer(new Duration(milliseconds: 33), () => print('done'));
}

class Tiles {
  static final GROUND = 67,
    WALL = 68,
    PLAYER = 129;
}

class Sprite {
  static final pixelsPerSprite = 16,
    spriteSheetSize = 32,
    spriteScale = 2;
  
  static void render(id, sizeX, sizeY, posX, posY) {
    sizeX *= Sprite.pixelsPerSprite;
    sizeY *= Sprite.pixelsPerSprite;
  
    var spriteX = Sprite.pixelsPerSprite * (id%Sprite.spriteSheetSize - 1);
    var spriteY = Sprite.pixelsPerSprite * (id/Sprite.spriteSheetSize).floor();
  
    ctx.drawImageScaledFromSource(
      spritesImage,
      spriteX, spriteY, // sx, sy
      sizeX, sizeY, // swidth, sheight
      posX*Sprite.pixelsPerSprite*Sprite.spriteScale, posY*Sprite.pixelsPerSprite*Sprite.spriteScale, // x, y
      sizeX*Sprite.spriteScale, sizeY*Sprite.spriteScale // width, height
    );
  }
}

class Player {
  var x = 8,
    y = 5;

  void render() {
    Sprite.render(Tiles.PLAYER, 1, 2, x, y-1);
  }
}

class World {
  List<List<int>> map = [];
  
  World() {
    map.add([]);
    for(var i=0; i<20; i++) {
      map[0].add(Tiles.WALL);
    }
  
    for(var i=1; i<15; i++) {
      map.add([]);
      map[i].add(Tiles.WALL);
      for(var j=0; j<18; j++) {
        map[i].add(Tiles.GROUND);
      }
      map[i].add(Tiles.WALL);
    }
  
    map.add([]);
    for(var i=0; i<20; i++) {
      map[15].add(Tiles.WALL);
    }
  }

  void render() {
    for(var y=0; y<map.length; y++) {
      for(var x=0; x<map[y].length; x++) {
        Sprite.render(map[y][x], 1, 1, x, y);
      }
    }
  }
}
