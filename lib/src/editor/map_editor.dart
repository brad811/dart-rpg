library dart_rpg.map_editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'map_editor_characters.dart';
import 'map_editor_maps.dart';
import 'map_editor_signs.dart';
import 'map_editor_warps.dart';
import 'map_editor_battlers.dart';

class MapEditor {
  static ImageElement spritesImage;
  
  static CanvasElement
    mapEditorCanvas,
    mapEditorSpriteSelectorCanvas,
    mapEditorSelectedSpriteCanvas;
  
  static CanvasRenderingContext2D
    mapEditorCanvasContext,
    mapEditorSpriteSelectorCanvasContext,
    mapEditorSelectedSpriteCanvasContext;
  
  static List<String> mapEditorTabs = ["maps", "tiles", "characters", "warps", "signs", "battlers"];
  static Map<String, DivElement> mapEditorTabDivs = {};
  static Map<String, DivElement> mapEditorTabHeaderDivs = {};
  
  static int
    mapEditorCanvasWidth = 100,
    mapEditorCanvasHeight = 100;
  
  static List<bool> layerVisible = [];
  
  static List<List<Tile>> renderList;
  static int selectedTile;
  
  static void init(Function callback) {
    mapEditorCanvas = querySelector('#editor_main_canvas');
    mapEditorCanvasContext = mapEditorCanvas.getContext("2d");
    
    mapEditorSpriteSelectorCanvas = querySelector('#editor_sprite_canvas');
    mapEditorSpriteSelectorCanvasContext = mapEditorSpriteSelectorCanvas.getContext("2d");
    
    mapEditorSelectedSpriteCanvas = querySelector('#editor_selected_sprite_canvas');
    mapEditorSelectedSpriteCanvasContext = mapEditorSelectedSpriteCanvas.getContext("2d");
    
    if(window.devicePixelRatio != 1.0) {
      List<CanvasElement> canvasElements = [
        mapEditorCanvas,
        mapEditorSpriteSelectorCanvas,
        mapEditorSelectedSpriteCanvas
      ];
      
      List<CanvasRenderingContext2D> contexts = [
        mapEditorCanvasContext,
        mapEditorSpriteSelectorCanvasContext,
        mapEditorSelectedSpriteCanvasContext
      ];
      
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
      callback();
    });
  }
  
  static void setUp() {
    for(String tab in mapEditorTabs) {
      mapEditorTabDivs[tab] = querySelector("#${tab}_tab");
      mapEditorTabDivs[tab].style.display = "none";
      
      mapEditorTabHeaderDivs[tab] = querySelector("#${tab}_tab_header");
      
      mapEditorTabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in mapEditorTabs) {
          mapEditorTabDivs[tabb].style.display = "none";
          mapEditorTabHeaderDivs[tabb].style.backgroundColor = "";
        }
        
        mapEditorTabDivs[tab].style.display = "block";
        mapEditorTabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
      });
    }
    
    mapEditorTabDivs[mapEditorTabDivs.keys.first].style.display = "block";
    mapEditorTabHeaderDivs[mapEditorTabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
    
    MapEditorMaps.setUp();
    MapEditorCharacters.setUp();
    MapEditorWarps.setUp();
    MapEditorSigns.setUp();
    MapEditorBattlers.setUp();
    
    setUpSpritePicker();
  }
  
  static void update() {
    MapEditorMaps.update();
    MapEditorCharacters.update();
    MapEditorWarps.update();
    MapEditorSigns.update();
    MapEditorBattlers.update();
    
    MapEditor.updateMap();
  }
  
  static void setUpSpritePicker() {
    mapEditorSpriteSelectorCanvasContext.fillStyle = "#ff00ff";
    mapEditorSpriteSelectorCanvasContext.fillRect(
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
        renderStaticSprite(mapEditorSpriteSelectorCanvasContext, y*Sprite.spriteSheetSize + x, col, row);
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
      
      Editor.update();
    };
    
    mapEditorCanvas.onClick.listen(tileChange);
    
    var tooltip = querySelector('#tooltip');
    /*StreamSubscription mouseMoveStream = */
    mapEditorCanvas.onMouseMove.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      
      tooltip.style.display = "block";
      tooltip.style.left = "${e.page.x + 30}px";
      tooltip.style.top = "${e.page.y - 10}px";
      tooltip.text = "x: ${x}, y: ${y}";
    });
    
    mapEditorCanvas.onMouseLeave.listen((onData) {
      tooltip.style.display = "none";
    });
    
    mapEditorCanvas.onMouseDown.listen((MouseEvent e) {
      StreamSubscription mouseMoveStream = mapEditorCanvas.onMouseMove.listen((MouseEvent e) {
        tileChange(e);
      });

      mapEditorCanvas.onMouseUp.listen((onData) => mouseMoveStream.cancel());
      mapEditorCanvas.onMouseLeave.listen((onData) => mouseMoveStream.cancel());
    });
    
    mapEditorSpriteSelectorCanvas.onClick.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      selectSprite(y*Sprite.spriteSheetSize + x);
    });
  }
  
  static void updateMapCanvasSize() {
    if(mapEditorCanvas.width != mapEditorCanvasWidth || mapEditorCanvas.height != mapEditorCanvasHeight) {
      mapEditorCanvas.width = mapEditorCanvasWidth;
      mapEditorCanvas.height = mapEditorCanvasHeight;
      
      if(window.devicePixelRatio != 1.0) {
        double scale = window.devicePixelRatio;
        
        mapEditorCanvas.style.width = mapEditorCanvas.width.toString() + 'px';
        mapEditorCanvas.style.height = mapEditorCanvas.height.toString() + 'px';
        mapEditorCanvas.width = (mapEditorCanvas.width * scale).round();
        mapEditorCanvas.height = (mapEditorCanvas.height * scale).round();
        mapEditorCanvasContext.scale(scale, scale);
      }
      
      mapEditorCanvasContext.imageSmoothingEnabled = false;
      context.callMethod("fixImageSmoothing");
    }
  }
  
  static void updateMap({bool shouldExport: false}) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<Character> characters = Main.world.maps[Main.world.curMap].characters;
    
    if(querySelector("#size_x") != null)
      querySelector("#size_x").text = mapTiles[0].length.toString();
    
    if(querySelector("#size_y") != null)
      querySelector("#size_y").text = mapTiles.length.toString();
    
    if(mapTiles.length == 0 || mapTiles[0].length == 0)
      return;
    
    mapEditorCanvasHeight = mapTiles.length * Sprite.scaledSpriteSize;
    mapEditorCanvasWidth = mapTiles[0].length * Sprite.scaledSpriteSize;
    
    updateMapCanvasSize();
    
    // Draw pink background
    mapEditorCanvasContext.fillStyle = "#ff00ff";
    mapEditorCanvasContext.fillRect(0, 0, mapEditorCanvasWidth, mapEditorCanvasHeight);
    
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
          mapEditorCanvasContext, tile.sprite.id,
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
    outlineTiles(MapEditorWarps.warps[Main.world.curMap], 0, 255, 0);
    
    // draw yellow boxes around sign tiles
    outlineTiles(MapEditorSigns.signs[Main.world.curMap], 255, 255, 0);
    
    if(shouldExport) {
      Editor.export();
    }
  }
  
  static void outlineTiles(List<Tile> tiles, int r, int g, int b) {
    mapEditorCanvasContext.beginPath();
    for(Tile tile in tiles) {
      int
        x = (tile.sprite.posX * Sprite.scaledSpriteSize).round(),
        y = (tile.sprite.posY * Sprite.scaledSpriteSize).round();
      
      mapEditorCanvasContext.moveTo(x, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x, y);
      
      mapEditorCanvasContext.setFillColorRgb(r, g, b, 0.1);
      mapEditorCanvasContext.fillRect(x, y, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    }
    
    // draw the strokes around the tiles
    mapEditorCanvasContext.closePath();
    mapEditorCanvasContext.setStrokeColorRgb(r, g, b, 0.9);
    mapEditorCanvasContext.stroke();
  }
  
  static void selectSprite(int id) {
    selectedTile = id;
    mapEditorSelectedSpriteCanvasContext.fillStyle = "#ff00ff";
    mapEditorSelectedSpriteCanvasContext.fillRect(0, 0, 32, 32);
    renderStaticSprite(mapEditorSelectedSpriteCanvasContext, id, 0, 0);
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
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    exportJson["maps"] = {};
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      exportJson["maps"][key] = {};
      
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
      
      MapEditorWarps.export(jsonMap, key);
      MapEditorSigns.export(jsonMap, key);
      
      MapEditorCharacters.export(exportJson["maps"][key], key);

      MapEditorBattlers.export(exportJson["maps"][key], key);
      
      exportJson["maps"][key]['tiles'] = jsonMap;
    }
    
    TextAreaElement textarea = querySelector("#export_json");
    textarea.value = JSON.encode(exportJson);
  }
}