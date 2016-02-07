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
    'y': 0
  };

  setTile(int x, int y) {
    this.setState({
      'x': x,
      'y': y
    });
  }

  componentDidUpdate(a, v, d) {
    List<String> layerNames = ["Ground", "Below", "Player", "Above"];

    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;

    int x = state['x'];
    int y = state['y'];

    for(int i=layerNames.length-1; i>=0; i--) {
      if(mapTiles[y][x][i] != null) {
        Editor.initSpritePicker("tile_info_layer_${i}_sprite_id", mapTiles[y][x][i].sprite.id, 1, 1, onInputChange);
      }
    }
  }

  Function deleteLayer(int layer) {
    return (MouseEvent e) {
      int x = state['x'];
      int y = state['y'];

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
      props['showTileInfo'](x, y);
    };
  }

  void onInputChange(Event e) {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;
    List<String> layerNames = ["Ground", "Below", "Player", "Above"];
    int x = state['x'];
    int y = state['y'];
    int selectedTileBefore = MapEditor.selectedTile;

    for(int i=layerNames.length-1; i>=0; i--) {
      if(mapTiles[y][x][i] != null) {
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

    props['showTileInfo'](x, y);

    MapEditor.selectedTool = "select";
    MapEditor.selectedTile = selectedTileBefore;
  }

  render() {
    List<List<List<Tile>>> mapTiles = Main.world.maps[Main.world.curMap].tiles;

    List<String> layerNames = ["Ground", "Below", "Player", "Above"];
    int x = this.state['x'];
    int y = this.state['y'];

    List<JsObject> tileRows = [];

    for(int i=layerNames.length-1; i>=0; i--) {
      if(mapTiles[y][x][i] != null) {
        tileRows.addAll([
          hr({}),
          table({}, tbody({},
            tr({},
              td({'className': 'tile_info_layer_name'}, layerNames[i]),
              td({'className': 'tile_info_delete'},
                button({'id': 'delete_tile_info_layer_${i}', 'onClick': deleteLayer(i)}, "Delete")
              )
            ),
            tr({},
              td({},
                Editor.generateSpritePickerHtml("tile_info_layer_${i}_sprite_id", mapTiles[y][x][i].sprite.id)
              ),
              td({'className': 'tile_info_checkboxes'},
                input({
                  'id': 'tile_info_layer_${i}_solid',
                  'type': 'checkbox',
                  'value': mapTiles[y][x][i].solid,
                  'onChange': onInputChange
                }, "Solid"),
                br({}),
                input({
                  'id': 'tile_info_layer_${i}_layered',
                  'type': 'checkbox',
                  'value': mapTiles[y][x][i].layered,
                  'onChange': onInputChange
                }, "Layered"),
                br({}),
                input({
                  'id': 'tile_info_layer_${i}_encounter',
                  'type': 'checkbox',
                  'value': mapTiles[y][x][i] is EncounterTile,
                  'onChange': onInputChange
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