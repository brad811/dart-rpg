library dart_rpg.map_editor_tiles;

import 'dart:html';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

// TODO: allow for dynamic number of layers

class MapEditorTiles extends Component {
  componentDidMount(Element rootNode) {
    setUpLayerVisibilityToggles();
    setUpMapSizeButtons();
  }

  render() {
    return
      div({'id': 'tiles_tab', 'className': 'tab'}, [
        div({'id': 'tool_selector_select', 'className': 'tool_selector'}, "Select"),
        div({'id': 'tool_selector_brush', 'className': 'tool_selector'}, "Brush"),
        div({'id': 'tool_selector_erase', 'className': 'tool_selector'}, "Erase"),
        div({'id': 'tool_selector_fill', 'className': 'tool_selector'}, "Fill"),
        div({'id': 'tool_selector_stamp', 'className': 'tool_selector'}, "Stamp"),
        div({'id': 'stamp_tool_size'}, [
          "Width: ", input({'id': 'stamp_tool_width', 'type': 'text', 'className': 'number'}),
          br({}),
          "Height: ", input({'id': 'stamp_tool_height', 'type': 'text', 'className': 'number'}),
        ]),
        br({'className': 'breaker'}),

        table({'className': 'editor_table'}, tbody({}, [
          tr({}, [
            td({},
              canvas({'id': 'editor_selected_sprite_canvas', 'width': 32, 'height': 32})
            ),
            td({}, [
              input({'type': 'radio', 'name': 'layer', 'value': 3}, "Above"), br({}),
              input({'type': 'radio', 'name': 'layer', 'value': 2}, "Player"), br({}),
              input({'type': 'radio', 'name': 'layer', 'value': 1}, "Below"), br({}),
              input({'type': 'radio', 'name': 'layer', 'value': 0}, "Ground"), br({})
            ]),
            td({}, [
              input({'id': 'solid', 'type': 'checkbox'}, "Solid"),  br({}),
              input({'id': 'solid', 'type': 'checkbox'}, "Layered"), br({}),
              input({'id': 'solid', 'type': 'checkbox'}, "Encounter")
            ])
          ])
        ])),

        div({'id': 'size_buttons_container'}, [
          table({}, tbody({}, [
            tr({}, [
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_up_button_pre'}, "+")
              ),
              td({'colSpan': 2})
            ]),
            tr({}, [
              td({'colSpan': 2}),
              td({},
                button({'id': 'size_y_down_button_pre'}, "-")
              ),
              td({'colSpan': 2})
            ]),
            tr({}, [
              td({},
                button({'id': 'size_x_up_button_pre'}, "+")
              ),
              td({},
                button({'id': 'size_x_down_button_pre'}, "-")
              ),
              td({'className': 'center'}, [
                "Resize Map",
                div({'id': 'cur_map_size'})
              ]),
              td({},
                button({'id': 'size_x_down_button'}, "-")
              ),
              td({},
                button({'id': 'size_x_up_button'}, "+")
              )
            ]),
            tr({}, [
              td({'colSpan': 2}),
              td({}, [
                button({'id': 'size_y_down_button'}, "-")
              ]),
              td({'colSpan': 2})
            ]),
            tr({}, [
              td({'colSpan': 2}),
              td({}, [
                button({'id': 'size_y_up_button'}, "+")
              ]),
              td({'colSpan': 2})
            ])
          ]))
        ]),

        div({'id': 'layer_visibility_toggles'}, [
          h4({}, "Layer Visibility"),
          input({'id': 'layer_visible_above', 'type': 'checkbox', 'value': true}, "Above"), br({}),
          input({'id': 'layer_visible_player', 'type': 'checkbox', 'value': true}, "Player"), br({}),
          input({'id': 'layer_visible_below', 'type': 'checkbox', 'value': true}, "Below"), br({}),
          input({'id': 'layer_visible_ground', 'type': 'checkbox', 'value': true}, "Ground"), br({}),
          br({}),
          input({'id': 'layer_visible_special', 'type': 'checkbox', 'value': true}, "Highlight Special Tiles"),
          br({})
        ])
      ]);
  }

  void setUpLayerVisibilityToggles() {
    Editor.attachInputListeners("layer_visible",
      ["above", "player", "below", "ground", "special"],
      (_) {
        MapEditor.layerVisible[World.LAYER_ABOVE] = Editor.getCheckboxInputBoolValue("#layer_visible_above");
        MapEditor.layerVisible[World.LAYER_PLAYER] = Editor.getCheckboxInputBoolValue("#layer_visible_player");
        MapEditor.layerVisible[World.LAYER_BELOW] = Editor.getCheckboxInputBoolValue("#layer_visible_below");
        MapEditor.layerVisible[World.LAYER_GROUND] = Editor.getCheckboxInputBoolValue("#layer_visible_ground");
        
        Editor.highlightSpecialTiles = Editor.getCheckboxInputBoolValue("#layer_visible_special");
        
        props['update']();
      }
    );
  }

  void setUpMapSizeButtons() {
    Editor.attachButtonListener("#size_x_down_button", (_) { sizeDownRight(); });
    Editor.attachButtonListener("#size_x_up_button", (_) { sizeUpRight(); });
    Editor.attachButtonListener("#size_y_down_button", (_) { sizeDownBottom(); });
    Editor.attachButtonListener("#size_y_up_button", (_) { sizeUpBottom(); });
    
    Editor.attachButtonListener("#size_x_down_button_pre", (_) { sizeDownLeft(); });
    Editor.attachButtonListener("#size_x_up_button_pre", (_) { sizeUpLeft(); });
    Editor.attachButtonListener("#size_y_down_button_pre", (_) { sizeDownTop(); });
    Editor.attachButtonListener("#size_y_up_button_pre", (_) { sizeUpTop(); });
  }

  void shiftObjects(int xAmount, int yAmount) {
    if(xAmount == 0 && yAmount == 0) {
      return;
    }
    
    props['shift'](xAmount, yAmount);

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
    
    props['update']();
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
    
    props['update']();
  }
  
  void sizeDownBottom() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    if(mapTiles.length == 1)
      return;
    
    mapTiles.removeLast();
    
    shiftObjects(0, 0);
    
    props['update']();
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
    
    props['update']();
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
    
    props['update']();
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
    
    props['update']();
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
    
    props['update']();
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
    
    props['update']();
  }
}