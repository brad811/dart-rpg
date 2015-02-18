library Editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';
import 'package:dart_rpg/src/world.dart';

class Editor {
  static ImageElement spritesImage;
  static CanvasElement c, sc, ssc;
  static CanvasRenderingContext2D ctx, sctx, ssctx;
  static DivElement
    mapTab, charactersTab, warpsTab, signsTab,
    mapTabHeader, charactersTabHeader, warpsTabHeader, signsTabHeader;
  
  static int
    canvasWidth = 100,
    canvasHeight = 100;
  
  static List<List<Tile>> renderList;
  static int selectedTile;
  
  static List<WarpTile> warps = [];
  
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
    
    Main.world = new World();
    Main.world.map = [];
    Main.world.characters = [];
    
    Main.world.loadMap(() {
      setUpTabs();
      setUpSpritePicker();
      setUpMapSizeButtons();
      setUpWarpsTab();
      updateMap();
    });
  }
  
  static void setUpWarpsTab() {
    querySelector("#add_warp_button").onClick.listen((MouseEvent e) {
      warps.add( new WarpTile(false, new Sprite.int(0, 0, 0), 0, 0) );
      updateWarpsTable();
    });
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
        "  <td><input type='text' value='${ warps[i].sprite.posX.round() }' /></td>"+
        "  <td><input type='text' value='${ warps[i].sprite.posY.round() }' /></td>"+
        "  <td><input type='text' value='${ warps[i].destX }' /></td>"+
        "  <td><input type='text' value='${ warps[i].destY }' /></td>"+
        "</tr>";
    }
    warpsHtml += "</table>";
    querySelector("#warps_container").innerHtml = warpsHtml;
    updateMap();
  }
  
  static void setUpTabs() {
    mapTab = querySelector('#map_tab');
    charactersTab = querySelector('#characters_tab');
    warpsTab = querySelector('#warps_tab');
    signsTab = querySelector('#signs_tab');
    
    mapTab.style.display = "none";
    charactersTab.style.display = "none";
    warpsTab.style.display = "none";
    signsTab.style.display = "none";
    
    mapTabHeader = querySelector('#map_tab_header');
    charactersTabHeader = querySelector('#characters_tab_header');
    warpsTabHeader = querySelector('#warps_tab_header');
    signsTabHeader = querySelector('#signs_tab_header');
    
    mapTabHeader.onClick.listen((MouseEvent e) {
      mapTab.style.display = "block";
      mapTabHeader.style.backgroundColor = "#eeeeee";
      
      charactersTab.style.display = "none";
      charactersTabHeader.style.backgroundColor = "";
      
      warpsTab.style.display = "none";
      warpsTabHeader.style.backgroundColor = "";
      
      signsTab.style.display = "none";
      signsTabHeader.style.backgroundColor = "";
    });
    
    charactersTabHeader.onClick.listen((MouseEvent e) {
      mapTab.style.display = "none";
      mapTabHeader.style.backgroundColor = "";
      
      charactersTab.style.display = "block";
      charactersTabHeader.style.backgroundColor = "#eeeeee";
      
      warpsTab.style.display = "none";
      warpsTabHeader.style.backgroundColor = "";
      
      signsTab.style.display = "none";
      signsTabHeader.style.backgroundColor = "";
    });
    
    warpsTabHeader.onClick.listen((MouseEvent e) {
      mapTab.style.display = "none";
      mapTabHeader.style.backgroundColor = "";
      
      charactersTab.style.display = "none";
      charactersTabHeader.style.backgroundColor = "";
      
      warpsTab.style.display = "block";
      warpsTabHeader.style.backgroundColor = "#eeeeee";
      
      signsTab.style.display = "none";
      signsTabHeader.style.backgroundColor = "";
    });
    
    signsTabHeader.onClick.listen((MouseEvent e) {
      mapTab.style.display = "none";
      mapTabHeader.style.backgroundColor = "";
      
      charactersTab.style.display = "none";
      charactersTabHeader.style.backgroundColor = "";
      
      warpsTab.style.display = "none";
      warpsTabHeader.style.backgroundColor = "";
      
      signsTab.style.display = "block";
      signsTabHeader.style.backgroundColor = "#eeeeee";
    });
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
        int x = (e.offset.x/Sprite.scaledSpriteSize).floor();
        int y = (e.offset.y/Sprite.scaledSpriteSize).floor();
        
        if(y >= Main.world.map.length || x >= Main.world.map[0].length)
          return;
        
        int layer = int.parse((querySelector("[name='layer']:checked") as RadioButtonInputElement).value);
        bool solid = (querySelector("#solid") as CheckboxInputElement).checked;
        
        if(selectedTile == 98) {
          Main.world.map[y][x][layer] = null;
        } else {
          Main.world.map[y][x][layer] = new Tile(
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
    // size x down button
    querySelector('#size_x_down_button').onClick.listen((MouseEvent e) {
      if(Main.world.map[0].length == 1)
        return;
      
      for(int y=0; y<Main.world.map.length; y++) {
        Main.world.map[y].removeLast();
        
        for(int x=0; x<Main.world.map[y].length; x++) {
          for(int k=0; k<Main.world.map[y][x].length; k++) {
            if(Main.world.map[y][x][k] is Tile) {
              Main.world.map[y][x][k].sprite.posX = x * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
     
    // size x up button
    querySelector('#size_x_up_button').onClick.listen((MouseEvent e) {
      if(Main.world.map.length == 0)
        Main.world.map.add([]);
      
      int width = Main.world.map[0].length;
      
      for(int y=0; y<Main.world.map.length; y++) {
        List<Tile> array = [];
        for(int k=0; k<World.layers.length; k++) {
          array.add(null);
        }
        Main.world.map[y].add(array);
      }
      
      updateMap();
    });
    
    // size y down button
    querySelector('#size_y_down_button').onClick.listen((MouseEvent e) {
      if(Main.world.map.length == 1)
        return;
      
      Main.world.map.removeLast();
      
      updateMap();
    });
     
    // size y up button
    querySelector('#size_y_up_button').onClick.listen((MouseEvent e) {
      List<List<Tile>> rowArray = [];
      
      int height = Main.world.map.length;
      
      for(int x=0; x<Main.world.map[0].length; x++) {
        List<Tile> array = [];
        for(int k=0; k<World.layers.length; k++) {
          array.add(null);
        }
        rowArray.add(array);
      }
      
      Main.world.map.add(rowArray);
      
      updateMap();
    });
    
    // ////////////////////////////////////////
    // Pre buttons
    // ////////////////////////////////////////
    
    // size x down button pre
    querySelector('#size_x_down_button_pre').onClick.listen((MouseEvent e) {
      if(Main.world.map[0].length == 1)
        return;
      
      for(int i=0; i<Main.world.map.length; i++) {
        Main.world.map[i] = Main.world.map[i].sublist(1);
        
        for(int j=0; j<Main.world.map[i].length; j++) {
          for(int k=0; k<Main.world.map[i][j].length; k++) {
            if(Main.world.map[i][j][k] is Tile) {
              Main.world.map[i][j][k].sprite.posX = j * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
     
    // size x up button pre
    querySelector('#size_x_up_button_pre').onClick.listen((MouseEvent e) {
      if(Main.world.map.length == 0)
        Main.world.map.add([]);
      
      for(int y=0; y<Main.world.map.length; y++) {
        List<Tile> array = [];
        for(int k=0; k<World.layers.length; k++) {
          array.add(null);
        }
        var temp = Main.world.map[y];
        temp.insert(0, array);
        Main.world.map[y] = temp;
      }
      
      for(int y=0; y<Main.world.map.length; y++) {
        for(int x=0; x<Main.world.map[y].length; x++) {
          for(int k=0; k<Main.world.map[y][x].length; k++) {
            if(Main.world.map[y][x][k] is Tile) {
              Main.world.map[y][x][k].sprite.posX = x * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
    
    // size y down button pre
    querySelector('#size_y_down_button_pre').onClick.listen((MouseEvent e) {
      if(Main.world.map.length == 1)
        return;
      
      Main.world.map.removeAt(0);
      
      for(int y=0; y<Main.world.map.length; y++) {
        for(int x=0; x<Main.world.map[0].length; x++) {
          for(int k=0; k<Main.world.map[0][0].length; k++) {
            if(Main.world.map[y][x][k] is Tile) {
              Main.world.map[y][x][k].sprite.posY = y * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
     
    // size y up button pre
    querySelector('#size_y_up_button_pre').onClick.listen((MouseEvent e) {
      List<List<Tile>> rowArray = [];
      
      for(int i=0; i<Main.world.map[0].length; i++) {
        List<Tile> array = [];
        for(int j=0; j<World.layers.length; j++) {
          array.add(null);
        }
        rowArray.add(array);
      }
      
      Main.world.map.insert(0, rowArray);
      
      for(int y=0; y<Main.world.map.length; y++) {
        for(int x=0; x<Main.world.map[0].length; x++) {
          for(int k=0; k<Main.world.map[0][0].length; k++) {
            if(Main.world.map[y][x][k] is Tile) {
              Main.world.map[y][x][k].sprite.posY = y * 1.0;
            }
          }
        }
      }
      
      updateMap();
    });
  }
  
  static void updateMap() {
    if(Main.world.map.length == 0 || Main.world.map[0].length == 0)
      return;
    
    canvasHeight = Main.world.map.length * Sprite.scaledSpriteSize;
    canvasWidth = Main.world.map[0].length * Sprite.scaledSpriteSize;
    
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
    
    for(Character character in Main.world.characters) {
      character.render(renderList);
    }
    
    for(List<Tile> layer in renderList) {
      for(Tile tile in layer) {
        renderStaticSprite(
          ctx, tile.sprite.id,
          tile.sprite.posX.round(), tile.sprite.posY.round()
        );
        
        // add pending strokes to be drawn around this tile if solid
        if(tile.solid) {
          int
            x = (tile.sprite.posX * Sprite.scaledSpriteSize).round(),
            y = (tile.sprite.posY * Sprite.scaledSpriteSize).round();
          
          ctx.moveTo(x, y);
          ctx.lineTo(x + Sprite.scaledSpriteSize, y);
          ctx.lineTo(x + Sprite.scaledSpriteSize, y + Sprite.scaledSpriteSize);
          ctx.lineTo(x, y + Sprite.scaledSpriteSize);
          ctx.lineTo(x, y);
        }
      }
    }
    
    // draw the strokes around the solid tiles
    ctx.setStrokeColorRgb(255, 0, 0, 0.9);
    ctx.stroke();
    
    //   to handle properties like "solid"
    List<List<List<Map>>> jsonMap = [];
    for(int y=0; y<Main.world.map.length; y++) {
      jsonMap.add([]);
      for(int x=0; x<Main.world.map[0].length; x++) {
        jsonMap[y].add([]);
        for(int k=0; k<Main.world.map[0][0].length; k++) {
          if(Main.world.map[y][x][k] is Tile) {
            if(Main.world.map[y][x][k].sprite.id == -1) {
              jsonMap[y][x].add(null);
            } else {
              jsonMap[y][x].add({
                "id": Main.world.map[y][x][k].sprite.id,
                "solid": Main.world.map[y][x][k].solid
              });
            }
          } else {
            jsonMap[y][x].add(null);
          }
        }
      }
    }
    
    TextAreaElement textarea = querySelector("textarea");
    textarea.value = JSON.encode(jsonMap);
    textarea.select();
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
    for(var y=0; y<Main.world.map.length; y++) {
      for(var x=0; x<Main.world.map[y].length; x++) {
        for(int layer in World.layers) {
          if(Main.world.map[y][x][layer] is Tile) {
            renderList[layer].add(
              Main.world.map[y][x][layer]
            );
          }
        }
      }
    }
  }
}