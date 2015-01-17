import 'dart:html';
import 'dart:async';

import 'src/input.dart';
import 'src/player.dart';
import 'src/sprite.dart';
import 'src/tile.dart';
import 'src/world.dart';

int canvasWidth = 640,
  canvasHeight = 512;

ImageElement spritesImage;
CanvasElement c;
CanvasRenderingContext2D ctx;

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
  
  List<List<Sprite>> renderList = [ [], [], [], [] ];
  
  world.render(renderList);
  
  renderList[Sprite.LAYER_ABOVE].add(
    new Sprite.int(
      Tile.HOUSE,
      6, 2,
      10, 6
    )
  );
  
  renderList[Sprite.LAYER_BELOW].add(
    new Sprite.int(
      Tile.HOUSE + 64,
      6, 3,
      10, 8
    )
  );
  
  player.render(renderList);
  
  for(var layer in renderList) {
    for(Sprite sprite in layer) {
      sprite.render(ctx, spritesImage, canvasWidth, canvasHeight);
    }
  }
  
  Input.handleKey(player);
  
  player.tick(world);
  
  new Timer(new Duration(milliseconds: 33), () => tick());
}

class WorldObject {
  
}

var tiles = new List<Tile>();


