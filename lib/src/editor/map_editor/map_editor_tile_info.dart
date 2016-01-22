library dart_rpg.map_editor_tile_info;

import 'dart:js';

import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/tile.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MapEditorTileInfo extends Component {
  Map<String, List<EventTile>> events = {};

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
          table({}, tbody({}, [
            tr({}, [
              td({'className': 'tile_info_layer_name'}, layerNames[i]),
              td({'className': 'tile_info_delete'},
                button({'id': 'delete_tile_info_layer_${i}'}, "Delete")
              )
            ]),
            tr({}, [
              td({},
                Editor.generateSpritePickerHtml("tile_info_layer_${i}_sprite_id", mapTiles[y][x][i].sprite.id)
              ),
              td({'className': 'tile_info_checkboxes'}, [
                input({'id': 'tile_info_layer_${i}_solid', 'type': 'checkbox', 'value': mapTiles[y][x][i].solid}, "Solid"),
                br({}),
                input({'id': 'tile_info_layer_${i}_layered', 'type': 'checkbox', 'value': mapTiles[y][x][i].layered}, "Layered"),
                br({}),
                input({'id': 'tile_info_layer_${i}_encounter', 'type': 'checkbox', 'value': mapTiles[y][x][i] is EncounterTile}, "Encounter"),
                br({})
              ])
            ])
          ]))
        ]);
      }
    }

    return div({'id': 'tile_info'}, [
      "Tile Info", br({}),
      hr({}),
      "X: ${x}", br({}),
      "Y: ${y}", br({}),
      tileRows
    ]);
  }
}