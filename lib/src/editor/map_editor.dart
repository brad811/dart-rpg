library dart_rpg.map_editor;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor_characters.dart';
import 'package:dart_rpg/src/editor/map_editor_events.dart';
import 'package:dart_rpg/src/editor/map_editor_maps.dart';
import 'package:dart_rpg/src/editor/map_editor_signs.dart';
import 'package:dart_rpg/src/editor/map_editor_warps.dart';
import 'package:dart_rpg/src/editor/map_editor_battlers.dart';

class MapEditor {
  static CanvasElement
    mapEditorCanvas,
    mapEditorSpriteSelectorCanvas,
    mapEditorSelectedSpriteCanvas;
  
  static CanvasRenderingContext2D
    mapEditorCanvasContext,
    mapEditorSpriteSelectorCanvasContext,
    mapEditorSelectedSpriteCanvasContext;
  
  static List<String> mapEditorTabs = ["maps", "tiles", "map_characters", "warps", "signs", "battlers", "events"];
  
  static int
    mapEditorCanvasWidth = 100,
    mapEditorCanvasHeight = 100,
    lastHoverX = -1,
    lastHoverY = -1,
    lastChangeX = -1,
    lastChangeY = -1;
  
  static List<bool> layerVisible = [];
  
  static List<List<Tile>> renderList;
  static int selectedTile, previousSelectedTile;

  static List<String> availableTools = ["select", "brush", "erase", "fill", "stamp"];
  static String selectedTool = "select";
  
  static DivElement tooltip, tileInfo;
  
  static void init(Function callback) {
    mapEditorCanvas = querySelector('#editor_main_canvas');
    mapEditorCanvasContext = mapEditorCanvas.getContext("2d");
    
    mapEditorSpriteSelectorCanvas = querySelector('#editor_sprite_canvas');
    mapEditorSpriteSelectorCanvasContext = mapEditorSpriteSelectorCanvas.getContext("2d");
    
    mapEditorSelectedSpriteCanvas = querySelector('#editor_selected_sprite_canvas');
    mapEditorSelectedSpriteCanvasContext = mapEditorSelectedSpriteCanvas.getContext("2d");
    
    if(window.devicePixelRatio != 1.0) {
      ElementList<Element> canvasElements = querySelectorAll("canvas");
      
      for(int i=0; i<canvasElements.length; i++) {
        Main.fixImageSmoothing(canvasElements[i], (canvasElements[i] as CanvasElement).width, (canvasElements[i] as CanvasElement).height);
      }
    }
    
    for(int i=0; i<World.layers.length; i++) {
      layerVisible.add(true);
    }
    
    callback();
  }
  
  static void setUp() {
    Editor.setUpTabs(mapEditorTabs);
    
    // resize the sprite picker to match the loaded sprite sheet image
    Main.fixImageSmoothing(
      MapEditor.mapEditorSpriteSelectorCanvas,
      (Main.spritesImage.width * Sprite.spriteScale).round(),
      (Main.spritesImage.height * Sprite.spriteScale).round()
    );
    
    // picked sprite canvas
    Main.fixImageSmoothing(
      MapEditor.mapEditorSelectedSpriteCanvas,
      (Sprite.scaledSpriteSize).round(),
      (Sprite.scaledSpriteSize).round()
    );
    
    setUpToolSelectors();
    
    MapEditorMaps.setUp();
    MapEditorCharacters.setUp();
    MapEditorWarps.setUp();
    MapEditorSigns.setUp();
    MapEditorBattlers.setUp();
    MapEditorEvents.setUp();
    
    setUpSpritePicker();

    selectTool("select");
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

  static void selectTool(String newTool) {
    availableTools.forEach((String curTool) {
      querySelector("#tool_selector_" + curTool).classes.remove("selected");

      if(curTool == newTool) {
        querySelector("#tool_selector_" + curTool).classes.add("selected");
      }
    });

    if(newTool == "erase") {
      previousSelectedTile = selectedTile;
      MapEditor.selectSprite(-1);
    } else {
      selectedTile = previousSelectedTile;
      MapEditor.selectSprite(selectedTile);
    }

    if(selectedTool == "select" && newTool != "select") {
      tileInfo.style.display = "none";
      MapEditor.updateMap();
    }

    selectedTool = newTool;
  }
  
  static void setUpToolSelectors() {
    availableTools.forEach((String curTool) {
      querySelector("#tool_selector_" + curTool).onClick.listen((MouseEvent e) {
        selectTool(curTool);
      });
    });
  }
  
  static void setUpSpritePicker() {
    mapEditorSpriteSelectorCanvasContext.fillStyle = "#ff00ff";
    mapEditorSpriteSelectorCanvasContext.fillRect(
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
        renderStaticSprite(mapEditorSpriteSelectorCanvasContext, y*Sprite.spriteSheetWidth + x, col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    // TODO: make this a different value?
    selectedTile = 66;
    previousSelectedTile = 66;
    MapEditor.selectSprite(66);
    
    mapEditorCanvas.onClick.listen(changeTile);
    
    tooltip = querySelector('#tooltip');
    tileInfo = querySelector('#tile_info');
    /*StreamSubscription mouseMoveStream = */
    mapEditorCanvas.onMouseMove.listen(hoverTile);
    
    mapEditorCanvas.onMouseLeave.listen((MouseEvent e) {
      lastHoverX = -1;
      lastHoverY = -1;
      tooltip.style.display = "none";

      if(selectedTool != "select") {
        MapEditor.updateMap();
      }
    });
    
    mapEditorCanvas.onMouseDown.listen((MouseEvent e) {
      if(selectedTool == "select") {
        return;
      }

      StreamSubscription mouseMoveStream = mapEditorCanvas.onMouseMove.listen((MouseEvent e) {
        e.preventDefault();
        changeTile(e);
      });
      
      e.preventDefault();

      mapEditorCanvas.onMouseUp.listen((MouseEvent e) {
        mouseMoveStream.cancel();
        lastChangeX = -1;
        lastChangeY = -1;
      });
      mapEditorCanvas.onMouseLeave.listen((MouseEvent e) {
        EventTarget eventTarget = e.relatedTarget;
        if(eventTarget is DivElement && eventTarget.id == "tooltip") {
          // don't stop changing tiles, we just collided with the tooltip
          return;
        } else {
          mouseMoveStream.cancel();
          lastChangeX = -1;
          lastChangeY = -1;
        }
      });
    });
    
    mapEditorSpriteSelectorCanvas.onClick.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
      MapEditor.selectSprite(y*Sprite.spriteSheetWidth + x);
      previousSelectedTile = y*Sprite.spriteSheetWidth + x;
      
      if(querySelector("#tool_selector_erase").classes.contains("selected")) {
        selectTool("brush");
      }
    });
  }
  
  static void hoverTile(MouseEvent e) {
    if(selectedTool == "select") {
      return;
    }

    int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
    int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
    
    if(y >= Main.world.maps[Main.world.curMap].tiles.length || x >= Main.world.maps[Main.world.curMap].tiles[0].length) {
      return;
    }
    
    if(selectedTool != "select") {
      // update the tooltip
      tooltip.style.display = "block";
      tooltip.style.left = "${e.page.x + 30}px";
      tooltip.style.top = "${e.page.y - 10}px";
      tooltip.text = "x: ${x}, y: ${y}";
    }
    
    if(x == lastHoverX && y == lastHoverY) {
      return;
    }
    
    lastHoverX = x;
    lastHoverY = y;
    
    MapEditor.updateMap();
    
    int
      width = 1,
      height = 1;
    
    if(selectedTool == "stamp") {
      // TODO: only do this when these values change, not on every tile hover
      width = Editor.getTextInputIntValue("#stamp_tool_width", 1);
      height = Editor.getTextInputIntValue("#stamp_tool_height", 1);
    }

    for(int i=0; i<width; i++) {
      for(int j=0; j<height; j++) {
        // render the tile as it would appear with the selected tile applied to the selected layer
        mapEditorCanvasContext.fillStyle = "#ff00ff";
        mapEditorCanvasContext.fillRect(Sprite.scaledSpriteSize * (x+i), Sprite.scaledSpriteSize * (y+j), Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
        
        int selectedLayer = Editor.getRadioInputIntValue("[name='layer']:checked", 0);
        
        for(int layer=0; layer<World.layers.length; layer++) {
          if(selectedLayer == layer) {
            renderStaticSprite(mapEditorCanvasContext, selectedTile + j*Sprite.spriteSheetWidth + i, x+i, y+j);
          } else {
            if(y+j >= Main.world.maps[Main.world.curMap].tiles.length ||
                x+i >= Main.world.maps[Main.world.curMap].tiles[y+j].length) {
              continue;
            }

            Tile tile = Main.world.maps[Main.world.curMap].tiles[y+j][x+i][layer];
            
            if(tile != null) {
              int id = Main.world.maps[Main.world.curMap].tiles[y+j][x+i][layer].sprite.id;
              renderStaticSprite(mapEditorCanvasContext, id, x+i, y+j);
            }
          }
        }
      }
    }
    
    outlineSelectedTiles(x, y, width, height);
    
  }

  static void outlineSelectedTiles(x, y, width, height) {
    mapEditorCanvasContext.lineWidth = 4;
    mapEditorCanvasContext.setStrokeColorRgb(255, 255, 255, 1.0);
    mapEditorCanvasContext.strokeRect(
      Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2,
      Sprite.scaledSpriteSize * width + 4, Sprite.scaledSpriteSize * height + 4
    );
    
    mapEditorCanvasContext.lineWidth = 2;
    mapEditorCanvasContext.setStrokeColorRgb(0, 0, 0, 1.0);
    mapEditorCanvasContext.strokeRect(
      Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2,
      Sprite.scaledSpriteSize * width + 4, Sprite.scaledSpriteSize * height + 4
    );
  }
  
  static void changeTile(MouseEvent e) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
    int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
    
    if(y >= mapTiles.length || x >= mapTiles[0].length)
      return;
    
    if(x == lastChangeX && y == lastChangeY) {
      return;
    }
    
    lastChangeX = x;
    lastChangeY = y;
    
    // TODO: maybe save these and change them onInputChange
    int layer = Editor.getRadioInputIntValue("[name='layer']:checked", 0);
    bool solid = Editor.getCheckboxInputBoolValue("#solid");
    bool layered = Editor.getCheckboxInputBoolValue("#layered");
    bool encounter = Editor.getCheckboxInputBoolValue("#encounter");
    
    if(selectedTile == -1) {
      mapTiles[y][x][layer] = null;
    } else if(encounter) {
      // TODO: fill
      mapTiles[y][x][layer] = new EncounterTile(
        new Sprite.int(selectedTile, x, y),
        layered
      );
    } else {
      if(selectedTool == "fill") {
        List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
        int tileBefore;
        if(mapTiles[y][x][layer] != null) {
          tileBefore = mapTiles[y][x][layer].sprite.id;
        } else {
          tileBefore = -1;
        }
        floodFill(mapTiles, x, y, layer, tileBefore, solid, layered);
      } else if(selectedTool == "stamp") {
        int height = Editor.getTextInputIntValue("#stamp_tool_height", 1);
        int width = Editor.getTextInputIntValue("#stamp_tool_width", 1);
        
        for(int i=0; i<width; i++) {
          for(int j=0; j<height; j++) {
            mapTiles[y+j][x+i][layer] = new Tile(
              solid,
              new Sprite.int(selectedTile + (j*Sprite.spriteSheetWidth) + i, x+i, y+j)
            );
          }
        }
      } else if(selectedTool == "select") {
        tooltip.style.display = "none";

        String html = "";

        html += 
          "Tile Info<br />" +
          "<hr />" +
          "X: ${x}<br />" +
          "Y: ${y}<br />";

        if(mapTiles[y][x][3] != null) {
          html +=
            "<hr />" +
            "Above<br />" +
            "Sprite id: ${mapTiles[y][x][3].sprite.id}<br />" +
            "Solid: ${mapTiles[y][x][3].solid}<br />";
        }

        if(mapTiles[y][x][2] != null) {
          html +=
            "<hr />" +
            "Player<br />" +
            "Sprite id: ${mapTiles[y][x][2].sprite.id}<br />" +
            "Solid: ${mapTiles[y][x][2].solid}<br />";
        }

        if(mapTiles[y][x][1] != null) {
          html +=
            "<hr />" +
            "Below<br />" +
            "Sprite id: ${mapTiles[y][x][1].sprite.id}<br />" +
            "Solid: ${mapTiles[y][x][1].solid}<br />";
        }

        if(mapTiles[y][x][0] != null) {
          html +=
            "<hr />" +
            "Ground<br />" +
            "Sprite id: ${mapTiles[y][x][0].sprite.id}<br />" +
            "Solid: ${mapTiles[y][x][0].solid}<br />";
        }

        tileInfo.setInnerHtml(html);

        tileInfo.style.display = "block";
        tileInfo.style.left = "${(x+1) * Sprite.scaledSpriteSize + 5}px";
        tileInfo.style.top = "${(y) * Sprite.scaledSpriteSize}px";
        tileInfo.style.width = "150px";
      } else {
        mapTiles[y][x][layer] = new Tile(
          solid,
          new Sprite.int(selectedTile, x, y),
          layered
        );
      }
    }

    MapEditor.updateMap(shouldExport: true);
    
    if(selectedTool == "select") {
      outlineSelectedTiles(x, y, 1, 1);
    }
  }
  
  static void floodFill(List<List<List<Tile>>> mapTiles, int x, int y, int layer, int tileBefore, bool solid, bool layered) {
    if(selectedTile == tileBefore) {
      return;
    } else if(mapTiles[y][x][layer] != null && mapTiles[y][x][layer].sprite.id != tileBefore) {
      return;
    } else if(mapTiles[y][x][layer] == null && tileBefore != -1) {
      return;
    }
    
    // TODO: fill with attributes like solid and layered and encounter?
    if(mapTiles[y][x][layer] == null) {
      mapTiles[y][x][layer] = new Tile(
        solid,
        new Sprite.int(selectedTile, x, y),
        layered
      );
    } else {
      mapTiles[y][x][layer].sprite.id = selectedTile;
    }
    
    // north
    if(y > 0) {
      floodFill(mapTiles, x, y-1, layer, tileBefore, solid, layered);
    }
    
    // south
    if(y < mapTiles.length-1) {
      floodFill(mapTiles, x, y+1, layer, tileBefore, solid, layered);
    }
    
    // east
    if(x < mapTiles[y].length-1) {
      floodFill(mapTiles, x+1, y, layer, tileBefore, solid, layered);
    }
    
    // west
    if(x > 0) {
      floodFill(mapTiles, x-1, y, layer, tileBefore, solid, layered);
    }
  }
  
  static void updateMapCanvasSize() {
    if(
        mapEditorCanvas.width != mapEditorCanvasWidth * window.devicePixelRatio ||
        mapEditorCanvas.height != mapEditorCanvasHeight * window.devicePixelRatio) {
      Main.fixImageSmoothing(mapEditorCanvas, mapEditorCanvasWidth, mapEditorCanvasHeight);
    }
    
    int xSize = Main.world.maps[ Main.world.curMap ].tiles[0].length;
    int ySize = Main.world.maps[ Main.world.curMap ].tiles.length;
    
    querySelector("#cur_map_size").text = "(${ xSize } x ${ ySize })";
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
    
    // build list of tiles to be rendered
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
  
  static Map<String, int> newColorTracker(int x, int y) {
    return {
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
  
  static void renderColoredTiles() {
    if(!Editor.highlightSpecialTiles)
      return;
    
    Map<String, Map<String, int>> colorTrackers = {};
    double alpha = 0.15;
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        int x = tile.sprite.posX.round();
        int y = tile.sprite.posY.round();
        String key = "${x},${y}";
        
        if(colorTrackers[key] == null) {
          colorTrackers[key] = newColorTracker(x, y);
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
      }
    }
    
    MapEditorWarps.warps[Main.world.curMap].forEach((WarpTile warpTile) {
      int x = warpTile.sprite.posX.round();
      int y = warpTile.sprite.posY.round();
      String key = "${x},${y}";
      
      if(colorTrackers[key] == null) {
        colorTrackers[key] = newColorTracker(x, y);
      }
      
      Map<String, int> colorTracker = colorTrackers[key];
      
      if(colorTracker["warp"] == 0) {
        colorTracker["colorCount"] += 1;
        colorTracker["warp"] = 1;
      }
    });
    
    MapEditorSigns.signs[Main.world.curMap].forEach((Sign sign) {
      int x = sign.sprite.posX.round();
      int y = sign.sprite.posY.round();
      String key = "${x},${y}";
      
      if(colorTrackers[key] == null) {
        colorTrackers[key] = newColorTracker(x, y);
      }
      
      Map<String, int> colorTracker = colorTrackers[key];
      
      if(colorTracker["sign"] == 0) {
        colorTracker["colorCount"] += 1;
        colorTracker["sign"] = 1;
      }
    });
    
    MapEditorEvents.events[Main.world.curMap].forEach((EventTile eventTile) {
      int x = eventTile.sprite.posX.round();
      int y = eventTile.sprite.posY.round();
      String key = "${x},${y}";
      
      if(colorTrackers[key] == null) {
        colorTrackers[key] = newColorTracker(x, y);
      }
      
      Map<String, int> colorTracker = colorTrackers[key];
      
      if(colorTracker["event"] == 0) {
        colorTracker["colorCount"] += 1;
        colorTracker["event"] = 1;
      }
    });
    
    World.characters.forEach((String key, Character character) {
      if(character.map != Main.world.curMap)
        return;
      
      int x = character.mapX;
      int y = character.mapY;
      String key = "${x},${y}";
      
      if(colorTrackers[key] == null) {
        colorTrackers[key] = newColorTracker(x, y);
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
    mapEditorCanvasContext.lineWidth = 1;
    mapEditorCanvasContext.stroke();
  }
  
  static void selectSprite(int id) {
    selectedTile = id;
    mapEditorSelectedSpriteCanvasContext.fillStyle = "#ff00ff";
    mapEditorSelectedSpriteCanvasContext.fillRect(0, 0, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    renderStaticSprite(mapEditorSelectedSpriteCanvasContext, id, 0, 0);
  }
  
  static void renderStaticSprite(CanvasRenderingContext2D ctx, int id, int posX, int posY) {
    ctx.drawImageScaledFromSource(
      Main.spritesImage,
      
      Sprite.pixelsPerSprite * (id%Sprite.spriteSheetWidth), // sx
      Sprite.pixelsPerSprite * (id/Sprite.spriteSheetWidth).floor(), // sy
      
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
                
                // if we're on the ground layer
                if(k == 0) {
                  // check if any layer on this tile is an encounter tile
                  for(int l=0; l<World.layers.length; l++) {
                    if(mapTiles[y][x][l] is EncounterTile) {
                      jsonObject["encounter"] = true;
                      break;
                    }
                  }
                }
                
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
    }
  }
}