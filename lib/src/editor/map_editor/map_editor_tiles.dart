library dart_rpg.map_editor_tiles;

import 'dart:html';

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

import 'package:react/react.dart';

// TODO: allow for dynamic number of layers

class MapEditorTiles extends Component {
  CanvasElement mapEditorSelectedSpriteCanvas;
  CanvasRenderingContext2D mapEditorSelectedSpriteCanvasContext;

  static String previousSelectedTool;
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
    // TODO: perhaps move to componentShouldUpdate and stop update if true
    if(previousSelectedTool != MapEditor.selectedTool) {
      selectTool(MapEditor.selectedTool);
      return false;
    }

    return true;
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    updateSelectedSpriteCanvas();
  }

  void updateSelectedSpriteCanvas() {
    mapEditorSelectedSpriteCanvasContext.fillStyle = "#ff00ff";
    mapEditorSelectedSpriteCanvasContext.fillRect(0, 0, Sprite.scaledSpriteSize, Sprite.scaledSpriteSize);
    MapEditor.renderStaticSprite(mapEditorSelectedSpriteCanvasContext, MapEditor.selectedTile, 0, 0);
  }

  void update() {
    setState({});
  }

  void selectTool(String newTool) {
    if(newTool == "erase") {
      MapEditor.previousSelectedTile = MapEditor.selectedTile;
      MapEditor.selectedTile = -1;
    } else {
      MapEditor.selectedTile = MapEditor.previousSelectedTile;
      MapEditor.selectedTile = MapEditor.selectedTile;
    }

    if(MapEditor.selectedTool == "select" && newTool != "select") {
      MapEditor.tileInfo.style.display = "none";
      MapEditor.updateMap();
    }

    MapEditor.selectedTool = newTool;

    MapEditor.lastChangeX = -1;
    MapEditor.lastChangeY = -1;

    previousSelectedTool = MapEditor.selectedTool;

    update();
  }

  onSelectedLayerChange(Event e) {
    MapEditor.selectedLayer = Editor.getRadioInputIntValue("[name='layer']:checked", 0);
  }

  render() {
    return
      div({'id': 'tiles_tab', 'className': 'tab'},
        div({
          'id': 'tool_selector_select',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "select" ? 'selected' : ''),
          'onClick': (MouseEvent e) { selectTool("select"); }
        }, "Select"),
        div({
          'id': 'tool_selector_brush',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "brush" ? 'selected' : ''),
          'onClick': (MouseEvent e) { selectTool("brush"); }
        }, "Brush"),
        div({
          'id': 'tool_selector_erase',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "erase" ? 'selected' : ''),
          'onClick': (MouseEvent e) { selectTool("erase"); }
        }, "Erase"),
        div({
          'id': 'tool_selector_fill',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "fill" ? 'selected' : ''),
          'onClick': (MouseEvent e) { selectTool("fill"); }
        }, "Fill"),
        div({
          'id': 'tool_selector_stamp',
          'className': 'tool_selector ' + (MapEditor.selectedTool == "stamp" ? 'selected' : ''),
          'onClick': (MouseEvent e) { selectTool("stamp"); }
        }, "Stamp"),
        div({'id': 'stamp_tool_size'},
          "Width: ", input({'id': 'stamp_tool_width', 'type': 'text', 'className': 'number'}),
          br({}),
          "Height: ", input({'id': 'stamp_tool_height', 'type': 'text', 'className': 'number'})
        ),
        br({'className': 'breaker'}),

        table({'className': 'editor_table'}, tbody({},
          tr({},
            td({},
              canvas({'id': 'editor_selected_sprite_canvas', 'width': 32, 'height': 32})
            ),
            td({},
              input({
                'type': 'radio',
                'name': 'layer',
                'value': 3,
                'checked': MapEditor.selectedLayer == 3,
                'onChange': onSelectedLayerChange
              }, "Above"), br({}),
              input({
                'type': 'radio',
                'name': 'layer',
                'value': 2,
                'checked': MapEditor.selectedLayer == 2,
                'onChange': onSelectedLayerChange
              }, "Player"), br({}),
              input({
                'type': 'radio',
                'name': 'layer',
                'value': 1,
                'checked': MapEditor.selectedLayer == 1,
                'onChange': onSelectedLayerChange
              }, "Below"), br({}),
              input({
                'type': 'radio',
                'name': 'layer',
                'value': 0,
                'checked': MapEditor.selectedLayer == 0,
                'onChange': onSelectedLayerChange
              }, "Ground"), br({})
            ),
            td({},
              input({'id': 'solid', 'type': 'checkbox'}, "Solid"),  br({}),
              input({'id': 'solid', 'type': 'checkbox'}, "Layered"), br({}),
              input({'id': 'solid', 'type': 'checkbox'}, "Encounter")
            )
          )
        )),

        div({'id': 'size_buttons_container'},
          table({}, tbody({},
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_up_button_pre', 'onClick': (MouseEvent e) { sizeUpTop(); }}, "+")
              ),
              td({'colSpan': 2})
            ),
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_down_button_pre', 'onClick': (MouseEvent e) { sizeDownTop(); }}, "-")
              ),
              td({'colSpan': 2})
            ),
            tr({},
              td({},
                button({'id': 'size_x_up_button_pre', 'onClick': (MouseEvent e) { sizeUpLeft(); }}, "+")
              ),
              td({},
                button({'id': 'size_x_down_button_pre', 'onClick': (MouseEvent e) { sizeDownLeft(); }}, "-")
              ),
              td({'className': 'center'},
                "Resize Map",
                div({'id': 'cur_map_size'})
              ),
              td({},
                button({'id': 'size_x_down_button', 'onClick': (MouseEvent e) { sizeDownRight(); }}, "-")
              ),
              td({},
                button({'id': 'size_x_up_button', 'onClick': (MouseEvent e) { sizeUpRight(); }}, "+")
              )
            ),
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_down_button', 'onClick': (MouseEvent e) { sizeDownBottom(); }}, "-")
              ),
              td({'colSpan': 2})
            ),
            tr({},
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_up_button', 'onClick': (MouseEvent e) { sizeUpBottom(); }}, "+")
              ),
              td({'colSpan': 2})
            )
          ))
        ),

        div({'id': 'layer_visibility_toggles'},
          h4({}, "Layer Visibility"),
          input({
            'id': 'layer_visible_above',
            'type': 'checkbox',
            'checked': MapEditor.layerVisible[World.LAYER_ABOVE],
            'onChange': (Event e) {
              MapEditor.layerVisible[World.LAYER_ABOVE] = Editor.getCheckboxInputBoolValue("#layer_visible_above");
              MapEditor.updateMap();
              update();
            }
          }, "Above"), br({}),
          input({
            'id': 'layer_visible_player',
            'type': 'checkbox',
            'checked': MapEditor.layerVisible[World.LAYER_PLAYER],
            'onChange': (Event e) {
              MapEditor.layerVisible[World.LAYER_PLAYER] = Editor.getCheckboxInputBoolValue("#layer_visible_player");
              MapEditor.updateMap();
              update();
            }
          }, "Player"), br({}),
          input({
            'id': 'layer_visible_below',
            'type': 'checkbox',
            'checked': MapEditor.layerVisible[World.LAYER_BELOW],
            'onChange': (Event e) {
              MapEditor.layerVisible[World.LAYER_BELOW] = Editor.getCheckboxInputBoolValue("#layer_visible_below");
              MapEditor.updateMap();
              update();
            }
          }, "Below"), br({}),
          input({
            'id': 'layer_visible_ground',
            'type': 'checkbox',
            'checked': MapEditor.layerVisible[World.LAYER_GROUND],
            'onChange': (Event e) {
              MapEditor.layerVisible[World.LAYER_GROUND] = Editor.getCheckboxInputBoolValue("#layer_visible_ground");
              MapEditor.updateMap();
              update();
            }
          }, "Ground"), br({}),
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
    
    MapEditor.updateMap(shouldExport: true);
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
    
    MapEditor.updateMap(shouldExport: true);
    update();
  }
  
  void sizeDownBottom() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 1)
      return;
    
    mapTiles.removeLast();
    
    shiftObjects(0, 0);
    
    MapEditor.updateMap(shouldExport: true);
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
    
    MapEditor.updateMap(shouldExport: true);
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
    
    MapEditor.updateMap(shouldExport: true);
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
    
    MapEditor.updateMap(shouldExport: true);
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
    
    MapEditor.updateMap(shouldExport: true);
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
    
    MapEditor.updateMap(shouldExport: true);
    update();
  }
}