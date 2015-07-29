library dart_rpg.main;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

// TODO: choice game event options box might be drawing too tall
// TODO: clear gui when loading game json

class Main {
  static final int
    canvasWidth = 640,
    canvasHeight = 512;

  static ImageElement spritesImage;
  static CanvasElement c;
  static CanvasRenderingContext2D ctx;
  static bool gameJsonHasFocus = false;

  static World world;
  static Player player;
  static InputHandler focusObject;
  static List<List<Tile>> renderList;
  
  static final int timeDelay = 33;
  static double timeScale = 1.0;
  static bool inBattle = false;
  static Battle battle;
  
  static Timer tickTimer = null;
  
  static void init() {
    c = querySelector('canvas');
    ctx = c.getContext("2d");
    
    if(window.devicePixelRatio != 1.0) {
      double scale = window.devicePixelRatio;
      c.style.width = c.width.toString() + 'px';
      c.style.height = c.height.toString() + 'px';
      c.width = (c.width * scale).round();
      c.height = (c.height * scale).round();
      ctx.scale(scale, scale);
    }
    
    ctx.imageSmoothingEnabled = false;
    
    spritesImage = new ImageElement(src: "sprite_sheet.png");
    spritesImage.onLoad.listen((e) {
      start();
    });
  }
  
  static void start() {
    TextAreaElement textArea = querySelector("#game_json");
    textArea.onFocus.listen((Event e) {
      gameJsonHasFocus = true;
    });
    
    textArea.onBlur.listen((Event e) {
      gameJsonHasFocus = false;
    });
    
    document.onKeyDown.listen((KeyboardEvent e) {
      if(!gameJsonHasFocus) {
        e.preventDefault();
        
        if(!Input.keys.contains(e.keyCode))
          Input.keys.add(e.keyCode);
      }
    });
    
    document.onKeyUp.listen((KeyboardEvent e) {
      if(!gameJsonHasFocus) {
        e.preventDefault();
        
        Input.keys.remove(e.keyCode);
      }
    });
    
    Function createWorld = () {
      timeScale = 0.0;
      world = new World(() {
        focusObject = player;
        timeScale = 1.0;
        tick();
      });
    };
    
    ButtonElement loadGameButton = querySelector("#load_game_button");
    loadGameButton.onClick.listen((MouseEvent e) {
      createWorld();
    });
    
    createWorld();
  }
  
  static void tick() {
    // Keeps the value from being set to 0 in between checking it and dividing by it
    var curTimeScale = timeScale;
    
    if(world.maps[world.curMap] == null)
      return;
 
    // Draw black background
    ctx.fillStyle = "#000000";
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    if(!inBattle) {
      renderList = [];
      for(int i=0; i<World.layers.length; i++) {
        renderList.add([]);
      }
      
      player.render(renderList);
      world.render(renderList);
      
      for(Character character in World.characters.values) {
        if(character.map == world.curMap) {
          character.render(renderList);
          
          if(curTimeScale > 0.0) {
            character.tick();
          }
        }
      }
      
      for(List<Tile> layer in renderList) {
        for(Tile tile in layer) {
          tile.render();
        }
      }
      
      if(curTimeScale > 0.0) {
        player.tick();
      }
    } else {
      battle.render();
      battle.tick();
    }
    
    Gui.render();
    Input.handleKey(focusObject);
    
    if(tickTimer != null)
      tickTimer.cancel();
    
    if(curTimeScale > 0.0) {
      tickTimer = new Timer(new Duration(milliseconds: (timeDelay * (1/curTimeScale)).round()), () => tick());
    } else {
      tickTimer = new Timer(new Duration(milliseconds: timeDelay), () => tick());
    }
  }
}