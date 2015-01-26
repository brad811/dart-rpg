library Main;

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/player.dart';
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
  
  static final int timeDelay = 33;
  static double timeScale = 1.0;
  
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
    ctx.fillStyle = "#000000";
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    renderList = [ [], [], [], [] ];
    for(int i=0; i<World.layers.length; i++) {
      renderList.add([]);
    }
    
    player.render(renderList);
    world.render(renderList);
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        tile.sprite.render();
      }
    }
    
    Gui.render();
    
    // Keeps the value from being set to 0 in between checking it and dividing by it
    var curTimeScale = timeScale;
    
    if(timeScale > 0.0) {
      Input.handleKey(focusObject);
      player.tick();
      new Timer(new Duration(milliseconds: (timeDelay * (1/curTimeScale)).round()), () => tick());
    } else {
      new Timer(new Duration(milliseconds: timeDelay), () => tick());
    }
  }
}
