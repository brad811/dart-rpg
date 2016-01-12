library dart_rpg.editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/map_editor.dart';
import 'package:dart_rpg/src/editor/object_editor.dart';
import 'package:dart_rpg/src/editor/screen_editor.dart';
import 'package:dart_rpg/src/editor/settings.dart';

// TODO: equation editor? (exp reqired to level up, chance to escape battle, stat gains from leveling up, exp gained from battle)

class Editor {
  static List<String> editorTabs = ["map_editor", "object_editor", "screen_editor", "settings"];
  
  static bool highlightSpecialTiles = true;
  
  static Map<String, StreamSubscription> listeners = new Map<String, StreamSubscription>();
  static Map<String, StreamSubscription> popupSpritePickerCanvasListeners = new Map<String, StreamSubscription>();
  
  static Timer debounceTimer;
  static Duration debounceDelay = new Duration(milliseconds: 250);
  
  static void init() {
    ObjectEditor.init();
    MapEditor.init(start);
    ScreenEditor.init();
    Settings.init();
  }
  
  static void start() {
    Main.world = new World(() {
      Main.world.loadGame(() {
        Editor.setUp();
      });
    });
  }
  
  static void setUp() {
    MapEditor.setUp();
    ObjectEditor.setUp();
    ScreenEditor.setUp();
    Settings.setUp();
    
    Editor.setUpTabs(editorTabs);
    
    Editor.update();
    
    Function resizeFunction = (Event e) {
      querySelector('#left_half').style.width = "${window.innerWidth - 562}px";
      querySelector('#left_half').style.height = "${window.innerHeight - 60}px";
      querySelector('#container').style.height = "${window.innerHeight - 10}px";
    };
    
    window.onResize.listen(resizeFunction);
    resizeFunction(null);
    
    ButtonElement loadGameButton = querySelector("#load_game_button");
    loadGameButton.onClick.listen(loadGame);
  }
  
  static void loadGame(MouseEvent e) {
    Main.world.parseGame(Editor.getTextAreaStringValue("#export_json"), () {
      Editor.setUp();
    });
  }
  
  static void debounceUpdate([Function callback]) {
    if(debounceTimer != null) {
      debounceTimer.cancel();
    }
    
    debounceTimer = new Timer(debounceDelay, () {
      Editor.update();
      if(callback != null) {
        callback();
      }
    });
  }
  
  static void update() {
    MapEditor.update();
    ObjectEditor.update();
    ScreenEditor.update();
    Settings.update();
    Editor.export();
  }
  
  static void export() {
    Map<String, Map<String, Map<String, Object>>> exportJson = {};
    MapEditor.export(exportJson);
    ObjectEditor.export(exportJson);
    ScreenEditor.export(exportJson);
    Settings.export(exportJson);
    
    String exportJsonString = JSON.encode(exportJson);
    
    TextAreaElement textarea = querySelector("#export_json");
    textarea.value = exportJsonString;
    
    TextAreaElement textarea2 = querySelector("#export_json_object_editor");
    textarea2.value = exportJsonString;
  }
  
  static void setUpTabs(List<String> tabs, [Function callback]) {
    Map<String, DivElement>
      tabDivs = {},
      tabHeaderDivs = {};
    
    for(String tab in tabs) {
      tabDivs[tab] = querySelector("#${tab}_tab");
      tabDivs[tab].style.display = "none";
      
      tabHeaderDivs[tab] = querySelector("#${tab}_tab_header");
      tabHeaderDivs[tab].style.backgroundColor = "";
      
      tabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in tabs) {
          tabDivs[tabb].style.display = "none";
          tabHeaderDivs[tabb].style.backgroundColor = "";
        }
        
        tabDivs[tab].style.display = "";
        tabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
        
        if(callback != null) {
          callback();
        }
      });
    }
    
    tabDivs[tabDivs.keys.first].style.display = "";
    tabHeaderDivs[tabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
  }
  
  static void setMapDeleteButtonListeners(Map<Object, Object> target, String targetName) {
    for(int i=0; i<target.keys.length; i++) {
      if(listeners["#delete_${targetName}_${i}"] != null)
        listeners["#delete_${targetName}_${i}"].cancel();
      
      listeners["#delete_${targetName}_${i}"] =
          querySelector("#delete_${targetName}_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
        if(confirm) {
          target.remove(target.keys.elementAt(i));
          Editor.update();
        }
      });
    }
  }
  
  static void setListDeleteButtonListeners(List<Object> target, String targetName) {
    for(int i=0; i<target.length; i++) {
      if(listeners["#delete_${targetName}_${i}"] != null)
        listeners["#delete_${targetName}_${i}"].cancel();

      listeners["#delete_${targetName}_${i}"] =
          querySelector("#delete_${targetName}_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
        if(confirm) {
          target.removeAt(i);
          Editor.update();
        }
      });
    }
  }
  
  static String generateSpritePickerHtml(String prefix, int value, { bool readOnly: false }) {
    String readOnlyString = "";
    if(readOnly) {
      readOnlyString = "readonly";
    }
    
    String html =
      "<canvas id='${prefix}_canvas'></canvas><br />"+
      "<input id='${prefix}' type='text' class='number' value='${ value }'  ${readOnlyString} />";
      
    if(readOnlyString == "") {
      html += "<button id='${prefix}_edit_button'>Edit</button>";
    }
    
    return html;
  }
  
  static void initSpritePicker(String prefix, int value, int sizeX, int sizeY, Function onInputChange, { bool readOnly: false }) {
    Main.fixImageSmoothing(
      querySelector("#${prefix}_canvas"),
      Sprite.scaledSpriteSize * sizeX,
      Sprite.scaledSpriteSize * sizeY
    );
    
    Editor.renderSprite("#${prefix}_canvas", value, sizeX, sizeY);
    
    if(!readOnly) {
      querySelector("#${prefix}_edit_button").onClick.listen((MouseEvent e) {
        Editor.showPopupSpriteSelector(sizeX, sizeY, (int spriteId) {
          (querySelector("#${prefix}") as TextInputElement).value = spriteId.toString();
          onInputChange(null);
        });
      });
    }
  }
  
  static void renderSprite(String id, int spriteId, int sizeX, int sizeY) {
    CanvasElement canvas = querySelector(id);
    CanvasRenderingContext2D ctx = canvas.context2D;
    
    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, Sprite.scaledSpriteSize * sizeX, Sprite.scaledSpriteSize * sizeY);
    
    for(int i=0; i<sizeX; i++) {
      for(int j=0; j<sizeY; j++) {
        MapEditor.renderStaticSprite(ctx, spriteId + (i) + (j*Sprite.spriteSheetWidth), i, j);
      }
    }
  }
  
  static void showPopupSpriteSelector(int sizeX, int sizeY, Function callback) {
    DivElement shade = querySelector("#popup_shade");
    DivElement container = querySelector("#popup_sprite_selector_container");
    CanvasElement canvas = querySelector("#popup_sprite_selector_canvas");
    
    int height = math.min(window.innerHeight - 40, Main.spritesImage.height * Sprite.spriteScale + 20);
    int width = math.min(window.innerWidth - 40, Main.spritesImage.width * Sprite.spriteScale + 20);
    
    container.style.height = "${ height }px";
    container.style.width = "${ width }px";
    container.style.marginLeft = "-${ (width/2).round() }px";
    
    Main.fixImageSmoothing(canvas, Main.spritesImage.width * Sprite.spriteScale, Main.spritesImage.height * Sprite.spriteScale);
    
    // Draw pink background
    canvas.context2D.fillStyle = "#ff00ff";
    canvas.context2D.fillRect(0, 0, Main.spritesImage.width * Sprite.spriteScale, Main.spritesImage.height * Sprite.spriteScale);
    
    // render sprite picker
    int
      maxCol = Sprite.spriteSheetWidth,
      col = 0,
      row = 0;
    for(int y=0; y<Sprite.spriteSheetHeight; y++) {
      for(int x=0; x<Sprite.spriteSheetWidth; x++) {
        MapEditor.renderStaticSprite(canvas.context2D, y*Sprite.spriteSheetWidth + x, col, row);
        col++;
        if(col >= maxCol) {
          row++;
          col = 0;
        }
      }
    }
    
    if(popupSpritePickerCanvasListeners["onClick"] != null) {
      popupSpritePickerCanvasListeners["onClick"].cancel();
    }
    
    popupSpritePickerCanvasListeners["onClick"] = canvas.onClick.listen((MouseEvent e) {
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor() - (sizeX/2).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor() - (sizeY/2).floor();
      
      if(y >= Main.world.maps[Main.world.curMap].tiles.length || x >= Main.world.maps[Main.world.curMap].tiles[0].length) {
        callback(-1);
      }
      
      container.style.display = "none";
      shade.style.display = "none";
      
      callback(y*Sprite.spriteSheetWidth + x);
    });
    
    if(popupSpritePickerCanvasListeners["onMouseMove"] != null) {
      popupSpritePickerCanvasListeners["onMouseMove"].cancel();
    }
    
    popupSpritePickerCanvasListeners["onMouseMove"] = canvas.onMouseMove.listen((MouseEvent e) {
      // Draw pink background
      canvas.context2D.fillStyle = "#ff00ff";
      canvas.context2D.fillRect(0, 0, Main.spritesImage.width * Sprite.spriteScale, Main.spritesImage.height * Sprite.spriteScale);
      
      // render sprite picker
      int
        maxCol = Sprite.spriteSheetWidth,
        col = 0,
        row = 0;
      for(int y=0; y<Sprite.spriteSheetHeight; y++) {
        for(int x=0; x<Sprite.spriteSheetWidth; x++) {
          MapEditor.renderStaticSprite(canvas.context2D, y*Sprite.spriteSheetWidth + x, col, row);
          col++;
          if(col >= maxCol) {
            row++;
            col = 0;
          }
        }
      }
      
      int x = (e.offset.x/Sprite.scaledSpriteSize).floor() - (sizeX/2).floor();
      int y = (e.offset.y/Sprite.scaledSpriteSize).floor() - (sizeY/2).floor();
      
      // outline the tiles
      canvas.context2D.lineWidth = 4;
      canvas.context2D.setStrokeColorRgb(255, 255, 255, 1.0);
      canvas.context2D.strokeRect(
        Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2,
        (Sprite.scaledSpriteSize * sizeX) + 4, (Sprite.scaledSpriteSize * sizeY) + 4
      );
      
      canvas.context2D.lineWidth = 2;
      canvas.context2D.setStrokeColorRgb(0, 0, 0, 1.0);
      canvas.context2D.strokeRect(
        Sprite.scaledSpriteSize * x - 2, Sprite.scaledSpriteSize * y - 2,
        (Sprite.scaledSpriteSize * sizeX) + 4, (Sprite.scaledSpriteSize * sizeY) + 4
      );
    });
    
    container.style.display = "block";
    shade.style.display = "block";
  }
  
  static void avoidNameCollision(Event e, String match, Map<String, Object> objects) {
    if(e == null) {
      return;
    }
    
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains(match) && objects.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; objects.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      }
    }
  }
  
  static void enforceValueFormat(Event e) {
    if(e == null) {
      return;
    }
    
    if(e.target is TextInputElement) {
      TextInputElement inputElement = e.target;
      
      if(inputElement.getAttribute("type") == "checkbox") {
        return;
      }
      
      int position = inputElement.selectionStart;
      
      if(inputElement.classes.contains("decimal")) {
        inputElement.value = inputElement.value.replaceAll(new RegExp(r'[^0-9\.]'), "");
      } else if(inputElement.classes.contains("number")) {
        inputElement.value = inputElement.value.replaceAll(new RegExp(r'[^0-9]'), "");
      } else {
        inputElement.value = inputElement.value.replaceAll(new RegExp(r'[^a-zA-Z0-9\._\ ,~!@#$%^&*()_+`\-=\[\]\\{}\|;:,./<>?]'), "_");
      }
      
      inputElement.setSelectionRange(position, position);
    }
  }
  
  static void updateAndRetainValue(Event e) {
    if(e == null) {
      Editor.update();
      return;
    }
    
    if(e.target is TextInputElement) {
      // save the cursor location
      TextInputElement target = e.target;
      
      if(target.getAttribute("type") == "checkbox") {
        Editor.debounceUpdate();
        return;
      }
      
      TextInputElement inputElement = querySelector('#' + target.id);
      int position = inputElement.selectionStart;
      String valueBefore = inputElement.value;
      
      // update everything
      Editor.debounceUpdate(() {
        // restore the cursor position
        inputElement = querySelector('#' + target.id);
        inputElement.value = valueBefore;
        inputElement.focus();
        inputElement.setSelectionRange(position, position);
      });
    } else if(e.target is TextAreaElement) {
      // save the cursor location
      TextAreaElement target = e.target;
      TextAreaElement inputElement = querySelector('#' + target.id);
      int position = inputElement.selectionStart;
      String valueBefore = inputElement.value;
      
      // update everything
      Editor.debounceUpdate(() {
        // restore the cursor position
        inputElement = querySelector('#' + target.id);
        inputElement.value = valueBefore;
        inputElement.focus();
        inputElement.setSelectionRange(position, position);
      });
    } else {
      // update everything
      Editor.update();
    }
  }
  
  static void attachInputListeners(String prefix, List<String> attrs, Function onInputChange) {
    for(String attr in attrs) {
      String selector = "#${prefix}_${attr}";
      
      if(listeners[selector] != null)
        listeners[selector].cancel();
      
      HtmlElement element = querySelector(selector);
      String type = element.getAttribute("type");
      
      if(type == "text" || element is TextAreaElement) {
        listeners[selector] = element.onInput.listen(onInputChange);
      } else if(type == "checkbox" || element is SelectElement) {
        listeners[selector] = element.onChange.listen(onInputChange);
      } else {
        print("Error: unknown input type while attaching listener!");
      }
    }
  }
  
  static void attachButtonListener(String selector, Function onClick) {
    if(listeners[selector] != null)
      listeners[selector].cancel();
    
    listeners[selector] = querySelector(selector).onClick.listen(onClick);
  }
  
  static String getSelectInputStringValue(String selector) {
    try {
      return (querySelector(selector) as SelectElement).value;
    } catch(e) {
      return "";
    }
  }
  
  static int getSelectInputIntValue(String selector, int defaultValue) {
    try {
      return int.parse((querySelector(selector) as SelectElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
  
  static String getTextAreaStringValue(String selector) {
    try {
      return (querySelector(selector) as TextAreaElement).value;
    } catch(e) {
      return "";
    }
  }
  
  static String getTextInputStringValue(String selector) {
    return (querySelector(selector) as TextInputElement).value;
  }
  
  static int getTextInputIntValue(String selector, int defaultValue) {
    try {
      return int.parse((querySelector(selector) as TextInputElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
  
  static double getTextInputDoubleValue(String selector, double defaultValue) {
    try {
      return double.parse((querySelector(selector) as TextInputElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
  
  static bool getCheckboxInputBoolValue(String selector) {
    try {
      return (querySelector(selector) as CheckboxInputElement).checked;
    } catch(e) {
      return false;
    }
  }
  
  static int getRadioInputIntValue(String selector, int defaultValue) {
    try {
      return int.parse((querySelector(selector) as RadioButtonInputElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
}