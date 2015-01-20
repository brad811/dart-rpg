library Main;

import 'dart:html';
import 'dart:async';

import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Main {
  static final int canvasWidth = 640,
    canvasHeight = 512;

  static ImageElement spritesImage;
  static CanvasElement c;
  static CanvasRenderingContext2D ctx;

  static World world;
  static Player player;
  static InputHandler focusObject;
  static List<List<Tile>> renderList;
  
  static void init() {
    c = querySelector('canvas');
    ctx = c.getContext("2d");
    ctx.imageSmoothingEnabled = false;
    
    spritesImage = new ImageElement(src: "sprite_sheet.png");
    spritesImage.onLoad.listen((e) {
        start();
    });
  }
  
  static void start() {
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
  
  static void tick() {
    ctx.fillStyle = "#333333";
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    // TODO: I'd like to have this be determined by layers.length
    renderList = [ [], [], [], [] ];
    
    player.render(renderList);
    world.render(renderList);
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        tile.sprite.render();
      }
    }
    
    Gui.render();
    
    Input.handleKey(focusObject);
    
    player.tick();
    
    new Timer(new Duration(milliseconds: 33), () => tick());
  }
}
