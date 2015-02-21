library Editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

class Editor {
  static ImageElement spritesImage;
  static CanvasElement c, sc, ssc;
  static CanvasRenderingContext2D ctx, sctx, ssctx;
  static List<String> tabs = ["maps", "tiles", "characters", "warps", "signs"];
  static Map<String, DivElement> tabDivs = {};
  static Map<String, DivElement> tabHeaderDivs = {};
  
  static int
    canvasWidth = 100,
    canvasHeight = 100;
  
  static List<List<Tile>> renderList;
  static int selectedTile;
  
  static List<WarpTile> warps = [];
  static List<Sign> signs = [];
  
  static void init() {
    c = querySelector('#editor_main_canvas');
    ctx = c.getContext("2d");
    ctx.imageSmoothingEnabled = false;
    
    sc = querySelector('#editor_sprite_canvas');
    sctx = sc.getContext("2d");
    sctx.imageSmoothingEnabled = false;
    
    ssc = querySelector('#editor_selected_sprite_canvas');
    ssctx = ssc.getContext("2d");
    ssctx.imageSmoothingEnabled = false;
    
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
        setUpMapSizeButtons();
        updateMapsTable();
        setUpWarpsTab();
        setUpSignsTab();
        updateMap();
        
        Function resizeFunction = (Event e) {
          querySelector('#left_half').style.width = "${window.innerWidth - 580}px";
          querySelector('#left_half').style.height = "${window.innerHeight - 30}px";
        };
        
        window.onResize.listen(resizeFunction);
        resizeFunction(null);
      });
    });
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
  
  static void updateMapsTable() {
    String mapsHtml;
    mapsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>Name</td><td>X Size</td><td>Y Size</td><td>Chars</td>"+
      "  </tr>";
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      mapsHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='maps_name_${i}' type='text' value='${ Main.world.maps[key].name }' /></td>"+
        "  <td>${ Main.world.maps[key].tiles[0].length }</td>"+
        "  <td>${ Main.world.maps[key].tiles.length }</td>"+
        "  <td>${ Main.world.maps[key].characters.length }</td>"+
        "</tr>";
    }
    mapsHtml += "</table>";
    querySelector("#maps_container").innerHtml = mapsHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<Main.world.maps.length; i++) {
        String key = Main.world.maps.keys.elementAt(i);
        try {
          Main.world.maps[key].name = (querySelector('#maps_name_${i}') as TextInputElement).value;
        } catch(e) {
          // could not update this map
        }
      }
      updateMap();
    };
    
    for(int i=0; i<Main.world.maps.length; i++) {
      querySelector('#maps_name_${i}').onInput.listen(inputChangeFunction);
    }
    
    updateMap();
  }
  
  static void setUpSignsTab() {
    querySelector("#add_sign_button").onClick.listen((MouseEvent e) {
      signs.add( new Sign(false, new Sprite.int(0, 0, 0), 234, "Text") );
      updateSignsTable();
    });
    
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    
    for(var y=0; y<mapTiles.length; y++) {
      for(var x=0; x<mapTiles[y].length; x++) {
        for(int layer in World.layers) {
          if(mapTiles[y][x][layer] is Sign) {
            signs.add(mapTiles[y][x][layer]);
          }
        }
      }
    }
    
    updateSignsTable();
  }
  
  static void updateSignsTable() {
    String signsHtml;
    signsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>X</td><td>Y</td><td>Pic</td><td>Text</td>"+
      "  </tr>";
    for(int i=0; i<signs.length; i++) {
      signsHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='signs_posx_${i}' type='text' value='${ signs[i].sprite.posX.round() }' /></td>"+
        "  <td><input id='signs_posy_${i}' type='text' value='${ signs[i].sprite.posY.round() }' /></td>"+
        "  <td><input id='signs_pic_${i}' type='text' value='${ signs[i].textEvent.pictureSpriteId }' /></td>"+
        "  <td><textarea id='signs_text_${i}' />${ signs[i].textEvent.text }</textarea></td>"+
        "</tr>";
    }
    signsHtml += "</table>";
    querySelector("#signs_container").innerHtml = signsHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<signs.length; i++) {
        try {
          signs[i] = new Sign(
            false,
            new Sprite(
              0,
              double.parse((querySelector('#signs_posx_${i}') as InputElement).value),
              double.parse((querySelector('#signs_posy_${i}') as InputElement).value)
            ),
            int.parse((querySelector('#signs_pic_${i}') as InputElement).value),
            (querySelector('#signs_text_${i}') as TextAreaElement).value
          );
        } catch(e) {
          // could not update this sign
        }
      }
      updateMap();
    };
    
    for(int i=0; i<signs.length; i++) {
      querySelector('#signs_posx_${i}').onInput.listen(inputChangeFunction);
      querySelector('#signs_posy_${i}').onInput.listen(inputChangeFunction);
      querySelector('#signs_pic_${i}').onInput.listen(inputChangeFunction);
      querySelector('#signs_text_${i}').onInput.listen(inputChangeFunction);
    }
    
    updateMap();
  }
  
  static void setUpWarpsTab() {
    querySelector("#add_warp_button").onClick.listen((MouseEvent e) {
      warps.add( new WarpTile(false, new Sprite.int(0, 0, 0), 0, 0) );
      updateWarpsTable();
    });
    
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    
    for(var y=0; y<mapTiles.length; y++) {
      for(var x=0; x<mapTiles[y].length; x++) {
        for(int layer in World.layers) {
          if(mapTiles[y][x][layer] is WarpTile) {
            warps.add(mapTiles[y][x][layer]);
          }
        }
      }
    }
    
    updateWarpsTable();
  }
  
  static void updateWarpsTable() {
    String warpsHtml;
    warpsHtml = "<table>"+
      "  <tr>"+
      "    <td>Num</td><td>X</td><td>Y</td><td>Dest X</td><td>Dest Y</td>"+
      "  </tr>";
    for(int i=0; i<warps.length; i++) {
      warpsHtml +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='warps_posx_${i}' type='text' value='${ warps[i].sprite.posX.round() }' /></td>"+
        "  <td><input id='warps_posy_${i}' type='text' value='${ warps[i].sprite.posY.round() }' /></td>"+
        "  <td><input id='warps_destx_${i}' type='text' value='${ warps[i].destX }' /></td>"+
        "  <td><input id='warps_desty_${i}' type='text' value='${ warps[i].destY }' /></td>"+
        "</tr>";
    }
    warpsHtml += "</table>";
    querySelector("#warps_container").innerHtml = warpsHtml;
    
    Function inputChangeFunction = (Event e) {
      for(int i=0; i<warps.length; i++) {
        try {
          warps[i].sprite.posX = double.parse((querySelector('#warps_posx_${i}') as InputElement).value);
          warps[i].sprite.posY = double.parse((querySelector('#warps_posy_${i}') as InputElement).value);
          warps[i].destX = int.parse((querySelector('#warps_destx_${i}') as InputElement).value);
          warps[i].destY = int.parse((querySelector('#warps_desty_${i}') as InputElement).value);
        } catch(e) {
          // could not update this warp
        }
      }
      updateMap();
    };
    
    for(int i=0; i<warps.length; i++) {
      querySelector('#warps_posx_${i}').onInput.listen(inputChangeFunction);
      querySelector('#warps_posy_${i}').onInput.listen(inputChangeFunction);
      querySelector('#warps_destx_${i}').onInput.listen(inputChangeFunction);
      querySelector('#warps_desty_${i}').onInput.listen(inputChangeFunction);
    }
    
    updateMap();
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
      
      List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
      
      Function tileChange = (MouseEvent e) {
        int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
        int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
        
        if(y >= mapTiles.length || x >= mapTiles[0].length)
          return;
        
        int layer = int.parse((querySelector("[name='layer']:checked") as RadioButtonInputElement).value);
        bool solid = (querySelector("#solid") as CheckboxInputElement).checked;
        
        if(selectedTile == 98) {
          mapTiles[y][x][layer] = null;
        } else {
          mapTiles[y][x][layer] = new Tile(
            solid,
            new Sprite.int(selectedTile, x, y)
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
  
  static void setUpMapSizeButtons() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    
    // size x down button
    querySelector('#size_x_down_button').onClick.listen((MouseEvent e) {
      if(mapTiles[0].length == 1)
        return;
      
      for(int y=0; y<mapTiles.length; y++) {
        mapTiles[y].removeLast();
        
        for(int x=0; x<mapTiles[y].length; x++) {
          for(int k=0; k<mapTiles[y][x].length; k++) {
            if(mapTiles[y][x][k] is Tile) {
              mapTiles[y][x][k].sprite.posX = x * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
     
    // size x up button
    querySelector('#size_x_up_button').onClick.listen((MouseEvent e) {
      if(mapTiles.length == 0)
        mapTiles.add([]);
      
      int width = mapTiles[0].length;
      
      for(int y=0; y<mapTiles.length; y++) {
        List<Tile> array = [];
        for(int k=0; k<World.layers.length; k++) {
          array.add(null);
        }
        mapTiles[y].add(array);
      }
      
      updateMap();
    });
    
    // size y down button
    querySelector('#size_y_down_button').onClick.listen((MouseEvent e) {
      if(mapTiles.length == 1)
        return;
      
      mapTiles.removeLast();
      
      updateMap();
    });
     
    // size y up button
    querySelector('#size_y_up_button').onClick.listen((MouseEvent e) {
      List<List<Tile>> rowArray = [];
      
      int height = mapTiles.length;
      
      for(int x=0; x<mapTiles[0].length; x++) {
        List<Tile> array = [];
        for(int k=0; k<World.layers.length; k++) {
          array.add(null);
        }
        rowArray.add(array);
      }
      
      mapTiles.add(rowArray);
      
      updateMap();
    });
    
    // ////////////////////////////////////////
    // Pre buttons
    // ////////////////////////////////////////
    
    // size x down button pre
    querySelector('#size_x_down_button_pre').onClick.listen((MouseEvent e) {
      if(mapTiles[0].length == 1)
        return;
      
      for(int i=0; i<mapTiles.length; i++) {
        mapTiles[i] = mapTiles[i].sublist(1);
        
        for(int j=0; j<mapTiles[i].length; j++) {
          for(int k=0; k<mapTiles[i][j].length; k++) {
            if(mapTiles[i][j][k] is Tile) {
              mapTiles[i][j][k].sprite.posX = j * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
     
    // size x up button pre
    querySelector('#size_x_up_button_pre').onClick.listen((MouseEvent e) {
      if(mapTiles.length == 0)
        mapTiles.add([]);
      
      for(int y=0; y<mapTiles.length; y++) {
        List<Tile> array = [];
        for(int k=0; k<World.layers.length; k++) {
          array.add(null);
        }
        var temp = mapTiles[y];
        temp.insert(0, array);
        mapTiles[y] = temp;
      }
      
      for(int y=0; y<mapTiles.length; y++) {
        for(int x=0; x<mapTiles[y].length; x++) {
          for(int k=0; k<mapTiles[y][x].length; k++) {
            if(mapTiles[y][x][k] is Tile) {
              mapTiles[y][x][k].sprite.posX = x * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
    
    // size y down button pre
    querySelector('#size_y_down_button_pre').onClick.listen((MouseEvent e) {
      if(mapTiles.length == 1)
        return;
      
      mapTiles.removeAt(0);
      
      for(int y=0; y<mapTiles.length; y++) {
        for(int x=0; x<mapTiles[0].length; x++) {
          for(int k=0; k<mapTiles[0][0].length; k++) {
            if(mapTiles[y][x][k] is Tile) {
              mapTiles[y][x][k].sprite.posY = y * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
     
    // size y up button pre
    querySelector('#size_y_up_button_pre').onClick.listen((MouseEvent e) {
      List<List<Tile>> rowArray = [];
      
      for(int i=0; i<mapTiles[0].length; i++) {
        List<Tile> array = [];
        for(int j=0; j<World.layers.length; j++) {
          array.add(null);
        }
        rowArray.add(array);
      }
      
      mapTiles.insert(0, rowArray);
      
      for(int y=0; y<mapTiles.length; y++) {
        for(int x=0; x<mapTiles[0].length; x++) {
          for(int k=0; k<mapTiles[0][0].length; k++) {
            if(mapTiles[y][x][k] is Tile) {
              mapTiles[y][x][k].sprite.posY = y * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
  }
  
  static void updateMap() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<Character> characters = Main.world.maps[Main.world.curMap].characters;
    
    if(mapTiles.length == 0 || mapTiles[0].length == 0)
      return;
    
    canvasHeight = mapTiles.length * Sprite.scaledSpriteSize;
    canvasWidth = mapTiles[0].length * Sprite.scaledSpriteSize;
    
    c.width = canvasWidth;
    c.height = canvasHeight;
    
    ctx.imageSmoothingEnabled = false;
    
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
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        renderStaticSprite(
          ctx, tile.sprite.id,
          tile.sprite.posX.round(), tile.sprite.posY.round()
        );
        
        // add solid tiles to a list to have boxes drawn around them
        if(tile.solid)
          solids.add(tile);
      }
    }
    
    // draw red boxes around solid tiles
    outlineTiles(solids, 255, 0, 0);
    
    // draw green boxes around warp tiles
    outlineTiles(warps, 0, 255, 0);
    
    // draw yellow boxes around sign tiles
    outlineTiles(signs, 255, 255, 0);
    
    // build the json
    buildExportJson();
  }
  
  static void buildExportJson() {
    Map<String, Map> exportJson = {};
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      List<Character> characters = Main.world.maps[key].characters;
      
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
                jsonMap[y][x].add({
                  "id": mapTiles[y][x][k].sprite.id,
                  "solid": mapTiles[y][x][k].solid
                });
              }
            } else {
              jsonMap[y][x].add(null);
            }
          }
        }
      }
      
      for(WarpTile warp in warps) {
        int
          x = warp.sprite.posX.round(),
          y = warp.sprite.posY.round();
        
        if(jsonMap[y][x][0] != null) {
          jsonMap[y][x][0]["warp"] = {
            "posX": x,
            "posY": y,
            "destX": warp.destX,
            "destY": warp.destY
          };
        }
      }
      
      for(Sign sign in signs) {
        int
          x = sign.sprite.posX.round(),
          y = sign.sprite.posY.round();
        
        if(jsonMap[y][x][0] != null) {
          jsonMap[y][x][0]["sign"] = {
            "posX": x,
            "posY": y,
            "pic": sign.textEvent.pictureSpriteId,
            "text": sign.textEvent.text
          };
        }
      }
      
      exportJson[key] = {};
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
    
    // draw the strokes around the warp tiles
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