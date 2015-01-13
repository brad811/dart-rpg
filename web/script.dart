import 'dart:html';
import 'dart:async';

var canvasWidth = 640,
  canvasHeight = 512;

ImageElement spritesImage;
CanvasElement c;
var ctx;

World world;
Player player;

void main() {
  c = querySelector('canvas');
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

  document.onKeyDown.listen((KeyboardEvent e) {
    if (!Input.keys.contains(e.keyCode))
      Input.keys.add(e.keyCode);
  });
  
  document.onKeyUp.listen((KeyboardEvent e) {
    Input.keys.remove(e.keyCode);
  });
  
  tick();
}

void tick() {
  world.render();
  player.render();
  
  Input.handleKey();
  
  player.tick();
  
  new Timer(new Duration(milliseconds: 33), () => tick());
}

class Tile {
  static final int GROUND = 67,
      WALL = 68,
      PLAYER = 129;
  
  final int type;
  final bool solid;
  
  Tile(int type, bool solid)
    : this.type = type,
      this.solid = solid;
}

var tiles = new List<Tile>();

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

class Input {
  static var keys = [];
  
  static void handleKey() {
    if(keys.length == 0)
      return;
    
    switch(keys[0]) {
      case KeyCode.LEFT:
      case KeyCode.RIGHT:
      case KeyCode.UP:
      case KeyCode.DOWN:
        player.move(keys[0]);
        break;
    }
  }
}

class Player {
  static final
    DOWN = 0,
    RIGHT = 1,
    UP = 2,
    LEFT = 3,
    motionAmount = Sprite.pixelsPerSprite * Sprite.spriteScale;
  
  static var 
    motionX = 0,
    motionY = 0,
    motionSpeed = 4,
    direction = DOWN,
    mapX = 8,
    mapY = 5,
    x = mapX * motionAmount,
    y = mapY * motionAmount;

  void render() {
    Sprite.render(Tile.PLAYER + direction, 1, 2, x/motionAmount, (y/motionAmount)-1);
  }
  
  void move(motionDirection) {
    if(motionX == 0 && motionY == 0) {
      if(motionDirection == KeyCode.LEFT) {
        direction = LEFT;
        motionX = -motionAmount;
      } else if(motionDirection == KeyCode.RIGHT) {
        direction = RIGHT;
        motionX = motionAmount;
      } else if(motionDirection == KeyCode.UP) {
        direction = UP;
        motionY = -motionAmount;
      } else if(motionDirection == KeyCode.DOWN) {
        direction = DOWN;
        motionY = motionAmount;
      }
    }
  }
  
  void tick() {
    if(motionX < 0) {
      motionX += motionSpeed;
      if(!world.map[mapY][mapX-1].solid) {
        x -= motionSpeed;
        
        if(motionX == 0)
          mapX -= 1;
      }
    }
    else if(motionX > 0) {
      motionX -= motionSpeed;
      if(!world.map[mapY][mapX+1].solid) {
        x += motionSpeed;
        
        if(motionX == 0)
          mapX += 1;
      }
    }
    else if(motionY < 0) {
      motionY += motionSpeed;
      if(!world.map[mapY-1][mapX].solid) {
        y -= motionSpeed;
        
        if(motionY == 0)
          mapY -= 1;
      }
    }
    else if(motionY > 0) {
      motionY -= motionSpeed;
      if(!world.map[mapY+1][mapX].solid) {
        y += motionSpeed;
        
        if(motionY == 0)
          mapY += 1;
      }
    }
  }
}

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

  void render() {
    for(var y=0; y<map.length; y++) {
      for(var x=0; x<map[y].length; x++) {
        Sprite.render(map[y][x].type, 1, 1, x, y);
      }
    }
  }
}
