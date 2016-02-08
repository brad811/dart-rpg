library dart_rpg.map_editor_tile_info;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class MapEditorTileInfo extends Component {
  getInitialState() => {
    'x': 0,
    'y': 0,
    'sizeX': 0,
    'sizeY': 0
  };

  setTile(int x, int y, int sizeX, int sizeY) {
    this.setState({
      'x': x,
      'y': y,
      'sizeX': sizeX,
      'sizeY': sizeY
    });
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    List<String> layerNames = ["Ground", "Below", "Player", "Above"];

    int
      x = state['x'],
      y = state['y'],
      sizeX = this.state['sizeX'],
      sizeY = this.state['sizeY'];

    for(int i=layerNames.length-1; i>=0; i--) {
      if(querySelector("#tile_info_layer_${i}_sprite_id_canvas") != null) {
        Editor.initMapSpritePicker(
          "tile_info_layer_${i}_sprite_id", x, y, i, sizeX, sizeY, onInputChange, readOnly: (sizeX != 1 || sizeY != 1)
        );
      }
    }
  }

  Function deleteLayer(int layer) {
    return (MouseEvent e) {
      int
        x = state['x'],
        y = state['y'],
        sizeX = this.state['sizeX'],
        sizeY = this.state['sizeY'];

      String selectedToolBefore = MapEditor.selectedTool;
      int selectedTileBefore = MapEditor.selectedTile;
      MapEditor.selectedTool = "brush";
      MapEditor.selectedTile = -1;
      MapEditor.lastChangeX = -1;
      MapEditor.lastChangeY = -1;
      props['changeTile'](x, y, layer, false, false, false);
      MapEditor.selectedTool = selectedToolBefore;
      MapEditor.selectedTile = selectedTileBefore;
      MapEditor.updateMap();
      MapEditor.outlineSelectedTiles(MapEditor.mapEditorCanvasContext, x, y, 1, 1);
      props['showTileInfo'](x, y, sizeX, sizeY);
    };
  }

  void onInputChange(Event e) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<String> layerNames = ["Ground", "Below", "Player", "Above"];
    int
      x = state['x'],
      y = state['y'],
      sizeX = this.state['sizeX'],
      sizeY = this.state['sizeY'];
    int selectedTileBefore = MapEditor.selectedTile;

    if(sizeX > 1 || sizeY > 1)
      return;

    for(int i=layerNames.length-1; i>=0; i--) {
      if(mapTiles[y][x][i] != null && sizeX == 1 && sizeY == 1) {
        mapTiles[y][x][i].sprite.id = Editor.getTextInputIntValue("#tile_info_layer_${i}_sprite_id", 0);

        // TODO: this should be done more cleanly
        MapEditor.selectedTool = "brush";
        MapEditor.selectedTile = mapTiles[y][x][i].sprite.id;

        MapEditor.lastChangeX = -1;
        MapEditor.lastChangeY = -1;

        props['changeTile'](
          x, y, i,
          Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_solid"),
          Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_layered"),
          Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_encounter")
        );
      }
    }

    MapEditor.updateMap();
    MapEditor.outlineSelectedTiles(MapEditor.mapEditorCanvasContext, x, y, 1, 1);

    props['showTileInfo'](x, y, sizeX, sizeY);

    MapEditor.selectedTool = "select";
    MapEditor.selectedTile = selectedTileBefore;
  }

  render() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;

    List<String> layerNames = ["Ground", "Below", "Player", "Above"];
    int
      x = state['x'],
      y = state['y'],
      sizeX = this.state['sizeX'],
      sizeY = this.state['sizeY'];

    List<JsObject> tileRows = [];

    for(int i=layerNames.length-1; i>=0; i--) {
      bool shouldDoLayer = false;
      int x2 = x, y2 = y;

      // find any non-null tiles in this area on this layer
      if(mapTiles[y][x][i] == null) {
        for(y2=y; y2<y+sizeY && !shouldDoLayer; y2++) {
          for(x2=x; x2<x+sizeX && !shouldDoLayer; x2++) {
            if(mapTiles[y2][x2][i] != null) {
              shouldDoLayer = true;
              x2--;
              y2--;
            }
          }
        }
      } else {
        shouldDoLayer = true;
      }

      if(shouldDoLayer) {
        tileRows.addAll([
          hr({}),
          table({}, tbody({},
            tr({},
              td({'className': 'tile_info_layer_name'}, layerNames[i]),
              td({'className': 'tile_info_delete'},
                button({
                  'id': 'delete_tile_info_layer_${i}',
                  'onClick': deleteLayer(i),
                  'disabled': (sizeX > 1 || sizeY > 1)
                }, "Delete")
              )
            ),
            tr({},
              td({},
                Editor.generateSpritePickerHtml("tile_info_layer_${i}_sprite_id", mapTiles[y2][x2][i].sprite.id)
              ),
              td({'className': 'tile_info_checkboxes'},
                input({
                  'id': 'tile_info_layer_${i}_solid',
                  'type': 'checkbox',
                  'checked': mapTiles[y2][x2][i].solid,
                  'onChange': onInputChange,
                  'disabled': (sizeX != 1 || sizeY != 1)
                }, "Solid"),
                br({}),
                input({
                  'id': 'tile_info_layer_${i}_layered',
                  'type': 'checkbox',
                  'checked': mapTiles[y2][x2][i].layered,
                  'onChange': onInputChange,
                  'disabled': (sizeX != 1 || sizeY != 1)
                }, "Layered"),
                br({}),
                input({
                  'id': 'tile_info_layer_${i}_encounter',
                  'type': 'checkbox',
                  'checked': mapTiles[y2][x2][i] is EncounterTile,
                  'onChange': onInputChange,
                  'disabled': (sizeX != 1 || sizeY != 1)
                }, "Encounter"),
                br({})
              )
            )
          ))
        ]);
      }
    }

    return div({'id': 'tile_info', 'className': MapEditor.selectedTool == "select" ? '' : 'hidden'}, [
      "Tile Info", br({}),
      hr({}),
      "X: ${x}", br({}),
      "Y: ${y}", br({}),
      tileRows
    ]);
  }
}