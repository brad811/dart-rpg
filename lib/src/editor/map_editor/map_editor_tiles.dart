library dart_rpg.map_editor_tiles;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_events.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_signs.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor_warps.dart';

import 'package:react/react.dart';

// TODO: allow for dynamic number of layers

class MapEditorTiles extends Component {
  CanvasElement mapEditorSelectedSpriteCanvas;
  CanvasRenderingContext2D mapEditorSelectedSpriteCanvasContext;

  static List<String> availableTools = ["select", "brush", "erase", "fill", "stamp"];

  componentDidMount(Element rootNode) {
    mapEditorSelectedSpriteCanvas = querySelector('#editor_selected_sprite_canvas');
    mapEditorSelectedSpriteCanvasContext = mapEditorSelectedSpriteCanvas.getContext("2d");
    
    // picked sprite canvas
    Main.fixImageSmoothing(
      mapEditorSelectedSpriteCanvas,
      (Sprite.scaledSpriteSize).round(),
      (Sprite.scaledSpriteSize).round()
    );

    updateSelectedSpriteCanvas();
  }

  shouldComponentUpdate(Map nextProps, Map nextState) {
    if(MapEditor.previousSelectedTool != MapEditor.selectedTool) {
      MapEditor.selectTool(MapEditor.selectedTool);
      update();
      return false;
    }

    return true;
  }

  void update() {
    setState({});
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    updateSelectedSpriteCanvas();
  }

  void updateSelectedSpriteCanvas() {
    mapEditorSelectedSpriteCanvasContext.fillStyle = "#ff00ff";
    mapEditorSelectedSpriteCanvasContext.fillRect(0, 0, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    MapEditor.renderStaticSprite(mapEditorSelectedSpriteCanvasContext, MapEditor.selectedTile, 0, 0);
  }

  onSelectedLayerChange(Event e) {
    MapEditor.selectedLayer = Editor.getRadioInputIntValue("[name='layer']:checked", 0);
    update();
  }

  onTileBrushAttributeChange(Event e) {
    MapEditor.brushSolid = Editor.getCheckboxInputBoolValue("#brushSolid");
    MapEditor.brushLayered = Editor.getCheckboxInputBoolValue("#brushLayered");
    MapEditor.brushEncounter = Editor.getCheckboxInputBoolValue("#brushEncounter");
    update();
  }

  render() {
    List<String> layers = ["Ground", "Below", "Player", "Above"];
    List<JsObject> layerRows = [];
    for(int i=layers.length-1; i>=0; i--) {
      layerRows.addAll([
        div({
          'className': 'layer_visiblity_toggle fa ${ MapEditor.layerVisible[i] ? 'fa-eye' : 'fa-eye-slash' }',
          'onClick': (Event e) {
            MapEditor.layerVisible[i] = !MapEditor.layerVisible[i];
            MapEditor.updateMap();
            update();
          }
        }),
        input({
          'type': 'radio',
          'name': 'layer',
          'value': i,
          'checked': MapEditor.selectedLayer == i,
          'onChange': onSelectedLayerChange
        }, layers[i]), br({'className': 'breaker'})
      ]);
    }

    return
      div({'id': 'tiles_tab', 'className': 'tab'},
        div({
          'id': 'tool_selector_select',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "select" ? 'selected' : ''),
          'onClick': (MouseEvent e) { MapEditor.selectTool("select"); update(); }
        }, "Select"),
        div({
          'id': 'tool_selector_brush',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "brush" ? 'selected' : ''),
          'onClick': (MouseEvent e) { MapEditor.selectTool("brush"); update(); }
        }, "Brush"),
        div({
          'id': 'tool_selector_erase',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "erase" ? 'selected' : ''),
          'onClick': (MouseEvent e) { MapEditor.selectTool("erase"); update(); }
        }, "Erase"),
        div({
          'id': 'tool_selector_fill',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "fill" ? 'selected' : ''),
          'onClick': (MouseEvent e) { MapEditor.selectTool("fill"); update(); }
        }, "Fill"),
        div({
          'id': 'tool_selector_stamp',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "stamp" ? 'selected' : ''),
          'onClick': (MouseEvent e) { MapEditor.selectTool("stamp"); update(); }
        }, "Stamp"),
        div({'id': 'stamp_tool_size'},
          "Width: ",
          input({
            'id': 'stamp_tool_width',
            'type': 'text',
            'className': 'number',
            'value': MapEditor.stampWidth,
            'onChange': (Event e) { MapEditor.stampWidth = Editor.getTextInputIntValue("#stamp_tool_width", 1); }
          }),
          br({}),
          "Height: ",
          input({
            'id': 'stamp_tool_height',
            'type': 'text',
            'className': 'number',
            'value': MapEditor.stampHeight,
            'onChange': (Event e) { MapEditor.stampHeight = Editor.getTextInputIntValue("#stamp_tool_height", 1); }
          })
        ),
        br({'className': 'breaker'}),

        table({'className': 'editor_table'}, tbody({},
          tr({},
            td({},
              canvas({'id': 'editor_selected_sprite_canvas', 'width': 32, 'height': 32})
            ),
            td({'id': 'layer_container'}, layerRows),
            td({},
              input({
                'id': 'brushSolid',
                'type': 'checkbox',
                'value': MapEditor.brushSolid,
                'onChange': onTileBrushAttributeChange
              }, "Solid"),  br({}),
              input({
                'id': 'brushLayered',
                'type': 'checkbox',
                'value': MapEditor.brushLayered,
                'onChange': onTileBrushAttributeChange
              }, "Layered"), br({}),
              input({
                'id': 'brushEncounter',
                'type': 'checkbox',
                'value': MapEditor.brushEncounter,
                'onChange': onTileBrushAttributeChange
              }, "Encounter")
            )
          )
        )),

        div({'id': 'size_buttons_container'},
          table({}, tbody({},
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_up_button_pre', 'onClick': (MouseEvent e) { sizeUpTop(); }, 'className': 'fa fa-plus'})
              ),
              td({'colSpan': 2})
            ),
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_down_button_pre', 'onClick': (MouseEvent e) { sizeDownTop(); }, 'className': 'fa fa-minus'})
              ),
              td({'colSpan': 2})
            ),
            tr({},
              td({},
                button({'id': 'size_x_up_button_pre', 'onClick': (MouseEvent e) { sizeUpLeft(); }, 'className': 'fa fa-plus'})
              ),
              td({},
                button({'id': 'size_x_down_button_pre', 'onClick': (MouseEvent e) { sizeDownLeft(); }, 'className': 'fa fa-minus'})
              ),
              td({'className': 'center'},
                "Resize Map",
                div({
                  'id': 'cur_map_size'
                }, "${Main.world.maps[Main.world.curMap].tiles[0].length} x ${Main.world.maps[Main.world.curMap].tiles.length}")
              ),
              td({},
                button({'id': 'size_x_down_button', 'onClick': (MouseEvent e) { sizeDownRight(); }, 'className': 'fa fa-minus'})
              ),
              td({},
                button({'id': 'size_x_up_button', 'onClick': (MouseEvent e) { sizeUpRight(); }, 'className': 'fa fa-plus'})
              )
            ),
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_down_button', 'onClick': (MouseEvent e) { sizeDownBottom(); }, 'className': 'fa fa-minus'})
              ),
              td({'colSpan': 2})
            ),
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_up_button', 'onClick': (MouseEvent e) { sizeUpBottom(); }, 'className': 'fa fa-plus'})
              ),
              td({'colSpan': 2})
            )
          ))
        ),

        div({'id': 'layer_visibility_toggles'},
          br({}),
          input({
            'id': 'layer_visible_special',
            'type': 'checkbox',
            'checked': Editor.highlightSpecialTiles,
            'onChange': (Event e) {
              Editor.highlightSpecialTiles = Editor.getCheckboxInputBoolValue("#layer_visible_special");
              MapEditor.updateMap();
              update();
            }
          }, "Highlight Special Tiles"),
          br({}),
          br({}),
          input({
            'id': 'should_show_tooltip',
            'type': 'checkbox',
            'checked': Editor.shouldShowTooltip,
            'onChange': (Event e) {
              Editor.shouldShowTooltip = Editor.getCheckboxInputBoolValue("#should_show_tooltip");
              update();
            }
          }, "Show Tooltip"),
          br({})
        )
      );
  }

  void shiftObjects(int xAmount, int yAmount) {
    if(xAmount == 0 && yAmount == 0) {
      return;
    }
    
    // TODO
    //ref('mapEditorMaps').shift(xAmount, yAmount);
    MapEditorWarps.shift(xAmount, yAmount);
    MapEditorSigns.shift(xAmount, yAmount);
    MapEditorEvents.shift(xAmount, yAmount);

    // shift characters
    World.characters.forEach((String characterLabel, Character character) {
      if(character.map != Main.world.curMap)
        return;
      
      character.mapX += xAmount;
      character.mapY += yAmount;
      
      character.x = character.mapX * character.motionAmount;
      character.y = character.mapY * character.motionAmount;
    });
    
    // shift warp game event destinations
    World.gameEventChains.values.forEach((List<GameEvent> gameEventChain) {
      gameEventChain.forEach((GameEvent gameEvent) {
        if(gameEvent is WarpGameEvent) {
          gameEvent.x += xAmount;
          gameEvent.y += yAmount;
        }
      });
    });
  }

  void sizeDownRight() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
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
    
    shiftObjects(0, 0);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeUpRight() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 0)
      mapTiles.add([]);
    
    for(int y=0; y<mapTiles.length; y++) {
      List<Tile> array = [];
      for(int k=0; k<World.layers.length; k++) {
        array.add(null);
      }
      mapTiles[y].add(array);
    }
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeDownBottom() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 1)
      return;
    
    mapTiles.removeLast();
    
    shiftObjects(0, 0);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeUpBottom() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<List<Tile>> rowArray = [];
    
    for(int x=0; x<mapTiles[0].length; x++) {
      List<Tile> array = [];
      for(int k=0; k<World.layers.length; k++) {
        array.add(null);
      }
      rowArray.add(array);
    }
    
    mapTiles.add(rowArray);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeDownLeft() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
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
    
    shiftObjects(-1, 0);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeUpLeft() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
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
    
    shiftObjects(1, 0);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeDownTop() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
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
    
    shiftObjects(0, -1);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
  
  void sizeUpTop() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
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
    
    shiftObjects(0, 1);
    
    MapEditor.updateMap();
    Editor.debounceExport();
    update();
  }
}