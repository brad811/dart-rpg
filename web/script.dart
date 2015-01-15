import 'dart:html';
import 'dart:async';

int canvasWidth = 640,
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
  ctx.fillStyle = "#333333";
  ctx.fillRect(0, 0, canvasWidth, canvasHeight);
  
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
  static final int pixelsPerSprite = 16,
    spriteSheetSize = 32,
    spriteScale = 2,
    scaledSpriteSize = pixelsPerSprite*spriteScale;
  
  static void render(id, sizeX, sizeY, posX, posY) {
    sizeX *= pixelsPerSprite;
    sizeY *= pixelsPerSprite;
  
    ctx.drawImageScaledFromSource(
      spritesImage,
      
      pixelsPerSprite * (id%spriteSheetSize - 1), // sx
      pixelsPerSprite * (id/spriteSheetSize).floor(), // sy
      
      sizeX, sizeY, // swidth, sheight
      
      posX*scaledSpriteSize - Player.x + canvasWidth/2 - scaledSpriteSize, // x
      posY*scaledSpriteSize - Player.y + canvasHeight/2, // y
      
      sizeX*spriteScale, sizeY*spriteScale // width, height
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
        player.move(Player.LEFT);
        break;
      case KeyCode.RIGHT:
        player.move(Player.RIGHT);
        break;
      case KeyCode.UP:
        player.move(Player.UP);
        break;
      case KeyCode.DOWN:
        player.move(Player.DOWN);
        break;
    }
  }
}

class Player {
  static final int
    DOWN = 0,
    RIGHT = 1,
    UP = 2,
    LEFT = 3,
    walkSpeed = 4,
    runSpeed = 8,
    motionAmount = Sprite.pixelsPerSprite * Sprite.spriteScale,
    directionCooldownAmount = 4;
  
  static int 
    motionX = 0,
    motionY = 0,
    direction = DOWN,
    directionCooldown = 0,
    mapX = 8,
    mapY = 5,
    curSpeed = walkSpeed,
    x = mapX * motionAmount,
    y = mapY * motionAmount,
    motionStep = 1,
    motionSpriteOffset = 0;

  void render() {
    Sprite.render(
      Tile.PLAYER + direction + motionSpriteOffset,
      1, 2,
      x/motionAmount, (y/motionAmount)-1
    );
  }
  
  void move(motionDirection) {
    // only move if we're not already moving
    if(motionX == 0 && motionY == 0) {
      // allow the player to change directions without moving
      if(direction != motionDirection) {
        direction = motionDirection;
        directionCooldown = directionCooldownAmount;
        return;
      }
      
      // don't add motion until we've finished turning
      if(directionCooldown > 0)
        return;
      
      if(motionDirection == LEFT) {
        motionX = -motionAmount;
      } else if(motionDirection == RIGHT) {
        motionX = motionAmount;
      } else if(motionDirection == UP) {
        motionY = -motionAmount;
      } else if(motionDirection == DOWN) {
        motionY = motionAmount;
      }
    }
  }
  
  void tick() {
    if(directionCooldown > 0) {
      directionCooldown -= 1;
      
      // use walk cycle sprite when turning
      if(directionCooldown >= directionCooldownAmount/2) {
        motionSpriteOffset = motionStep + 3 + direction;
      } else if(directionCooldown == 0) {
        if(motionStep == 1)
          motionStep = 2;
        else if(motionStep == 2)
          motionStep = 1;
      }
      
      return;
    }
    
    // set walk cycle sprite for first half of motion
    if(
        (motionX != 0 && (motionX).abs() > motionAmount/2)
        || (motionY != 0 && (motionY).abs() > motionAmount/2)) {
      motionSpriteOffset = motionStep + 3 + direction;
    } else {
      motionSpriteOffset = 0;
    }
    
    if(motionX < 0) {
      motionX += curSpeed;
      if(!world.map[mapY][mapX-1].solid) {
        x -= curSpeed;
        
        if(motionX == 0)
          mapX -= 1;
      }
      
      // reverse walk cycle foot
      if(motionX == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionX == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionX > 0) {
      motionX -= curSpeed;
      if(!world.map[mapY][mapX+1].solid) {
        x += curSpeed;
        
        if(motionX == 0)
          mapX += 1;
      }
      
      // reverse walk cycle foot
      if(motionX == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionX == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionY < 0) {
      motionY += curSpeed;
      if(!world.map[mapY-1][mapX].solid) {
        y -= curSpeed;
        
        if(motionY == 0)
          mapY -= 1;
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionY > 0) {
      motionY -= curSpeed;
      if(!world.map[mapY+1][mapX].solid) {
        y += curSpeed;
        
        if(motionY == 0)
          mapY += 1;
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
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
