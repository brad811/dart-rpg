library dart_rpg.settings;

import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';

class Settings {
  static CanvasElement canvas;
  static CanvasRenderingContext2D ctx;
  static DivElement tooltip;
  
  static List<String> tabs = [];
  static Map<String, DivElement> tabDivs = {};
  static Map<String, DivElement> tabHeaderDivs = {};
  
  static void init() {
    canvas = querySelector("#editor_sprite_settings_canvas");
    ctx = canvas.getContext("2d");
  }
  
  static void setUp() {
    setUpSpriteCanvas();
  }
  
  static void update() {
    buildMainHtml();
    
    // attach listener to save button
    querySelector("#settings_save_button").onClick.listen((MouseEvent e) {
      save();
    });
  }
  
  static void buildMainHtml() {
    String html = "";
    
    html += "NOTE: You must click save for your changes on this tab to take effect!<hr />";
    html += "<button id='settings_save_button'>Save</button><hr />";
    
    html += "<table>";
    
    html += "<tr>";
    html += "<td>Sprite sheet location:&nbsp;</td>";
    html += "<td>&nbsp;<textarea id='sprite_sheet_location'>${ Main.spritesImageLocation }</textarea></td>";
    html += "</tr>";
    
    html += "<tr>";
    html += "<td>Pixels per sprite:&nbsp;</td>";
    html += "<td>&nbsp;<input id='sprite_sheet_pixels_per_sprite' type='text' class='number' value='${ Sprite.pixelsPerSprite }' /></td>";
    html += "</tr>";
    
    html += "<tr>";
    html += "<td>Sprite scale:&nbsp;</td>";
    html += "<td>&nbsp;<input id='sprite_sheet_scale' type='text' class='number' value='${ Sprite.spriteScale }' /></td>";
    html += "</tr>";
    
    html += "<tr>";
    html += "<td>Frames per second:&nbsp;</td>";
    html += "<td>&nbsp;<input id='settings_frames_per_second' type='text' class='number' value='${ Main.framesPerSecond }' /></td>";
    html += "</tr>";
    
    html += "</table>";
    
    querySelector("#settings_main_tab").setInnerHtml(html);
  }
  
  static void setUpSpriteCanvas() {
    Main.fixImageSmoothing(
      canvas,
      (Main.spritesImage.width * Sprite.spriteScale).round(),
      (Main.spritesImage.height * Sprite.spriteScale).round()
    );
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(
      0, 0,
      Sprite.scaledSpriteSize*Sprite.spriteSheetWidth,
      Sprite.scaledSpriteSize*Sprite.spriteSheetHeight
    );
    
    // render sprite picker
    int
      maxCol = Sprite.spriteSheetWidth,
      col = 0,
      row = 0;
    
    for(int y=0; y<Sprite.spriteSheetHeight; y++) {
      for(int x=0; x<Sprite.spriteSheetWidth; x++) {
        MapEditor.renderStaticSprite(ctx, y*Sprite.spriteSheetWidth + x, col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    tooltip = querySelector('#tooltip');
    
    canvas.onMouseMove.listen(outlineTile);
    
    canvas.onMouseLeave.listen((MouseEvent e) {
      tooltip.style.display = "none";
    });
  }
  
  static void outlineTile(MouseEvent e) {
    int x = (e.offset.x / Sprite.scaledSpriteSize).floor();
    int y = (e.offset.y / Sprite.scaledSpriteSize).floor();
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(
      0, 0,
      Sprite.scaledSpriteSize*Sprite.spriteSheetWidth,
      Sprite.scaledSpriteSize*Sprite.spriteSheetHeight
    );
    
    int
      maxCol = Sprite.spriteSheetWidth,
      col = 0,
      row = 0;
    
    for(int y=0; y<Sprite.spriteSheetHeight; y++) {
      for(int x=0; x<Sprite.spriteSheetWidth; x++) {
        MapEditor.renderStaticSprite(ctx, y*Sprite.spriteSheetWidth + x, col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    ctx.lineWidth = 4;
    ctx.setStrokeColorRgb(255, 255, 255, 1.0);
    ctx.strokeRect(Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2, Sprite.scaledSpriteSize + 4, Sprite.scaledSpriteSize + 4);
    
    ctx.lineWidth = 2;
    ctx.setStrokeColorRgb(0, 0, 0, 1.0);
    ctx.strokeRect(Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2, Sprite.scaledSpriteSize + 4, Sprite.scaledSpriteSize + 4);
    
    tooltip.style.display = "block";
    tooltip.style.left = "${e.page.x + 30}px";
    tooltip.style.top = "${e.page.y - 10}px";
    tooltip.text = "x: ${x}, y: ${y}, id: ${ (y*Sprite.spriteSheetWidth) + x }";
  }
  
  static void save() {
    Main.spritesImageLocation = Editor.getTextAreaStringValue("#sprite_sheet_location");
    
    Sprite.pixelsPerSprite = Editor.getTextInputIntValue("#sprite_sheet_pixels_per_sprite", 16);
    Sprite.spriteScale = Editor.getTextInputIntValue("#sprite_sheet_scale", 2);
    
    Sprite.scaledSpriteSize = Sprite.pixelsPerSprite * Sprite.spriteScale;
    
    Main.framesPerSecond = Editor.getTextInputIntValue("#settings_frames_per_second", 40);
    
    Main.spritesImage = new ImageElement(src:Main.spritesImageLocation);
    Main.spritesImage.onLoad.listen((e) {
      Sprite.spriteSheetWidth = (Main.spritesImage.width / Sprite.pixelsPerSprite).round();
      Sprite.spriteSheetHeight = (Main.spritesImage.height / Sprite.pixelsPerSprite).round();
      
      MapEditor.setUp();
      ObjectEditor.setUp();
      Settings.setUp();
      
      Editor.update();
      
      Main.fixImageSmoothing(
        MapEditor.mapEditorSpriteSelectorCanvas,
        Sprite.spriteSheetWidth * Sprite.scaledSpriteSize,
        Sprite.spriteSheetHeight * Sprite.scaledSpriteSize
      );
      
      Main.fixImageSmoothing(
        MapEditor.mapEditorSelectedSpriteCanvas,
        Sprite.scaledSpriteSize,
        Sprite.scaledSpriteSize
      );
      
      Main.fixImageSmoothing(
        canvas,
        Sprite.spriteSheetWidth * Sprite.scaledSpriteSize,
        Sprite.spriteSheetHeight * Sprite.scaledSpriteSize
      );
      
      MapEditor.mapEditorSpriteSelectorCanvasContext.fillStyle = "#ff00ff";
      MapEditor.mapEditorSpriteSelectorCanvasContext.fillRect(
        0, 0,
        Sprite.scaledSpriteSize*Sprite.spriteSheetWidth,
        Sprite.scaledSpriteSize*Sprite.spriteSheetHeight
      );
      
      // render sprite picker
      int
        maxCol = Sprite.spriteSheetWidth,
        col = 0,
        row = 0;
      for(int y=0; y<Sprite.spriteSheetHeight; y++) {
        for(int x=0; x<Sprite.spriteSheetWidth; x++) {
          MapEditor.renderStaticSprite(MapEditor.mapEditorSpriteSelectorCanvasContext, y*Sprite.spriteSheetWidth + x, col, row);
          col++;
          if(col >= maxCol) {
            row++;
            col = 0;
          }
        }
      }
    });
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Object> json = {};
    json["spriteSheetLocation"] = Main.spritesImageLocation;
    json["pixelsPerSprite"] = Sprite.pixelsPerSprite;
    json["spriteScale"] = Sprite.spriteScale;
    
    json["framesPerSecond"] = Main.framesPerSecond;
    
    exportJson["settings"] = json;
  }
}