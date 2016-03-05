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

      for(int y2=y; y2<y+sizeY; y2++) {
        for(int x2=x; x2<x+sizeX; x2++) {
          props['changeTile'](x2, y2, layer, false, false, false);
        }
      }

      MapEditor.selectedTool = selectedToolBefore;
      MapEditor.selectedTile = selectedTileBefore;
      
      MapEditor.outlineSelectedTiles(MapEditor.mapEditorCanvasContext, x, y, sizeX, sizeY);
      props['showTileInfo'](x, y, sizeX, sizeY);
    };
  }

  Function copyLayer(int layer) {
    return (MouseEvent e) {
      List<List<List<Tile>>> tiles = Main.world.maps[Main.world.curMap].tiles;

      MapEditor.stampTiles = [[]];

      for(int y=0; y<this.state["sizeY"]; y++) {
        MapEditor.stampTiles[0].add([]);
        for(int x=0; x<this.state["sizeX"]; x++) {
          if(
            tiles[this.state["y"] + y] != null &&
            tiles[this.state["y"] + y][this.state["x"] + x] != null &&
            tiles[this.state["y"] + y][this.state["x"] + x][layer] != null &&
            tiles[this.state["y"] + y][this.state["x"] + x][layer].sprite != null
          ) {
            MapEditor.stampTiles[0][y].add(
              tiles[this.state["y"] + y][this.state["x"] + x][layer].sprite.id
            );
          } else {
            MapEditor.stampTiles[0][y].add(null);
          }
        }
      }

      MapEditor.selectedLayer = layer;
      MapEditor.selectTool("stamp");
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

    for(int i=layerNames.length-1; i>=0; i--) {
      for(int y2=y; y2<y+sizeY; y2++) {
        for(int x2=x; x2<x+sizeX; x2++) {
          if(mapTiles[y2][x2][i] != null) {
            if(sizeX == 1 && sizeY == 1) {
              mapTiles[y2][x2][i].sprite.id = Editor.getTextInputIntValue("#tile_info_layer_${i}_sprite_id", 0);
            }

            // TODO: this should be done more cleanly
            MapEditor.selectedTool = "brush";
            MapEditor.selectedTile = mapTiles[y2][x2][i].sprite.id;

            MapEditor.lastChangeX = -1;
            MapEditor.lastChangeY = -1;

            bool solid = (
              sizeX == 1 && sizeY == 1
                ? Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_solid")
                : (
                  (e.target as Element).id == "tile_info_layer_${i}_solid"
                    ? Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_solid")
                    : mapTiles[y2][x2][i].solid
                )
            );

            bool layered = (
              sizeX == 1 && sizeY == 1
                ? Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_layered")
                : (
                  (e.target as Element).id == "tile_info_layer_${i}_layered"
                    ? Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_layered")
                    : mapTiles[y2][x2][i].layered
                )
            );

            bool encounter = (
              sizeX == 1 && sizeY == 1
                ? Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_encounter")
                : (
                  (e.target as Element).id == "tile_info_layer_${i}_encounter"
                    ? Editor.getCheckboxInputBoolValue("#tile_info_layer_${i}_encounter")
                    : mapTiles[y2][x2][i] is EncounterTile
                )
            );

            props['changeTile'](x2, y2, i, solid, layered, encounter);
          }
        }
      }
    }

    MapEditor.outlineSelectedTiles(MapEditor.mapEditorCanvasContext, x, y, sizeX, sizeY);

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
      bool
        shouldDoLayer = false,
        allSolid = true,
        allLayered = true,
        allEncounter = true;

      // find any non-null tiles in this area on this layer
      for(int y2=y; y2<y+sizeY; y2++) {
        for(int x2=x; x2<x+sizeX; x2++) {
          if(mapTiles[y2][x2][i] != null) {
            // there is at least one non-null tile here
            shouldDoLayer = true;

            if(!mapTiles[y2][x2][i].solid)
              allSolid = false;

            if(!mapTiles[y2][x2][i].layered)
              allLayered = false;

            if(!(mapTiles[y2][x2][i] is EncounterTile))
              allEncounter = false;
          }
        }
      }

      if(shouldDoLayer) {
        tileRows.addAll([
          hr({}),
          table({}, tbody({},
            tr({},
              td({'className': 'tile_info_layer_name'}, layerNames[i]),
              td({'className': 'tile_info_delete'},
                button({
                  'onClick': copyLayer(i)
                }, span({'className': 'fa fa-files-o'}), " Copy"),
                " ",
                button({
                  'onClick': deleteLayer(i)
                }, span({'className': 'fa fa-trash'}), " Delete")
              )
            ),
            tr({},
              td({},
                Editor.generateSpritePickerHtml("tile_info_layer_${i}_sprite_id", sizeX == 1 && sizeY == 1 ? mapTiles[y][x][i].sprite.id : 0)
              ),
              td({'className': 'tile_info_checkboxes'},
                input({
                  'id': 'tile_info_layer_${i}_solid',
                  'type': 'checkbox',
                  'checked': allSolid,
                  'onChange': onInputChange
                }, "Solid"),
                br({}),
                input({
                  'id': 'tile_info_layer_${i}_layered',
                  'type': 'checkbox',
                  'checked': allLayered,
                  'onChange': onInputChange
                }, "Layered"),
                br({}),
                input({
                  'id': 'tile_info_layer_${i}_encounter',
                  'type': 'checkbox',
                  'checked': allEncounter,
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