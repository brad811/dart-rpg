library dart_rpg.screen_editor;

import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class ScreenEditor {
  static CanvasElement canvas;
  static CanvasRenderingContext2D ctx;
  
  static void init() {
    canvas = querySelector("#screen_editor_canvas");
    ctx = canvas.getContext("2d");
  }
  
  static void setUp() {
    // TODO
  }
  
  static void update() {
    // TODO
    buildMainHtml();
    
    Main.fixImageSmoothing(canvas, Main.canvasWidth, Main.canvasHeight);
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, Main.canvasWidth, Main.canvasHeight);
  }
  
  static void buildMainHtml() {
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    // TODO
  }
}