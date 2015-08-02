library dart_rpg.map_editor;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'editor.dart';
import 'map_editor_characters.dart';
import 'map_editor_events.dart';
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
  
  static List<String> mapEditorTabs = ["maps", "tiles", "map_characters", "warps", "signs", "battlers", "events"];
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
    
    for(int i=0; i<World.layers.length; i++) {
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
    MapEditorEvents.setUp();
    
    setUpSpritePicker();
  }
  
  static void update() {
    MapEditorMaps.update();
    MapEditorCharacters.update();
    MapEditorWarps.update();
    MapEditorSigns.update();
    MapEditorBattlers.update();
    MapEditorEvents.update();
    
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
        e.preventDefault();
        tileChange(e);
      });
      
      e.preventDefault();

      mapEditorCanvas.onMouseUp.listen((MouseEvent e) => mouseMoveStream.cancel());
      mapEditorCanvas.onMouseLeave.listen((MouseEvent e) {
        EventTarget eventTarget = e.relatedTarget;
        if(eventTarget is DivElement && eventTarget.id == "tooltip") {
          // don't stop changing tiles, we just collided with the tooltip
          return;
        } else {
          mouseMoveStream.cancel();
        }
      });
    });
    
    mapEditorSpriteSelectorCanvas.onClick.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      selectSprite(y*Sprite.spriteSheetSize + x);
    });
  }
  
  static void tileChange(MouseEvent e) {
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
    
    List<Character> characters = [];
    for(Character character in World.characters.values) {
      if(character.map == Main.world.curMap)
        characters.add(character);
    }
    
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
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        renderStaticSprite(
          mapEditorCanvasContext, tile.sprite.id,
          tile.sprite.posX.round(), tile.sprite.posY.round()
        );
      }
    }
    
    renderColoredTiles();
    
    if(shouldExport) {
      Editor.export();
    }
  }
  
  static void renderColoredTiles() {
    Map<String, Map<String, int>> colorTrackers = {};
    double alpha = 0.15;
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        int x = tile.sprite.posX.round();
        int y = tile.sprite.posY.round();
        String key = "${x},${y}";
        
        if(colorTrackers[key] == null) {
          colorTrackers[key] = {
            "colorCount": 0,
            "numberDone": 0,
            "solid": 0,
            "layered": 0,
            "encounter": 0,
            "character": 0,
            "warp": 0,
            "sign": 0,
            "event": 0,
            "x": x,
            "y": y
          };
        }
        
        Map<String, int> colorTracker = colorTrackers[key];
        
        if(tile.solid == true && colorTracker["solid"] == 0) {
          colorTracker["colorCount"] += 1;
          colorTracker["solid"] = 1;
        }
        
        if(tile.layered == true && colorTracker["layered"] == 0) {
          colorTracker["colorCount"] += 1;
          colorTracker["layered"] = 1;
        }
        
        if(tile is EncounterTile && colorTracker["encounter"] == 0) {
          colorTracker["colorCount"] += 1;
          colorTracker["encounter"] = 1;
        }
        
        if(tile is WarpTile && colorTracker["warp"] == 0) {
          colorTracker["colorCount"] += 1;
          colorTracker["warp"] = 1;
        }
        
        if(tile is Sign && colorTracker["sign"] == 0) {
          colorTracker["colorCount"] += 1;
          colorTracker["sign"] = 1;
        }
        
        if(tile is EventTile && colorTracker["event"] == 0) {
          colorTracker["colorCount"] += 1;
          colorTracker["event"] = 1;
        }
      }
    }
    
    World.characters.forEach((String key, Character character) {
      if(character.map != Main.world.curMap)
        return;
      
      int x = character.mapX;
      int y = character.mapY;
      String key = "${x},${y}";
      
      if(colorTrackers[key] == null) {
        colorTrackers[key] = {
          "colorCount": 0,
          "numberDone": 0,
          "solid": 0,
          "layered": 0,
          "encounter": 0,
          "character": 0,
          "warp": 0,
          "sign": 0,
          "event": 0,
          "x": x,
          "y": y
        };
      }
      
      Map<String, int> colorTracker = colorTrackers[key];
      
      colorTracker["colorCount"] += 1;
      colorTracker["character"] = 1;
    });
    
    for(int y=0; y<Main.world.maps[Main.world.curMap].tiles.length; y++) {
      for(int x=0; x<Main.world.maps[Main.world.curMap].tiles.first.length; x++) {
        String key = "${x},${y}";
                
        Map<String, int> colorTracker = colorTrackers[key];
        
        if(colorTracker == null)
          continue;
        
        // solid
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["solid"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            255, 0, 0, alpha
          );
        
        // character
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["character"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            0, 0, 255, alpha
          );
        
        // layered
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["layered"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            0, 150, 255, alpha
          );
        
        // encounter
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["encounter"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            200, 0, 255, alpha
          );
        
        // warp
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["warp"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            0, 255, 0, alpha
          );
        
        // sign
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["sign"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            255, 255, 0, alpha
          );
        
        // event
        colorTracker["numberDone"] = outlineTilePart(
            x, y,
            colorTracker["event"] == 1,
            colorTracker["colorCount"], colorTracker["numberDone"],
            255, 128, 0, alpha
          );
      }
    }
  }
  
  static int outlineTilePart(int x, int y, bool should, int colorCount, int numberDone, int r, int g, int b, double a) {
    if(should) {
      if(colorCount == 1) {
        outlineTile(x, y, r, g, b, a);
      } else if(colorCount == 2) {
        if(numberDone == 0) {
          outlineTile(x, y, r, g, b, a, 1);
          outlineTile(x, y, r, g, b, a, 3);
        } else {
          outlineTile(x, y, r, g, b, a, 2);
          outlineTile(x, y, r, g, b, a, 4);
        }
      } else {
        if(numberDone == 0) {
          outlineTile(x, y, r, g, b, a, 1);
        } else if(numberDone == 1) {
          outlineTile(x, y, r, g, b, a, 2);
        } else if(numberDone == 2) {
          outlineTile(x, y, r, g, b, a, 3);
        } else if(numberDone == 3) {
          outlineTile(x, y, r, g, b, a, 4);
        }
      }
      
      numberDone += 1;
    }
    
    return numberDone;
  }
  
  static void outlineTile(int posX, int posY, int r, int g, int b, double a, [int quadrant = 0]) {
    if(!Editor.highlightSpecialTiles)
      return;
    
    mapEditorCanvasContext.beginPath();
    if(quadrant == 0) {
      // the whole tile
      int
        x = (posX * Sprite.scaledSpriteSize).round(),
        y = (posY * Sprite.scaledSpriteSize).round();
      
      mapEditorCanvasContext.moveTo(x, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x, y);
      
      mapEditorCanvasContext.setFillColorRgb(r, g, b, a);
      mapEditorCanvasContext.fillRect(x, y, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    } else if(quadrant == 1) {
      // top left
      int
        x = (posX * Sprite.scaledSpriteSize).round(),
        y = (posY * Sprite.scaledSpriteSize).round();
      
      mapEditorCanvasContext.moveTo(x, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize / 2, y);
      
      mapEditorCanvasContext.moveTo(x, y);
      mapEditorCanvasContext.lineTo(x, y + Sprite.scaledSpriteSize / 2);
      
      mapEditorCanvasContext.setFillColorRgb(r, g, b, a);
      mapEditorCanvasContext.fillRect(x, y, Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2);
    } else if(quadrant == 2) {
      // bottom left
      int
        x = (posX * Sprite.scaledSpriteSize).round(),
        y = (posY * Sprite.scaledSpriteSize).round();
      
      mapEditorCanvasContext.moveTo(x + Sprite.scaledSpriteSize, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize / 2);
      
      mapEditorCanvasContext.moveTo(x + Sprite.scaledSpriteSize, y);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize / 2, y);
      
      mapEditorCanvasContext.setFillColorRgb(r, g, b, a);
      mapEditorCanvasContext.fillRect(x + Sprite.scaledSpriteSize / 2, y, Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2);
    } else if(quadrant == 3) {
      // top right
      int
        x = (posX * Sprite.scaledSpriteSize).round(),
        y = (posY * Sprite.scaledSpriteSize).round();
      
      mapEditorCanvasContext.moveTo(x, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize / 2, y + Sprite.scaledSpriteSize);
      
      mapEditorCanvasContext.moveTo(x, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x, y + Sprite.scaledSpriteSize / 2);
      
      mapEditorCanvasContext.setFillColorRgb(r, g, b, a);
      mapEditorCanvasContext.fillRect(x, y + Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2);
    } else if(quadrant == 4) {
      // bottom right
      int
        x = (posX * Sprite.scaledSpriteSize).round(),
        y = (posY * Sprite.scaledSpriteSize).round();
      
      mapEditorCanvasContext.moveTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize / 2, y + Sprite.scaledSpriteSize);
      
      mapEditorCanvasContext.moveTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize);
      mapEditorCanvasContext.lineTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize / 2);
      
      mapEditorCanvasContext.setFillColorRgb(r, g, b, a);
      mapEditorCanvasContext.fillRect(x + Sprite.scaledSpriteSize / 2, y + Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2);
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
      MapEditorEvents.export(jsonMap, key);

      MapEditorBattlers.export(exportJson["maps"][key], key);
      
      exportJson["maps"][key]['tiles'] = jsonMap;
      if(Main.world.startMap == key) {
        exportJson["maps"][key]['startMap'] = true;
        exportJson["maps"][key]['startX'] = Main.world.startX;
        exportJson["maps"][key]['startY'] = Main.world.startY;
      }
    }
  }
}