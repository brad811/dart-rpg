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

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_characters.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_events.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_maps.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_signs.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_tile_info.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_tiles.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_warps.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_battlers.dart';

import 'package:react/react.dart';

// TODO: allow for dynamic number of layers

var mapEditorMaps = registerComponent(() => new MapEditorMaps());
var mapEditorTiles = registerComponent(() => new MapEditorTiles());
var mapEditorCharacters = registerComponent(() => new MapEditorCharacters());
var mapEditorWarps = registerComponent(() => new MapEditorWarps());
var mapEditorSigns = registerComponent(() => new MapEditorSigns());
var mapEditorBattlers = registerComponent(() => new MapEditorBattlers());
var mapEditorEvents = registerComponent(() => new MapEditorEvents());
var mapEditorTileInfo = registerComponent(() => new MapEditorTileInfo());

class MapEditor extends Component {
  static CanvasElement mapEditorCanvas;
  
  static CanvasRenderingContext2D mapEditorCanvasContext;
  
  static int
    mapEditorCanvasWidth = 100,
    mapEditorCanvasHeight = 100,
    lastHoverX = -1,
    lastHoverY = -1,
    lastChangeX = -1,
    lastChangeY = -1,
    lastTileInfoX = -1,
    lastTileInfoY = -1,
    lastTileInfoSizeX = -1,
    lastTileInfoSizeY = -1;

  static bool shouldHover = true;
  
  static List<bool> layerVisible = [];
  
  static List<List<Tile>> renderList;
  
  static DivElement tooltip, tileInfo;

  static String selectedTool = "select", previousSelectedTool;
  static int selectedTile = -1, previousSelectedTile = -1;
  static int selectedLayer = 0;
  static bool
    brushSolid = false,
    brushLayered = false,
    brushEncounter = false;

  static Function moveCallback = null;
  static StreamSubscription bodyMoveListener = null;
  static String moveModeMapBefore = null;

  static List<List<List<int>>> stampTiles = [];

  static Map<String, List<WarpTile>> warps = {};
  static Map<String, List<Sign>> signs = {};
  static Map<String, List<EventTile>> events = {};
  static bool specialTilesLoaded = false;

  StreamSubscription resizeListener;

  @override
  getInitialState() => {
    'selectedTab': 'maps'
  };

  @override
  componentWillMount() {
    if(!specialTilesLoaded) {
      loadSpecialTiles();
    }
  }

  static void loadSpecialTiles() {
    warps = {};
    signs = {};
    events = {};

    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;

      warps[key] = [];
      signs[key] = [];
      events[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer = 0; layer < World.layers.length; layer++) {
            if(mapTiles[y][x][layer] is WarpTile) {
              WarpTile mapWarpTile = mapTiles[y][x][layer];
              WarpTile warpTile = new WarpTile(
                  mapWarpTile.solid,
                  new Sprite(
                    mapWarpTile.sprite.id,
                    mapWarpTile.sprite.posX,
                    mapWarpTile.sprite.posY
                  ),
                  mapWarpTile.destMap,
                  mapWarpTile.destX,
                  mapWarpTile.destY
                );
              warps[key].add(warpTile);
            } else if(mapTiles[y][x][layer] is Sign) {
              Sign mapSignTile = mapTiles[y][x][layer];
              Sign signTile = new Sign(
                  mapSignTile.solid,
                  new Sprite(
                    mapSignTile.sprite.id,
                    mapSignTile.sprite.posX,
                    mapSignTile.sprite.posY
                  ),
                  mapSignTile.textEvent.pictureSpriteId,
                  mapSignTile.textEvent.text
                );
              signs[key].add(signTile);
            } else if(mapTiles[y][x][layer] is EventTile) {
              EventTile mapEventTile = mapTiles[y][x][layer];
              EventTile eventTile = new EventTile(
                  mapEventTile.gameEventChain,
                  mapEventTile.runOnce,
                  mapEventTile.runOnEnter,
                  mapEventTile.runOnInteract,
                  new Sprite(
                    mapEventTile.sprite.id,
                    mapEventTile.sprite.posX,
                    mapEventTile.sprite.posY
                  )
                );
              events[key].add(eventTile);
            }
          }
        }
      }
    }

    specialTilesLoaded = true;
  }

  @override
  componentDidMount() {
    resizeListener = window.onResize.listen(handleResize);
    handleResize(null);

    mapEditorCanvas = querySelector('#editor_main_canvas');
    mapEditorCanvasContext = mapEditorCanvas.getContext("2d");
    
    if(window.devicePixelRatio != 1.0) {
      ElementList<Element> canvasElements = querySelectorAll("canvas");
      
      for(int i=0; i<canvasElements.length; i++) {
        Main.fixImageSmoothing(
          canvasElements[i],
          (canvasElements[i] as CanvasElement).width,
          (canvasElements[i] as CanvasElement).height
        );
      }
    }
    
    for(int i=0; i<World.layers.length; i++) {
      layerVisible.add(true);
    }
    
    tooltip = querySelector('#tooltip');
    tileInfo = querySelector('#tile_info');

    updateMap();
  }

  @override
  componentDidUpdate(Map prevProps, Map prevState) {
    updateMap();
  }

  void update() {
    setState({});
  }

  void handleResize(Event e) {
    Element leftHalf = querySelector('#left_half');
    if(leftHalf != null) {
      leftHalf.style.width = "${window.innerWidth - 562}px";
      leftHalf.style.height = "${window.innerHeight - 60}px";
    }
  }

  static Timer debounceTimer, debounceExportTimer;
  static Duration debounceDelay = new Duration(milliseconds: 250);
  static Duration debounceExportDelay = new Duration(milliseconds: 500);

  void debounceUpdate({Function callback}) {
    if(debounceTimer != null) {
      debounceTimer.cancel();
    }

    debounceTimer = new Timer(debounceDelay, () {
      update();
      Editor.export();
      if(callback != null) {
        callback();
      }
    });
  }

  void handleMainCanvasMouseDown(SyntheticMouseEvent se) {
    MouseEvent e = se.nativeEvent;

    e.preventDefault();

    int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
    int y = (e.offset.y/Sprite.scaledSpriteSize).floor();

    if(selectedTool == "select") {
      handleMainCanvasSelectMouseDown(x, y);
      return;
    } else if(selectedTool == "move") {
      if(moveCallback != null) {
        if(moveModeMapBefore != null && moveModeMapBefore != Main.world.curMap) {
          changeMap(moveModeMapBefore);
        }

        moveCallback(x, y);
        MapEditor.updateMap();
      } else {
        print("moveCallback was null!");
      }

      return;
    }

    changeTile(
      selectedTile,
      x, y, MapEditor.selectedLayer,
      MapEditor.brushSolid,
      MapEditor.brushLayered,
      MapEditor.brushEncounter
    );

    StreamSubscription
      mouseMoveStream,
      mouseUpStream,
      mouseLeaveStream;

    mouseMoveStream = mapEditorCanvas.onMouseMove.listen((MouseEvent e) {
      e.preventDefault();
      
      if(e is SyntheticMouseEvent) {
        e = (e as SyntheticMouseEvent).nativeEvent;
      }

      int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor();

      changeTile(
        selectedTile,
        x, y, MapEditor.selectedLayer,
        MapEditor.brushSolid,
        MapEditor.brushLayered,
        MapEditor.brushEncounter
      );
    });

    mouseUpStream = mapEditorCanvas.onMouseUp.listen((MouseEvent e) {
      mouseMoveStream.cancel();
      mouseUpStream.cancel();
      mouseLeaveStream.cancel();
      lastChangeX = -1;
      lastChangeY = -1;
    });

    mouseLeaveStream = mapEditorCanvas.onMouseLeave.listen((MouseEvent e) {
      EventTarget eventTarget = e.relatedTarget;
      if(eventTarget is DivElement && eventTarget.id == "tooltip") {
        // don't stop changing tiles, we just collided with the tooltip
        return;
      } else {
        mouseMoveStream.cancel();
        mouseUpStream.cancel();
        mouseLeaveStream.cancel();
        lastChangeX = -1;
        lastChangeY = -1;
      }
    });
  }

  void handleMainCanvasSelectMouseDown(int x, int y) {
    if(tileInfo.getComputedStyle().getPropertyValue("display") != "none") {
      // user clicked away from selected tiles, so hide tile info
      tileInfo.style.display = "none";

      MapEditor.updateMap(
        oldPoint: new Point(lastTileInfoX, lastTileInfoY),
        newPoint: new Point(lastTileInfoX, lastTileInfoY),
        size: new Point(lastTileInfoSizeX, lastTileInfoSizeY)
      );

      lastTileInfoX = -1;
      lastTileInfoY = -1;
      
      return;
    }

    shouldHover = false;

    int startX = x;
    int startY = y;

    int lastX = -1, lastY = -1;

    int minX = x, minY = y, sizeX = 1, sizeY = 1;

    MapEditor.updateMap(
      oldPoint: new Point(lastTileInfoX, lastTileInfoY),
      newPoint: new Point(lastTileInfoX, lastTileInfoY),
      size: new Point(lastTileInfoSizeX, lastTileInfoSizeY)
    );

    StreamSubscription
      onMouseMoveStream,
      onMouseUpListener,
      onMouseLeaveListener;

    onMouseMoveStream = mapEditorCanvas.onMouseMove.listen((MouseEvent e) {
      e.preventDefault();

      // add the tile and re-render
      int newX = (e.offset.x/Sprite.scaledSpriteSize).floor();
      int newY = (e.offset.y/Sprite.scaledSpriteSize).floor();

      if(newX == lastX && newY == lastY) {
        return;
      }

      // update with old size
      MapEditor.updateMap(
        oldPoint: new Point(minX, minY),
        newPoint: new Point(newX, newY),
        size: new Point(sizeX, sizeY)
      );

      if(newX < startX) {
        minX = newX;
        sizeX = 1 + startX - newX;
      } else if(newX > startX) {
        minX = startX;
        sizeX = 1 + newX - startX;
      } else {
        minX = startX;
        sizeX = 1;
      }

      if(newY < startY) {
        minY = newY;
        sizeY = 1 + startY - newY;
      } else if(newY > startY) {
        minY = startY;
        sizeY = 1 + newY - startY;
      } else {
        minY = startY;
        sizeY = 1;
      }

      // update with new size
      MapEditor.updateMap(
        oldPoint: new Point(minX, minY),
        newPoint: new Point(newX, newY),
        size: new Point(sizeX, sizeY)
      );

      lastX = newX;
      lastY = newY;

      lastTileInfoSizeX = sizeX;
      lastTileInfoSizeY = sizeY;
      lastTileInfoX = minX;
      lastTileInfoY = minY;

      outlineSelectedTiles(mapEditorCanvasContext, minX, minY, sizeX, sizeY);
    });

    Function finish = (MouseEvent e) {
      shouldHover = true;

      onMouseMoveStream.cancel();
      onMouseUpListener.cancel();
      onMouseLeaveListener.cancel();

      // update map?

      // check if we're unselecting by clicking the currently selected region
      if(
        sizeX == 1 && sizeY == 1 &&
        (lastTileInfoX <= minX && minX <= lastTileInfoX + lastTileInfoSizeX - 1) &&
        (lastTileInfoY <= minY && minY <= lastTileInfoY + lastTileInfoSizeY - 1)
      ) {
        lastTileInfoX = -1;
        lastTileInfoY = -1;
        lastTileInfoSizeX = -1;
        lastTileInfoSizeY = -1;

        tileInfo.style.display = "none";
        updateMap();
      } else {
        updateMap(
          oldPoint: new Point(lastTileInfoX, lastTileInfoY),
          newPoint: new Point(minX, minY),
          size: new Point(lastTileInfoSizeX, lastTileInfoSizeY)
        );

        lastTileInfoSizeX = sizeX;
        lastTileInfoSizeY = sizeY;
        lastTileInfoX = minX;
        lastTileInfoY = minY;

        outlineSelectedTiles(mapEditorCanvasContext, minX, minY, sizeX, sizeY);
        showTileInfo(minX, minY, sizeX, sizeY);
      }
    };

    onMouseUpListener = mapEditorCanvas.onMouseUp.listen(finish);
    onMouseLeaveListener = mapEditorCanvas.onMouseLeave.listen(finish);
  }

  static void hoverTile(SyntheticMouseEvent se) {
    if(!shouldHover) {
      return;
    }

    MouseEvent e = se.nativeEvent;

    // tileInfo.style.display != "none"
    if(tileInfo.getComputedStyle().getPropertyValue("display") != "none") {
      return;
    }

    int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
    int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
    
    if(y >= Main.world.maps[Main.world.curMap].tiles.length || x >= Main.world.maps[Main.world.curMap].tiles[0].length) {
      return;
    }
    
    if(selectedTool != "select" && Editor.shouldShowTooltip) {
      // update the tooltip
      tooltip.style.display = "block";
      tooltip.style.left = "${e.page.x + 30}px";
      tooltip.style.top = "${e.page.y - 10}px";
      tooltip.text = "x: ${x}, y: ${y}";
    }
    
    if(x == lastHoverX && y == lastHoverY) {
      return;
    }

    int
      width = 1,
      height = 1;
    
    if(selectedTool == "stamp") {
      // TODO: only do this when these values change, not on every tile hover
      width = MapEditor.stampTiles[0][0].length;
      height = MapEditor.stampTiles[0].length;
    }

    MapEditor.updateMap(
      oldPoint: new Point(lastHoverX, lastHoverY),
      newPoint: new Point(x, y),
      size: new Point(width, height)
    );

    if(selectedTool != "select" && selectedTool != "move") { // select and move tools should not show change previews
      for(int i=0; i<width; i++) {
        for(int j=0; j<height; j++) {
          // render the tile as it would appear with the selected tile applied to the selected layer
          mapEditorCanvasContext.fillStyle = "#ff00ff";
          mapEditorCanvasContext.fillRect(
            Sprite.scaledSpriteSize * (x+i), Sprite.scaledSpriteSize * (y+j),
            Sprite.scaledSpriteSize, Sprite.scaledSpriteSize
          );
          
          for(int layer=0; layer<World.layers.length; layer++) {
            if(selectedLayer == layer) {
              if(selectedTool == "stamp") {
                if(MapEditor.stampTiles[0][j][i] != null) {
                  renderStaticSprite(mapEditorCanvasContext, MapEditor.stampTiles[0][j][i], x+i, y+j);
                }
              } else {
                renderStaticSprite(mapEditorCanvasContext, selectedTile + j*Sprite.spriteSheetWidth + i, x+i, y+j);
              }
            } else {
              if(y+j >= Main.world.maps[Main.world.curMap].tiles.length ||
                  x+i >= Main.world.maps[Main.world.curMap].tiles[y+j].length) {
                continue;
              }

              Tile tile = Main.world.maps[Main.world.curMap].tiles[y+j][x+i][layer];
              
              if(tile != null) {
                int id = tile.sprite.id;
                renderStaticSprite(mapEditorCanvasContext, id, x+i, y+j);
              }
            }
          }
        }
      }
    }
    
    outlineSelectedTiles(mapEditorCanvasContext, x, y, width, height);

    lastHoverX = x;
    lastHoverY = y;
    //MapEditor.updateMap();
  }

  static void selectTool(String newTool) {
    if(newTool == "erase") {
      MapEditor.previousSelectedTile = MapEditor.selectedTile;
      MapEditor.selectedTile = -1;
    } else {
      MapEditor.selectedTile = MapEditor.previousSelectedTile;
      MapEditor.selectedTile = MapEditor.selectedTile;
    }

    if(MapEditor.selectedTool == "select" && newTool != "select") {
      MapEditor.tileInfo.style.display = "none";
      lastTileInfoX = -1;
      lastTileInfoY = -1;
      MapEditor.updateMap();
    }

    MapEditor.selectedTool = newTool;

    MapEditor.lastChangeX = -1;
    MapEditor.lastChangeY = -1;

    previousSelectedTool = MapEditor.selectedTool;
  }

  static void outlineSelectedTiles(CanvasRenderingContext2D context, int x, int y, int width, int height) {
    context.lineWidth = 4;
    context.setStrokeColorRgb(255, 255, 255, 1.0);
    context.strokeRect(
      Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2,
      Sprite.scaledSpriteSize * width + 4, Sprite.scaledSpriteSize * height + 4
    );
    
    context.lineWidth = 2;
    context.setStrokeColorRgb(0, 0, 0, 1.0);
    context.strokeRect(
      Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2,
      Sprite.scaledSpriteSize * width + 4, Sprite.scaledSpriteSize * height + 4
    );
  }

  void changeMap(String newMap) {
    ref('tileInfo').setTile(0, 0, 0, 0);
    tileInfo.style.display = "none";
    lastTileInfoX = -1;
    lastTileInfoY = -1;
    Main.world.curMap = newMap;
    props['update']();
  }
  
  void showTileInfo(int x, int y, int sizeX, int sizeY) {
    tooltip.style.display = "none";

    // TODO: update tile_info
    ref('tileInfo').setTile(x, y, sizeX, sizeY);

    tileInfo.style.display = "block";
    tileInfo.style.left = "${(x + sizeX) * Sprite.scaledSpriteSize + 5}px";
    tileInfo.style.top = "${(y) * Sprite.scaledSpriteSize}px";
    tileInfo.style.width = "${150 + sizeX*Sprite.scaledSpriteSize}px";
  }

  static void changeTile(int spriteId, int x, int y, int layer, bool solid, bool layered, bool encounter) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    
    if(y >= mapTiles.length || x >= mapTiles[0].length)
      return;
    
    if(x == lastChangeX && y == lastChangeY && selectedTool != "select") {
      return;
    }
    
    lastChangeX = x;
    lastChangeY = y;

    if(selectedTool == "select") {
      selectTile(x, y);
    } else if(selectedTile == -1 && selectedTool != "stamp") {
      eraseTile(x, y, layer);
    } if(selectedTool == "fill") {
      fillTile(spriteId, x, y, layer, solid, layered, encounter);
    } else if(selectedTool == "stamp") {
      stampTile(x, y, layer, solid);
    } else {
      brushTile(spriteId, x, y, layer, solid, layered, encounter);
    }
  }

  static void selectTile(int x, int y) {
    // TODO: check if this conditional ever gets called
    if(lastTileInfoX == x && lastTileInfoY == y && tileInfo.getComputedStyle().getPropertyValue("display") != "none") {
      tileInfo.style.display = "none";
    } else {
      lastTileInfoX = x;
      lastTileInfoY = y;
      //showTileInfo(x, y);
    }

    MapEditor.updateMap(newPoint: new Point(x, y));
    outlineSelectedTiles(mapEditorCanvasContext, x, y, 1, 1);
  }

  static void eraseTile(int x, int y, int layer) {
    Main.world.maps[Main.world.curMap].tiles[y][x][layer] = null;
    MapEditor.updateMap(newPoint: new Point(x, y));
    Editor.debounceExport();
  }

  static void fillTile(int spriteId, int x, int y, int layer, bool solid, bool layered, bool encounter) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    int tileBefore;
    if(mapTiles[y][x][layer] != null) {
      tileBefore = mapTiles[y][x][layer].sprite.id;
    } else {
      tileBefore = -1;
    }

    floodFill(mapTiles, spriteId, x, y, layer, tileBefore, solid, layered, encounter);

    MapEditor.updateMap();
    Editor.debounceExport();
  }

  static void stampTile(int x, int y, int layer, bool solid) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;

    for(int j=0; j<MapEditor.stampTiles[0].length; j++) {
      if(y+j >= mapTiles.length)
        break;

      for(int i=0; i<MapEditor.stampTiles[0][j].length; i++) {
        if(x+i >= mapTiles[y+j].length)
          break;

        // MapEditor.stampTiles[k][j][i]
        if(MapEditor.stampTiles[0][j][i] == null) {
          mapTiles[y+j][x+i][layer] = null;
        } else {
          mapTiles[y+j][x+i][layer] = new Tile(
            solid,
            new Sprite.int(
              MapEditor.stampTiles[0][j][i], x+i, y+j
            )
          );
        }
      }
    }

    MapEditor.updateMap(newPoint: new Point(x, y));
    Editor.debounceExport();
  }

  static void brushTile(int spriteId, int x, int y, int layer, bool solid, bool layered, bool encounter) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;

    if(encounter) {
      mapTiles[y][x][layer] = new EncounterTile(
        new Sprite.int(spriteId, x, y),
        layered
      );
    } else {
      mapTiles[y][x][layer] = new Tile(
        solid,
        new Sprite.int(spriteId, x, y),
        layered
      );
    }

    MapEditor.updateMap(newPoint: new Point(x, y));
    Editor.debounceExport();
  }
  
  static void floodFill(List<List<List<Tile>>> mapTiles, int spriteId, int x, int y, int layer, int tileBefore, bool solid, bool layered, bool encounter) {
    if(spriteId == tileBefore) {
      return;
    } else if(mapTiles[y][x][layer] != null && mapTiles[y][x][layer].sprite.id != tileBefore) {
      return;
    } else if(mapTiles[y][x][layer] == null && tileBefore != -1) {
      return;
    }
    
    if(encounter) {
      mapTiles[y][x][layer] = new EncounterTile(
        new Sprite.int(spriteId, x, y),
        layered
      );
    } else {
      mapTiles[y][x][layer] = new Tile(
        solid,
        new Sprite.int(spriteId, x, y),
        layered
      );
    }
    
    // north
    if(y > 0) {
      floodFill(mapTiles, spriteId, x, y-1, layer, tileBefore, solid, layered, encounter);
    }
    
    // south
    if(y < mapTiles.length-1) {
      floodFill(mapTiles, spriteId, x, y+1, layer, tileBefore, solid, layered, encounter);
    }
    
    // east
    if(x < mapTiles[y].length-1) {
      floodFill(mapTiles, spriteId, x+1, y, layer, tileBefore, solid, layered, encounter);
    }
    
    // west
    if(x > 0) {
      floodFill(mapTiles, spriteId, x-1, y, layer, tileBefore, solid, layered, encounter);
    }
  }
  
  static void updateMapCanvasSize() {
    if(
        mapEditorCanvas.width != mapEditorCanvasWidth * window.devicePixelRatio ||
        mapEditorCanvas.height != mapEditorCanvasHeight * window.devicePixelRatio) {
      Main.fixImageSmoothing(mapEditorCanvas, mapEditorCanvasWidth, mapEditorCanvasHeight);
    }
    
    /*
    int xSize = Main.world.maps[ Main.world.curMap ].tiles[0].length;
    int ySize = Main.world.maps[ Main.world.curMap ].tiles.length;
    
    querySelector("#cur_map_size").text = "(${ xSize } x ${ ySize })";
    */
  }
  
  static void updateMap({Point oldPoint, Point newPoint, Point size, bool shouldExport: false}) {
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
    
    renderList = [];
    for(int i=0; i<World.layers.length; i++) {
      renderList.add([]);
    }
    
    // build list of tiles to be rendered
    renderWorld(renderList);
    
    for(Character character in characters) {
      character.render(renderList);
    }

    // Draw pink background
    if(oldPoint == null && newPoint == null) {
      mapEditorCanvasContext.fillStyle = "#ff00ff";
      mapEditorCanvasContext.fillRect(0, 0, mapEditorCanvasWidth, mapEditorCanvasHeight);
    } else {
      mapEditorCanvasContext.fillStyle = "#ff00ff";

      if(size == null) {
        size = new Point(1, 1);
      }

      // blank out old point
      if(oldPoint != null) {
        mapEditorCanvasContext.fillRect(
          (oldPoint.x-1) * Sprite.scaledSpriteSize, (oldPoint.y-1) * Sprite.scaledSpriteSize,
          Sprite.scaledSpriteSize*(3 + size.x), Sprite.scaledSpriteSize*(3 + size.y));
      }

      if(newPoint != null) {
        // blank out new point
        mapEditorCanvasContext.fillRect(
          (newPoint.x-1) * Sprite.scaledSpriteSize, (newPoint.y-1) * Sprite.scaledSpriteSize,
          Sprite.scaledSpriteSize*(3 + size.x), Sprite.scaledSpriteSize*(3 + size.y));
      }
    }
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        if(
          (oldPoint == null && newPoint == null) ||
          (
            oldPoint != null &&
            tile.sprite.posX.round() >= oldPoint.x - 1 && tile.sprite.posX.round() <= oldPoint.x + size.x + 1 &&
            tile.sprite.posY.round() >= oldPoint.y - 1 && tile.sprite.posY.round() <= oldPoint.y + size.y + 1
          ) || (
            newPoint != null &&
            tile.sprite.posX.round() >= newPoint.x - 1 && tile.sprite.posX.round() <= newPoint.x + size.x + 1 &&
            tile.sprite.posY.round() >= newPoint.y - 1 && tile.sprite.posY.round() <= newPoint.y + size.y + 1
          )
        ) {
          renderStaticSprite(
            mapEditorCanvasContext, tile.sprite.id,
            tile.sprite.posX.round(), tile.sprite.posY.round()
          );
        }
      }
    }
    
    MapEditor.renderColoredTiles(oldPoint: oldPoint, newPoint: newPoint, size: size);

    if(selectedTool == "select" && oldPoint == null && newPoint == null) {
      outlineSelectedTiles(
        mapEditorCanvasContext,
        lastTileInfoX, lastTileInfoY,
        lastTileInfoSizeX, lastTileInfoSizeY
      );
    }
    
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
  
  static void renderColoredTiles({Point oldPoint, Point newPoint, Point size}) {
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
    
    warps[Main.world.curMap].forEach((WarpTile warpTile) {
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
    
    signs[Main.world.curMap].forEach((Sign sign) {
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

    events[Main.world.curMap].forEach((EventTile eventTile) {
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

      for(int j=y; j<y+(character.sizeY/2).floor(); j++) {
        for(int i=x; i<x+character.sizeX; i++) {
          String key = "${i},${j}";

          if(colorTrackers[key] == null) {
            colorTrackers[key] = newColorTracker(i, j);
          }
          
          Map<String, int> colorTracker = colorTrackers[key];
          colorTracker["colorCount"] += 1;
          colorTracker["solid"] = 1;
        }
      }
    });
    
    for(int y=0; y<Main.world.maps[Main.world.curMap].tiles.length; y++) {
      for(int x=0; x<Main.world.maps[Main.world.curMap].tiles.first.length; x++) {
        String key = "${x},${y}";

        if(size == null) {
          size = new Point(1, 1);
        }

        bool shouldDo = false;

        // if no points were provided, do the whole map
        if(oldPoint == null && newPoint == null) {
          shouldDo = true;
        }

        if(oldPoint != null && (
            x >= oldPoint.x - 1 && x <= oldPoint.x + size.x + 1 &&
            y >= oldPoint.y - 1 && y <= oldPoint.y + size.y + 1
          )
        ) {
          shouldDo = true;
        }

        if(newPoint != null && (
            x >= newPoint.x - 1 && x <= newPoint.x + size.x + 1 &&
            y >= newPoint.y - 1 && y <= newPoint.y + size.y + 1
          )
        ) {
          shouldDo = true;
        }

        if(!shouldDo) {
          continue;
        }

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
      mapEditorCanvasContext.fillRect(
        x + Sprite.scaledSpriteSize / 2, y + Sprite.scaledSpriteSize / 2,
        Sprite.scaledSpriteSize / 2, Sprite.scaledSpriteSize / 2);
    }
    
    // draw the strokes around the tiles
    mapEditorCanvasContext.closePath();
    mapEditorCanvasContext.setStrokeColorRgb(r, g, b, 0.9);
    mapEditorCanvasContext.lineWidth = 1;
    mapEditorCanvasContext.stroke();
  }
  
  void selectSprite(int id) {
    setState({'selectedTile': id});
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
        for(int layer = 0; layer < World.layers.length; layer++) {
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

  startMoveMode(String selector, String map, Function callback) {
    // change map if needed
    if(map != Main.world.curMap) {
      moveModeMapBefore = Main.world.curMap;
      changeMap(map);
    }

    querySelector(selector).style.color = "#00aa00";
    querySelector("body").style.cursor = "move";

    MapEditor.previousSelectedTool = MapEditor.selectedTool;

    MapEditor.selectedTool = "move";

    MapEditor.bodyMoveListener = querySelector("body").onClick.listen((MouseEvent e) {
      endMoveMode(selector);
    });

    MapEditor.moveCallback = callback;
  }

  endMoveMode(String selector) {
    bodyMoveListener.cancel();

    if(moveModeMapBefore != null && moveModeMapBefore != Main.world.curMap) {
      changeMap(moveModeMapBefore);
    }

    // TODO: check if null
    querySelector(selector).style.color = null;
    querySelector("body").style.cursor = null;

    MapEditor.selectedTool = MapEditor.previousSelectedTool;
  }

  @override
  render() {
    JsObject selectedTab;
    if(state['selectedTab'] == "maps") {
      selectedTab = mapEditorMaps({'update': props['update'], 'debounceUpdate': props['debounceUpdate'], 'changeMap': changeMap});
    } else if(state['selectedTab'] == "tiles") {
      selectedTab = mapEditorTiles({'selectedTile': state['selectedTile']});
    } else if(state['selectedTab'] == "map_characters") {
      selectedTab = mapEditorCharacters({'update': props['update'], 'goToEditObject': props['goToEditObject']});
    } else if(state['selectedTab'] == "warps") {
      selectedTab = mapEditorWarps({'update': props['update'], 'startMoveMode': startMoveMode});
    } else if(state['selectedTab'] == "signs") {
      selectedTab = mapEditorSigns({'update': props['update'], 'startMoveMode': startMoveMode});
    } else if(state['selectedTab'] == "battlers") {
      selectedTab = mapEditorBattlers({'update': props['update']});
    } else if(state['selectedTab'] == "events") {
      selectedTab = mapEditorEvents({'update': props['update'], 'goToEditObject': props['goToEditObject'], 'startMoveMode': startMoveMode});
    }

    return
      tr({'id': 'map_editor_tab'},
        td({'id': 'left_half'},
          div({'style': {'position': 'relative', 'width': 0, 'height': 0}},
            mapEditorTileInfo({
              'ref': 'tileInfo',
              'update': props['update'],
              'showTileInfo': showTileInfo,
              'changeTile': changeTile
            })
          ),
          canvas({
            'id': 'editor_main_canvas',
            'width': 640,
            'height': 512,
            'onMouseDown': handleMainCanvasMouseDown,
            'onMouseMove': hoverTile,
            'onMouseLeave': (MouseEvent e) {
              tooltip.style.display = "none";

              if(selectedTool != "select") {
                MapEditor.updateMap();
              }
            }
          })
        ),
        td({'id': 'right_half'},
          table({'id': 'right_half_container'}, tbody({},
            tr({},
              td({'className': 'tab_headers'},
                div({
                  'id': 'maps_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "maps" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'maps'}); }
                  }, "Maps"),
                div({
                  'id': 'tiles_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "tiles" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'tiles'}); }
                }, "Tiles"),
                div({
                  'id': 'map_characters_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "map_characters" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'map_characters'}); }
                }, "Characters"),
                div({
                  'id': 'warps_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "warps" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'warps'}); }
                }, "Warps"),
                div({
                  'id': 'signs_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "signs" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'signs'}); }
                }, "Signs"),
                div({
                  'id': 'battlers_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "battlers" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'battlers'}); }
                }, "Battlers"),
                div({
                  'id': 'events_tab_header',
                  'className': 'tab_header ' + (state['selectedTab'] == "events" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'events'}); }
                }, "Events")
              )
            ),
            tr({},
              td({'id': 'editor_tabs_container'},
                selectedTab
              )
            ),
            tr({},
              td({'className': 'export_json_container'},
                textarea({'id': 'export_json', 'defaultValue': Editor.exportJsonString}),
                button({
                  'id': 'load_game_button',
                  'onClick': (e) {
                    Editor.exportJsonString = Editor.getTextAreaStringValue("#export_json");
                    specialTilesLoaded = false;
                    Editor.loadGame(props['update']);
                  }
                }, span({'className': 'fa fa-folder-open-o'}), " Load")
              )
            )
          ))
        )
      );
  }

  static Map exportTile(List<List<List<Tile>>> mapTiles, int x, int y, int k) {
    if(mapTiles[y][x][k] is Tile) {
      if(mapTiles[y][x][k].sprite.id == -1) {
        return null;
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
        
        return jsonObject;
      }
    } else {
      return null;
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
            jsonMap[y][x].add(exportTile(mapTiles, x, y, k));
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