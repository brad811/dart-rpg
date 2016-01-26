library dart_rpg.editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'dart:math' as math;

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';
import 'package:dart_rpg/src/editor/screen_editor.dart';
import 'package:dart_rpg/src/editor/settings.dart';

import 'package:react/react.dart';

// TODO: equation editor? (exp reqired to level up, chance to escape battle, stat gains from leveling up, exp gained from battle)

var mapEditor = registerComponent(() => new MapEditor());
var objectEditor = registerComponent(() => new ObjectEditor());
var screenEditor = registerComponent(() => new ScreenEditor());
var settings = registerComponent(() => new Settings());

class Editor extends Component {
  static List<String> editorTabs = ["map_editor", "object_editor", "screen_editor", "settings"];
  
  static bool highlightSpecialTiles = true;
  
  static StreamSubscription resizeListener;
  static Map<String, StreamSubscription> listeners = new Map<String, StreamSubscription>();
  static Map<String, StreamSubscription> popupSpritePickerCanvasListeners = new Map<String, StreamSubscription>();

  static String exportJsonString = "";

  getInitialState() => {
    'gameLoaded': false,
    'doneSettingUp': false,
    'selectedTab': 'mapEditor'
  };

  componentDidMount(Element rootNode) {
    Main.world = new World(() {
      Main.world.loadGame(() {
        this.setState({'gameLoaded': true});
        Editor.export();
      });
    });
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    if(!this.state['doneSettingUp']) {
      if(resizeListener != null) {
        resizeListener.cancel();
      }
      resizeListener = window.onResize.listen(handleResize);
      handleResize(null);

      this.setState({'doneSettingUp': true});
    }
  }

  void handleResize(Event e) {
    querySelector('#container').style.height = "${window.innerHeight - 10}px";
  }

  render() {
    if(!this.state['gameLoaded']) {
      return div({}, "Loading game...");
    }

    JsObject selectedTab;
    if(state['selectedTab'] == 'mapEditor') {
      selectedTab = mapEditor({'update': update, 'debounceUpdate': debounceUpdate});
    } else if(state['selectedTab'] == 'objectEditor') {
      selectedTab = objectEditor({'update': update});
    } else if(state['selectedTab'] == 'screenEditor') {
      selectedTab = screenEditor({'update': update});
    } else if(state['selectedTab'] == 'settings') {
      selectedTab = settings({'update': update});
    }

    return
      div({},
        table({'id': 'container'}, tbody({},
          tr({},
            td({'id': 'editor_tabs', 'colSpan': 2},
              div({
                'id': 'map_editor_tab_header',
                'className': 'tab_header ' + (state['selectedTab'] == 'mapEditor' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedTab': 'mapEditor'}); }
              }, "Map Editor"),
              div({
                'id': 'object_editor_tab_header',
                'className': 'tab_header ' + (state['selectedTab'] == 'objectEditor' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedTab': 'objectEditor'}); }
              }, "Object Editor"),
              div({
                'id': 'screen_editor_tab_header',
                'className': 'tab_header ' + (state['selectedTab'] == 'screenEditor' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedTab': 'screenEditor'}); }
              }, "Screen Editor"),
              div({
                'id': 'settings_tab_header',
                'className': 'tab_header ' + (state['selectedTab'] == 'settings' ? 'selected' : ''),
                'onClick': (MouseEvent e) { setState({'selectedTab': 'settings'}); }
              }, "Settings"),

              // TODO: make this a component
              div({'id': 'game_storage_container'}, "Loading...")
            )
          ),
          selectedTab
        )),
        div({'id': 'tooltip'}),
        div({'id': 'popup_shade'}),
        div({'id': 'popup_sprite_selector_container'},
          canvas({'id': 'popup_sprite_selector_canvas'})
        )
      );
  }
  
  static void loadGame(Function callback) {
    Main.world.parseGame(Editor.getTextAreaStringValue("#export_json"), () {
      callback();
    });
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

  static void debounceExport() {
    if(debounceExportTimer != null) {
      debounceExportTimer.cancel();
    }

    debounceExportTimer = new Timer(debounceExportDelay, () {
      Editor.export();
    });
  }
  
  void update({bool shouldExport: false}) {
    this.setState({});

    if(shouldExport) {
      Editor.export();
    }
  }
  
  static void export() {
    print("Exporting...");

    Map<String, Map<String, Map<String, Object>>> exportJson = {};
    MapEditor.export(exportJson);
    ObjectEditor.export(exportJson);
    ScreenEditor.export(exportJson);
    Settings.export(exportJson);
    
    Editor.exportJsonString = JSON.encode(exportJson);

    TextAreaElement exportJsonTextarea = querySelector("#export_json");
    if(exportJsonTextarea != null) {
      exportJsonTextarea.value = Editor.exportJsonString;
    }
  }

  static Function generateConfirmDeleteFunction(Object target, Object key, String targetName, Function callback) {
    return (MouseEvent e) {
      bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
      if(confirm) {
        if(target is Map)
          target.remove(key);
        else if(target is List)
          target.removeAt(key);
        else
          print("Warning: invalid target passed to generateConfirmDeleteFunction!");

        callback();
      }
    };
  }

  @deprecated
  static void confirmMapDelete(Map<Object, Object> target, Object key, String targetName, Function callback) {
    bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
    if(confirm) {
      target.remove(key);
      callback();
    }
  }

  @deprecated
  static void confirmListDelete(List<Object> target, int offset, String targetName, Function callback) {
    bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
    if(confirm) {
      target.removeAt(offset);
      callback();
    }
  }
  
  static void setMapDeleteButtonListeners(Map<Object, Object> target, String targetName, Function callback) {
    for(int i=0; i<target.keys.length; i++) {
      if(listeners["#delete_${targetName}_${i}"] != null)
        listeners["#delete_${targetName}_${i}"].cancel();
      
      listeners["#delete_${targetName}_${i}"] =
          querySelector("#delete_${targetName}_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
        if(confirm) {
          target.remove(target.keys.elementAt(i));
          callback();
        }
      });
    }
  }
  
  static void setListDeleteButtonListeners(List<Object> target, String targetName, Function callback) {
    for(int i=0; i<target.length; i++) {
      if(listeners["#delete_${targetName}_${i}"] != null)
        listeners["#delete_${targetName}_${i}"].cancel();

      listeners["#delete_${targetName}_${i}"] =
          querySelector("#delete_${targetName}_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
        if(confirm) {
          target.removeAt(i);
          callback();
        }
      });
    }
  }
  
  static JsObject generateSpritePickerHtml(String prefix, int value, { bool readOnly: false }) {
    List<JsObject> elements = [
      canvas({'id': '${prefix}_canvas'}),
      br({}),
      input({
        'id': prefix,
        'type': 'text',
        'className': 'number',
        'value': value,
        'readOnly': readOnly
      })
    ];

    if(!readOnly) {
      elements.add(
        button({'id': '${prefix}_edit_button'}, "Edit")
      );
    }
    
    return div({}, elements);
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
  
  static void updateAndRetainValue(Event e, Function callback) {
    if(e == null) {
      callback();
      return;
    }
    
    if(e.target is TextInputElement) {
      // save the cursor location
      TextInputElement target = e.target;
      
      if(target.getAttribute("type") == "checkbox") {
        callback();
        return;
      }
      
      TextInputElement inputElement = querySelector('#' + target.id);
      int position = inputElement.selectionStart;
      String valueBefore = inputElement.value;
      
      // update everything
      callback(callback: () {
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
      callback(callback: () {
        // restore the cursor position
        inputElement = querySelector('#' + target.id);
        inputElement.value = valueBefore;
        inputElement.focus();
        inputElement.setSelectionRange(position, position);
      });
    } else {
      // update everything
      callback();
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