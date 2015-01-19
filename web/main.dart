import 'dart:html';
import 'dart:async';

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/gui.dart';
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
  
  Gui.renderWindow(ctx, spritesImage, canvasWidth, canvasHeight, 1, 11, 18, 4);
  Gui.renderWindow(ctx, spritesImage, canvasWidth, canvasHeight, 1, 11, 4, 4);
  Font.renderStaticText(ctx, spritesImage, canvasWidth, canvasHeight, 10.5, 23.5, "This seems to be working! This is  ");
  Font.renderStaticText(ctx, spritesImage, canvasWidth, canvasHeight, 10.5, 25.0, "what a full screen of text would");
  Font.renderStaticText(ctx, spritesImage, canvasWidth, canvasHeight, 10.5, 26.5, "look like given 4 lines and 35");
  Font.renderStaticText(ctx, spritesImage, canvasWidth, canvasHeight, 10.5, 28.0, "characters per line.");
  
  Input.handleKey(focusObject, world);
  
  player.tick(world);
  
  new Timer(new Duration(milliseconds: 33), () => tick());
}
