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

class Input {
  static var keys = [];
  
  static void handleKey() {
    if(keys.length == 0)
      return;
    
    switch(keys[0]) {
      case KeyCode.LEFT:
        player.move(keys[0]);
        break;
      case KeyCode.RIGHT:
        player.move(keys[0]);
        break;
      case KeyCode.UP:
        player.move(keys[0]);
        break;
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
    x = 8 * motionAmount,
    y = 5 * motionAmount;

  void render() {
    Sprite.render(Tiles.PLAYER + direction, 1, 2, x/motionAmount, (y-1)/motionAmount);
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
      x -= motionSpeed;
    }
    else if(motionX > 0) {
      motionX -= motionSpeed;
      x += motionSpeed;
    }
    else if(motionY < 0) {
      motionY += motionSpeed;
      y -= motionSpeed;
    }
    else if(motionY > 0) {
      motionY -= motionSpeed;
      y += motionSpeed;
    }
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
