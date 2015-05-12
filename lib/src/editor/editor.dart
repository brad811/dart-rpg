library dart_rpg.editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor_characters.dart';
import 'package:dart_rpg/src/editor/editor_maps.dart';
import 'package:dart_rpg/src/editor/editor_signs.dart';
import 'package:dart_rpg/src/editor/editor_warps.dart';
import 'package:dart_rpg/src/editor/editor_battlers.dart';

// TODO:
// - maybe make maps use numbers instead of names
//   - could simplify making references to them
//   - wouldn't be able to change so wouldn't ever have to update warps on name changes
//     - but what about warps that point to a map that no longer exists?
//       - probably delete

// TODO: add hover tooltip that shows ID of tiles
// TODO: add hover tooltip that shows map coordinates
// TODO: enable showing and hiding layers
// TODO: shift warps, signs, etc. when map is resized

// TODO: add delete buttons to the various tabs

class Editor {
  static ImageElement spritesImage;
  static CanvasElement c, sc, ssc;
  static CanvasRenderingContext2D ctx, sctx, ssctx;
  static List<String> tabs = ["maps", "tiles", "characters", "warps", "signs", "battlers"];
  static Map<String, DivElement> tabDivs = {};
  static Map<String, DivElement> tabHeaderDivs = {};
  
  static int
    canvasWidth = 100,
    canvasHeight = 100;
  
  static List<bool> layerVisible = [];
  
  static List<List<Tile>> renderList;
  static int selectedTile;
  
  static void init() {
    c = querySelector('#editor_main_canvas');
    ctx = c.getContext("2d");
    
    sc = querySelector('#editor_sprite_canvas');
    sctx = sc.getContext("2d");
    
    ssc = querySelector('#editor_selected_sprite_canvas');
    ssctx = ssc.getContext("2d");
    
    if(window.devicePixelRatio != 1.0) {
      List<CanvasElement> canvasElements = [c, sc, ssc];
      List<CanvasRenderingContext2D> contexts = [ctx, sctx, ssctx];
      double scale = window.devicePixelRatio;
      
      for(int i=0; i<canvasElements.length; i++) {
        canvasElements[i].style.width = canvasElements[i].width.toString() + 'px';
        canvasElements[i].style.height = canvasElements[i].height.toString() + 'px';
        canvasElements[i].width = (canvasElements[i].width * scale).round();
        canvasElements[i].height = (canvasElements[i].height * scale).round();
        contexts[i].scale(scale, scale);
        contexts[i].imageSmoothingEnabled = false;
      }
    }
    
    for(int layer in World.layers) {
      layerVisible.add(true);
    }
    
    spritesImage = new ImageElement(src: "sprite_sheet.png");
    spritesImage.onLoad.listen((e) {
      start();
    });
  }
  
  static void start() {
    Main.player = new Player(0, 0);
    
    Main.world = new World(() {
      Main.world.loadMaps(() {
        setUpTabs();
        setUpSpritePicker();
        
        EditorMaps.setUp();
        EditorCharacters.setUp();
        EditorWarps.setUp();
        EditorSigns.setUp();
        EditorBattlers.setUp();
        
        updateAllTables();
        
        Function resizeFunction = (Event e) {
          querySelector('#left_half').style.width = "${window.innerWidth - 580}px";
          querySelector('#left_half').style.height = "${window.innerHeight - 30}px";
        };
        
        window.onResize.listen(resizeFunction);
        resizeFunction(null);
      });
    });
  }
  
  static void updateAllTables() {
    EditorMaps.update();
    EditorCharacters.update();
    EditorWarps.update();
    EditorSigns.update();
    EditorBattlers.update();
    
    Editor.updateMap();
  }
  
  static void setUpTabs() {
    for(String tab in tabs) {
      tabDivs[tab] = querySelector("#${tab}_tab");
      tabDivs[tab].style.display = "none";
      
      tabHeaderDivs[tab] = querySelector("#${tab}_tab_header");
      
      tabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in tabs) {
          tabDivs[tabb].style.display = "none";
          tabHeaderDivs[tabb].style.backgroundColor = "";
        }
        
        tabDivs[tab].style.display = "block";
        tabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
      });
    }
    
    tabDivs[tabDivs.keys.first].style.display = "block";
    tabHeaderDivs[tabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
  }
  
  static void setUpSpritePicker() {
    sctx.fillStyle = "#ff00ff";
      sctx.fillRect(
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
          renderStaticSprite(sctx, y*Sprite.spriteSheetSize + x, col, row);
          col++;
          if(col >= maxCol) {
            row++;
            col = 0;
          }
        }
      }
      
      selectSprite(Tile.GROUND);
      
      Function tileChange = (MouseEvent e) {
        List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
        int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
        int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
        
        if(y >= mapTiles.length || x >= mapTiles[0].length)
          return;
        
        int layer = int.parse((querySelector("[name='layer']:checked") as RadioButtonInputElement).value);
        bool solid = (querySelector("#solid") as CheckboxInputElement).checked;
        bool layered = (querySelector("#layered") as CheckboxInputElement).checked;
        bool encounter = (querySelector("#encounter") as CheckboxInputElement).checked;
        
        if(selectedTile == 98) {
          mapTiles[y][x][layer] = null;
        } else if(encounter) {
          mapTiles[y][x][layer] = new EncounterTile(
            new Sprite.int(selectedTile, x, y),
            layered
          );
        } else {
          mapTiles[y][x][layer] = new Tile(
            solid,
            new Sprite.int(selectedTile, x, y),
            layered
          );
        }
        
        updateMap();
      };
      
      c.onClick.listen(tileChange);
      
      c.onMouseDown.listen((MouseEvent e) {
        StreamSubscription mouseMoveStream = c.onMouseMove.listen((MouseEvent e) {
          tileChange(e);
        });

        c.onMouseUp.listen((onData) => mouseMoveStream.cancel());
        c.onMouseLeave.listen((onData) => mouseMoveStream.cancel());
      });
      
      sc.onClick.listen((MouseEvent e) {
        int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
        int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
        selectSprite(y*Sprite.spriteSheetSize + x);
      });
  }
  
  static void updateMapCanvasSize() {
    if(c.width != canvasWidth || c.height != canvasHeight) {
      c.width = canvasWidth;
      c.height = canvasHeight;
      
      if(window.devicePixelRatio != 1.0) {
        double scale = window.devicePixelRatio;
        
        c.style.width = c.width.toString() + 'px';
        c.style.height = c.height.toString() + 'px';
        c.width = (c.width * scale).round();
        c.height = (c.height * scale).round();
        ctx.scale(scale, scale);
      }
      
      ctx.imageSmoothingEnabled = false;
      context.callMethod("fixImageSmoothing");
    }
  }
  
  static void updateMap() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<Character> characters = Main.world.maps[Main.world.curMap].characters;
    
    if(querySelector("#size_x") != null)
      querySelector("#size_x").text = mapTiles[0].length.toString();
    
    if(querySelector("#size_y") != null)
      querySelector("#size_y").text = mapTiles.length.toString();
    
    if(mapTiles.length == 0 || mapTiles[0].length == 0)
      return;
    
    canvasHeight = mapTiles.length * Sprite.scaledSpriteSize;
    canvasWidth = mapTiles[0].length * Sprite.scaledSpriteSize;
    
    updateMapCanvasSize();
    
    // Draw pink background
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    renderList = [];
    for(int i=0; i<World.layers.length; i++) {
      renderList.add([]);
    }
    
    renderWorld(renderList);
    
    for(Character character in characters) {
      character.render(renderList);
    }
    
    List<Tile> solids = [];
    List<Tile> layereds = [];
    List<Tile> encounters = [];
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        renderStaticSprite(
          ctx, tile.sprite.id,
          tile.sprite.posX.round(), tile.sprite.posY.round()
        );
        
        // add solid tiles, layered tiles, and encounter tiles
        // to a list to have boxes drawn around them
        if(tile.solid)
          solids.add(tile);
        
        if(tile.layered == true)
          layereds.add(tile);
        
        if(tile is EncounterTile)
          encounters.add(tile);
      }
    }
    
    // draw red boxes around solid tiles
    outlineTiles(solids, 255, 0, 0);
    
    // TODO: draw blue boxes around characters
    
    // draw cyan boxes around layered tiles
    outlineTiles(layereds, 0, 150, 255);
    
    // draw magenta boxes around encounter tiles
    outlineTiles(encounters, 200, 0, 255);
    
    // draw green boxes around warp tiles
    outlineTiles(EditorWarps.warps[Main.world.curMap], 0, 255, 0);
    
    // draw yellow boxes around sign tiles
    outlineTiles(EditorSigns.signs[Main.world.curMap], 255, 255, 0);
    
    // build the json
    buildExportJson();
  }
  
  static void buildExportJson() {
    Map<String, Map> exportJson = {};
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      exportJson[key] = {};
      
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      
      List<List<List<Map>>> jsonMap = [];
      for(int y=0; y<mapTiles.length; y++) {
        jsonMap.add([]);
        for(int x=0; x<mapTiles[0].length; x++) {
          jsonMap[y].add([]);
          for(int k=0; k<mapTiles[0][0].length; k++) {
            if(mapTiles[y][x][k] is Tile) {
              if(mapTiles[y][x][k].sprite.id == -1) {
                jsonMap[y][x].add(null);
              } else {
                Map jsonObject = {};
                jsonObject["id"] = mapTiles[y][x][k].sprite.id;
                if(mapTiles[y][x][k].solid)
                  jsonObject["solid"] = true;
                if(mapTiles[y][x][k].layered == true)
                  jsonObject["layered"] = true;
                if(mapTiles[y][x][k] is EncounterTile)
                  jsonObject["encounter"] = true;
                
                jsonMap[y][x].add(jsonObject);
              }
            } else {
              jsonMap[y][x].add(null);
            }
          }
        }
      }
      
      EditorWarps.export(jsonMap, key);
      EditorSigns.export(jsonMap, key);
      
      EditorCharacters.export(exportJson[key], key);

      EditorBattlers.export(exportJson[key], key);
      
      exportJson[key]['tiles'] = jsonMap;
    }
    
    TextAreaElement textarea = querySelector("#export_json");
    textarea.value = JSON.encode(exportJson);
  }
  
  static void outlineTiles(List<Tile> tiles, int r, int g, int b) {
    ctx.beginPath();
    for(Tile tile in tiles) {
      int
        x = (tile.sprite.posX * Sprite.scaledSpriteSize).round(),
        y = (tile.sprite.posY * Sprite.scaledSpriteSize).round();
      
      ctx.moveTo(x, y);
      ctx.lineTo(x + Sprite.scaledSpriteSize, y);
      ctx.lineTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize);
      ctx.lineTo(x, y + Sprite.scaledSpriteSize);
      ctx.lineTo(x, y);
      
      ctx.setFillColorRgb(r, g, b, 0.1);
      ctx.fillRect(x, y, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    }
    
    // draw the strokes around the tiles
    ctx.closePath();
    ctx.setStrokeColorRgb(r, g, b, 0.9);
    ctx.stroke();
  }
  
  static void selectSprite(int id) {
    selectedTile = id;
    ssctx.fillStyle = "#ff00ff";
    ssctx.fillRect(0, 0, 32, 32);
    renderStaticSprite(ssctx, id, 0, 0);
  }
  
  static void renderStaticSprite(CanvasRenderingContext2D ctx, int id, int posX, int posY) {
    ctx.drawImageScaledFromSource(
      spritesImage,
      
      Sprite.pixelsPerSprite * (id%Sprite.spriteSheetSize), // sx
      Sprite.pixelsPerSprite * (id/Sprite.spriteSheetSize).floor(), // sy
      
      Sprite.pixelsPerSprite, Sprite.pixelsPerSprite, // swidth, sheight
      
      posX*Sprite.scaledSpriteSize, // x
      posY*Sprite.scaledSpriteSize, // y
      
      Sprite.scaledSpriteSize, Sprite.scaledSpriteSize // width, height
    );
  }
  
  static void renderWorld(List<List<Tile>> renderList) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    
    for(var y=0; y<mapTiles.length; y++) {
      for(var x=0; x<mapTiles[y].length; x++) {
        for(int layer in World.layers) {
          if(!layerVisible[layer])
            continue;
          
          if(mapTiles[y][x][layer] is Tile) {
            renderList[layer].add(
              mapTiles[y][x][layer]
            );
          }
        }
      }
    }
  }
}