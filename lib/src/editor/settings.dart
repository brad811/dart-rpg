library dart_rpg.settings;

import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

import 'map_editor.dart';

class Settings {
  static CanvasElement canvas;
  static CanvasRenderingContext2D ctx;
  
  static List<String> tabs = [];
  static Map<String, DivElement> tabDivs = {};
  static Map<String, DivElement> tabHeaderDivs = {};
  
  static void init() {
    // attach listener to save button
    canvas = querySelector("#editor_sprite_settings_canvas");
    ctx = canvas.getContext("2d");
  }
  
  static void setUp() {
    setUpSpritePicker();
  }
  
  static void update() {
    buildMainHtml();
  }
  
  static void buildMainHtml() {
    String html = "";
    
    html += "NOTE: You must click save on this tab for your changes to take effect!<hr />";
    
    html += "<table><tr>";
    html += "<td>Sprite sheet location:&nbsp;</td>";
    html += "<td>&nbsp;<textarea id='sprite_sheet_location'>${ Main.spritesImageLocation }</textarea></td>";
    html += "</tr></table>";
    
    querySelector("#settings_main_tab").setInnerHtml(html);
  }
  
  static void setUpSpritePicker() {
    MapEditor.fixImageSmoothing(
      canvas,
      (Main.spritesImage.width * window.devicePixelRatio).round(),
      (Main.spritesImage.height * window.devicePixelRatio).round()
    );
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(
      0, 0,
      Sprite.scaledSpriteSize*Sprite.spriteSheetSize,
      Sprite.scaledSpriteSize*Sprite.spriteSheetSize
    );
    
    // render sprite picker
    int
      maxCol = 32,
      col = 0,
      row = 0;
    
    for(int y=0; y<Sprite.spriteSheetSize; y++) {
      for(int x=0; x<Sprite.spriteSheetSize; x++) {
        MapEditor.renderStaticSprite(ctx, y*Sprite.spriteSheetSize + x, col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    canvas.onMouseMove.listen(outlineTile);
  }
  
  static void outlineTile(MouseEvent e) {
    int x = (e.offset.x / Sprite.scaledSpriteSize).floor();
    int y = (e.offset.y / Sprite.scaledSpriteSize).floor();
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(
      0, 0,
      Sprite.scaledSpriteSize*Sprite.spriteSheetSize,
      Sprite.scaledSpriteSize*Sprite.spriteSheetSize
    );
    
    int
      maxCol = 32,
      col = 0,
      row = 0;
    
    for(int y=0; y<Sprite.spriteSheetSize; y++) {
      for(int x=0; x<Sprite.spriteSheetSize; x++) {
        MapEditor.renderStaticSprite(ctx, y*Sprite.spriteSheetSize + x, col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    ctx.lineWidth = 3;
    ctx.setStrokeColorRgb(255, 255, 255, 1.0);
    ctx.strokeRect(Sprite.scaledSpriteSize * x, Sprite.scaledSpriteSize * y, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    
    ctx.lineWidth = 1;
    ctx.setStrokeColorRgb(0, 0, 0, 1.0);
    ctx.strokeRect(Sprite.scaledSpriteSize * x, Sprite.scaledSpriteSize * y, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
  }
  
  static void save() {
    // TODO: onInputChange
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
  }
}