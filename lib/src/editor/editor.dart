library dart_rpg.editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'dart:math' as math;

import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/game_storage.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';
import 'package:dart_rpg/src/editor/screen_editor.dart';
import 'package:dart_rpg/src/editor/settings.dart';
import 'package:dart_rpg/src/editor/undo_redo.dart';

import 'package:react/react.dart';

// TODO: equation editor? (exp reqired to level up, chance to escape battle, stat gains from leveling up, exp gained from battle)

var mapEditor = registerComponent(() => new MapEditor());
var objectEditor = registerComponent(() => new ObjectEditor());
var screenEditor = registerComponent(() => new ScreenEditor());
var settings = registerComponent(() => new Settings());
var gameStorage = registerComponent(() => new GameStorage());
var undoRedo = registerComponent(() => new UndoRedo());

class Editor extends Component {
  static List<String> editorTabs = ["map_editor", "object_editor", "screen_editor", "settings"];
  
  static bool highlightSpecialTiles = true;
  static bool shouldShowTooltip = true;
  
  static StreamSubscription resizeListener;
  static Map<String, StreamSubscription> listeners = new Map<String, StreamSubscription>();
  static Map<String, StreamSubscription> popupSpritePickerCanvasListeners = new Map<String, StreamSubscription>();

  static String exportJsonString = "";

  static List<String> undoList = [];
  static int maxUndoListLength = 20;
  static int undoPosition = 0;
  static UndoRedo undoRedoObject;

  getInitialState() => {
    'gameLoaded': false,
    'doneSettingUp': false,
    'selectedTab': 'mapEditor'
  };

  static String selectedSubTab = "";
  static int selectedSubItemNumber = -1;

  static int gameLoadedTimestamp = 0;

  @override
  componentDidMount() {
    Main.world = new World(() {
      Main.world.loadGame(() {
        this.setState({'gameLoaded': true});

        undoList = [];
        undoPosition = 0;

        Editor.export();
      });
    });
  }

  @override
  componentDidUpdate(Map prevProps, Map prevState) {
    if(!this.state['doneSettingUp']) {
      if(resizeListener != null) {
        resizeListener.cancel();
      }
      resizeListener = window.onResize.listen(handleResize);
      handleResize(null);

      this.setState({'doneSettingUp': true});
    } else {
      undoRedoObject = ref('undoRedo');
    }
  }

  static void handleResize(Event e) {
    querySelector('#container').style.height = "${window.innerHeight - 10}px";
  }

  void goToEditObject(String subTab, int number) {
    Editor.selectedSubTab = subTab;
    Editor.selectedSubItemNumber = number;

    this.setState({
      'selectedTab': 'objectEditor'
    });
  }

  @override
  render() {
    if(!this.state['gameLoaded']) {
      return div({'id': 'editor_loading_screen'}, "Loading game...");
    }

    JsObject selectedTab;
    if(state['selectedTab'] == 'mapEditor') {
      selectedTab = mapEditor({
        'ref': 'mapEditor',
        'update': update,
        'debounceUpdate': debounceUpdate,
        'goToEditObject': goToEditObject
      });
    } else if(state['selectedTab'] == 'objectEditor') {
      selectedTab = objectEditor({
        'ref': 'objectEditor',
        'update': update
      });
    } else if(state['selectedTab'] == 'screenEditor') {
      selectedTab = screenEditor({'update': update});
    } else if(state['selectedTab'] == 'settings') {
      selectedTab = settings({'update': update});
    }

    return
      div({'key': gameLoadedTimestamp},
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

              undoRedo({'ref': 'undoRedo', 'undo': this.undo, 'redo': this.redo}),
              
              div({'id': 'game_storage_container'},
                gameStorage({'update': update})
              )
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
    if(querySelector("#export_json") != null) {
      (querySelector("#export_json") as TextAreaElement).value = "";
    }

    Main.world.parseGame(exportJsonString, () {
      MapEditor.loadSpecialTiles();
      gameLoadedTimestamp = new DateTime.now().millisecondsSinceEpoch;
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

  void undo() {
    if(undoPosition <= 1) {
      print("Can't undo any more!");
      return;
    }

    String curMapBefore = Main.world.curMap;
    String selectedTabBefore = this.state['selectedTab'];

    String mapEditorSelectedTabBefore;
    int scrollTop, scrollLeft;
    if(ref('mapEditor') != null) {
      mapEditorSelectedTabBefore = ref('mapEditor').state['selectedTab'];

      scrollTop = querySelector("#left_half").scrollTop;
      scrollLeft = querySelector("#left_half").scrollLeft;
    }

    String objectEditorSelectedTabBefore;
    if(ref('objectEditor') != null) {
      objectEditorSelectedTabBefore = ref('objectEditor').state['selectedTab'];
    }

    undoPosition--;
    Editor.exportJsonString = undoList[undoPosition - 1];
    Editor.loadGame(() {
      Main.world.curMap = curMapBefore;
      this.setState({
        'selectedTab': selectedTabBefore
      });

      if(ref('mapEditor') != null) {
        ref('mapEditor').setState({
          'selectedTab': mapEditorSelectedTabBefore
        }, () {
            querySelector("#left_half").scrollTop = scrollTop;
            querySelector("#left_half").scrollLeft = scrollLeft;
          }
        );
      }

      if(ref('objectEditor') != null) {
        ref('objectEditor').setState({
          'selectedTab': objectEditorSelectedTabBefore
        });
      }
    });
  }

  void redo() {
    if(undoPosition == undoList.length) {
      print("Can't redo any more!");
      return;
    }

    String curMapBefore = Main.world.curMap;

    int scrollTop, scrollLeft;
    if(ref('mapEditor') != null) {
      scrollTop = querySelector("#left_half").scrollTop;
      scrollLeft = querySelector("#left_half").scrollLeft;
    }

    undoPosition++;
    Editor.exportJsonString = undoList[undoPosition - 1];
    Editor.loadGame(() {
      Main.world.curMap = curMapBefore;
      this.setState({},
        () {
          querySelector("#left_half").scrollTop = scrollTop;
          querySelector("#left_half").scrollLeft = scrollLeft;
        }
      );
    });
  }
  
  static void export() {
    print("Exporting...");

    Map<String, Map<String, Map<String, Object>>> exportJson = {};
    MapEditor.export(exportJson);
    ObjectEditor.export(exportJson);
    ScreenEditor.export(exportJson);
    Settings.export(exportJson);

    String newExportJsonString = JSON.encode(exportJson);

    // if there was a change, add to the undo list
    if(Editor.exportJsonString != JSON.encode(exportJson)) {
      // if in the middle of the undo list, cut off everything after current position
      if(undoPosition < undoList.length) {
        undoList = undoList.sublist(0, undoPosition);
      }

      // add the new json to the undo list
      undoList.add(newExportJsonString);

      // trim the undo list if it's too long
      if(undoList.length > maxUndoListLength) {
        undoList = undoList.sublist(undoList.length - maxUndoListLength, undoList.length);
      }

      // set the undo position to the end
      undoPosition = undoList.length;

      undoRedoObject.setState({});
    }
    
    Editor.exportJsonString = newExportJsonString;

    TextAreaElement exportJsonTextarea = querySelector("#export_json");
    if(exportJsonTextarea != null) {
      exportJsonTextarea.value = Editor.exportJsonString;
    }
  }

  static Function generateConfirmDeleteFunction(
    Object target, Object key, String targetName, Function callback, {bool atLeastOneRequired: false}
  ) {
    return (MouseEvent e) {
      if(atLeastOneRequired) {
        if(
          (target is Map && target.keys.length == 1) ||
          (target is List && target.length == 1)
        ) {
          window.alert("There must be at least one ${targetName}.");
          return;
        }
      }

      bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
      if(confirm) {
        if(target is Map)
          target.remove(key);
        else if(target is List)
          target.removeAt(key);
        else if(target is Inventory)
          target.removeItem(key, target.getQuantity(key));
        else
          print("Warning: invalid target passed to generateConfirmDeleteFunction!");

        Editor.debounceExport();
        callback();
      }
    };
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
      Editor.generateInput({
        'id': prefix,
        'type': 'text',
        'className': 'number',
        'value': value,
        'readOnly': readOnly,
        'onChange': (Event e) {}
      })
    ];

    if(!readOnly) {
      elements.add(
        button({'id': '${prefix}_edit_button'}, span({'className': 'fa fa-pencil-square-o'}), " Edit")
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

  static void initMapSpritePicker(
    String prefix, int minX, int minY, int layer, int sizeX, int sizeY, Function onInputChange, { bool readOnly: false }
  ) {
    Main.fixImageSmoothing(
      querySelector("#${prefix}_canvas"),
      Sprite.scaledSpriteSize * sizeX,
      Sprite.scaledSpriteSize * sizeY
    );

    CanvasElement canvas = querySelector("#${prefix}_canvas");
    CanvasRenderingContext2D ctx = canvas.context2D;

    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, Sprite.scaledSpriteSize * sizeX, Sprite.scaledSpriteSize * sizeY);
    
    for(int x=minX; x<minX+sizeX; x++) {
      for(int y=minY; y<minY+sizeY; y++) {
        if(Main.world.maps[Main.world.curMap].tiles[y][x] == null || Main.world.maps[Main.world.curMap].tiles[y][x][layer] == null)
          continue;

        MapEditor.renderStaticSprite(
          ctx, Main.world.maps[Main.world.curMap].tiles[y][x][layer].sprite.id, x - minX, y - minY
        );
      }
    }
    
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
      InputElement inputElement = e.target;

      int position = inputElement.selectionStart;

      if(inputElement.value == "") {
        inputElement.value = "no_name";
      }
      
      if(inputElement.id.contains(match)) {
        inputElement.value = getUniqueName(inputElement.value, objects);
      }

      inputElement.setSelectionRange(position, position);
    }
  }

  static String getUniqueName(String value, Map<String, Object> objects) {
    if(objects.keys.contains(value)) {
      // avoid name collisions
      int i = 0;
      for(; objects.keys.contains(value + "_${i}"); i++) {}
      value += "_${i}";
    }

    return value;
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

      inputElement.value = inputElement.value.replaceAll(new RegExp(r'[^a-zA-Z0-9\._\ ,~!@#$%^&*()_+`\-=\[\]\\{}\|;:,./<>?]'), "_");

      if(inputElement.value.length > 0 && inputElement.classes.contains("number")) { // number
        if(inputElement.classes.contains("decimal")) { // decimal number
          inputElement.value = inputElement.value[0] + inputElement.value.substring(1).replaceAll(new RegExp("[\-]"), "");
          if(inputElement.value.indexOf(".") != inputElement.value.lastIndexOf(".")) {
            // there is more than one decimal, remove the extras
            inputElement.value =
              inputElement.value.substring(0, inputElement.value.indexOf(".") + 1) +
              inputElement.value.substring(inputElement.value.indexOf(".")).replaceAll(".", "");
          }

          if(inputElement.value.length > 12) {
            inputElement.value = inputElement.value.substring(0, 12);
          }
        } else { // integer number
          inputElement.value = inputElement.value.replaceAll(".", "");
          inputElement.value = inputElement.value[0] + inputElement.value.substring(1).replaceAll(new RegExp("[\-\.]"), "");
        }

        if(inputElement.classes.contains("positive")) {
          inputElement.value = inputElement.value.replaceAll("-", "");
        }
      }
      
      inputElement.setSelectionRange(position, position);
    }
  }

  static String getValueBefore(e) {
    if(e == null) {
      return "";
    }
    
    if(e.target is TextInputElement) {
      if(e.target.getAttribute("type") == "checkbox") {
        return "";
      }

      return e.target.value;
    } else if(e.target is TextAreaElement) {
      return e.target.value;
    }

    return "";
  }

  static String lastElementId, lastValue;
  static JsObject generateInput(Map obj) {
    String valueFieldName = 'value';
    if(obj['type'] == 'checkbox') {
      valueFieldName = 'checked';
    }

    return input({
      'id': obj['id'],
      'key': obj['id'],
      'type': obj['type'],
      'className': obj['className'],
      valueFieldName: Editor.lastElementId == obj['id'] ? Editor.lastValue : obj[valueFieldName],
      'onChange': (e) {
        Editor.enforceValueFormat(e);
        Editor.lastElementId = (e.target as HtmlElement).id;
        Editor.lastValue = Editor.getValueBefore(e);
        obj['onChange'](e);
      },
      'onFocus': (_) { lastElementId = obj['id']; lastValue = obj[valueFieldName]; }
    });
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