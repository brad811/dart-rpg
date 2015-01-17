import 'dart:html';
import 'dart:async';

import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

int canvasWidth = 640,
  canvasHeight = 512;

ImageElement spritesImage;
CanvasElement c;
CanvasRenderingContext2D ctx;

World world;
Player player;
InputHandler focusObject;

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
  focusObject = player;

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
  
  List<List<Tile>> renderList = [ [], [], [], [] ];
  
  player.render(renderList);
  world.render(renderList);
  
  for(List<Tile> layer in renderList) {
    for(Tile tile in layer) {
      tile.sprite.render(ctx, spritesImage, canvasWidth, canvasHeight);
    }
  }
  
  Input.handleKey(focusObject, world);
  
  player.tick(world);
  
  new Timer(new Duration(milliseconds: 33), () => tick());
}
