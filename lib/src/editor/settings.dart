library dart_rpg.settings;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class Settings extends Component {
  static CanvasElement settingsCanvas;
  static CanvasRenderingContext2D ctx;
  static DivElement tooltip;
  
  static List<String> tabs = [];
  static Map<String, DivElement> tabDivs = {};
  static Map<String, DivElement> tabHeaderDivs = {};
  static String previousImageLocation;

  componentDidMount(Element rootNode) {
    settingsCanvas = querySelector("#editor_sprite_settings_canvas");
    ctx = settingsCanvas.getContext("2d");
    setUpSpriteCanvas();
  }

  static Timer debounceTimer;
  static Duration debounceDelay = new Duration(milliseconds: 500);

  void debounceUpdateCanvas({Function callback}) {
    if(debounceTimer != null) {
      debounceTimer.cancel();
    }

    debounceTimer = new Timer(debounceDelay, () {
      updateCanvas();
      Editor.export();
      if(callback != null) {
        callback();
      }
    });
  }

  void update() {
    setState({});
    debounceUpdateCanvas();
  }

  render() {
    return
      tr({'id': 'settings_tab'}, [
        td({'id': 'settings_container_left'},
          div({'id': 'settings_main_tab', 'className': 'tab'},
            table({}, tbody({},
              tr({},
                td({}, "Sprite sheet location: "),
                td({},
                  textarea({
                    'id': 'sprite_sheet_location',
                    'value': Main.spritesImageLocation,
                    'onChange': onInputChange
                  })
                )
              ),
              tr({},
                td({}, "Pixels per sprite: "),
                td({},
                  input({
                    'id': 'sprite_sheet_pixels_per_sprite',
                    'type': 'text',
                    'className': 'number',
                    'value': Sprite.pixelsPerSprite,
                    'onChange': onInputChange
                  })
                )
              ),
              tr({},
                td({}, "Sprite scale: "),
                td({},
                  input({
                    'id': 'sprite_sheet_scale',
                    'type': 'text',
                    'className': 'number',
                    'value': Sprite.spriteScale,
                    'onChange': onInputChange
                  })
                )
              ),
              tr({},
                td({}, "Frames per second: "),
                td({},
                  input({
                    'id': 'settings_frames_per_second',
                    'type': 'text',
                    'className': 'number',
                    'value': Main.framesPerSecond,
                    'onChange': onInputChange
                  })
                )
              )
            ))
          )
        ),
        td({},
          div({'id': 'settings_container_right'},
            canvas({'id': 'editor_sprite_settings_canvas', 'width': 256, 'height': 256})
          )
        )
      ]);
  }
  
  static void setUpSpriteCanvas() {
    Main.fixImageSmoothing(
      settingsCanvas,
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
    
    settingsCanvas.onMouseMove.listen(outlineTile);
    
    settingsCanvas.onMouseLeave.listen((MouseEvent e) {
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

  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    Main.spritesImageLocation = Editor.getTextAreaStringValue("#sprite_sheet_location");
    
    Sprite.pixelsPerSprite = Editor.getTextInputIntValue("#sprite_sheet_pixels_per_sprite", 16);
    Sprite.spriteScale = Editor.getTextInputIntValue("#sprite_sheet_scale", 2);
    
    Sprite.scaledSpriteSize = Sprite.pixelsPerSprite * Sprite.spriteScale;
    
    Main.framesPerSecond = Editor.getTextInputIntValue("#settings_frames_per_second", 40);
    
    update();
  }
  
  void updateCanvas() {
    if(previousImageLocation == Main.spritesImageLocation) {
      return;
    }

    previousImageLocation = Main.spritesImageLocation;

    Main.spritesImage = new ImageElement(src:Main.spritesImageLocation);
    Main.spritesImage.onLoad.listen((e) {
      Sprite.spriteSheetWidth = (Main.spritesImage.width / Sprite.pixelsPerSprite).round();
      Sprite.spriteSheetHeight = (Main.spritesImage.height / Sprite.pixelsPerSprite).round();
      
      Main.fixImageSmoothing(
        settingsCanvas,
        Sprite.spriteSheetWidth * Sprite.scaledSpriteSize,
        Sprite.spriteSheetHeight * Sprite.scaledSpriteSize
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