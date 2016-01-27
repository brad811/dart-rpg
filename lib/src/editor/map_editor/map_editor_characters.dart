library dart_rpg.map_editor_characters;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class MapEditorCharacters extends Component {
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    int i = -1;
    World.characters.forEach((String key, Character character) {
      i += 1;
      
      if(character.map != Main.world.curMap)
        return;
      
      try {
        character.mapX = Editor.getTextInputIntValue("#map_character_${i}_map_x", 0);
        character.mapY = Editor.getTextInputIntValue("#map_character_${i}_map_y", 0);
        character.layer = Editor.getSelectInputIntValue("#map_character_${i}_layer", World.LAYER_BELOW);
        character.direction = Editor.getSelectInputIntValue("#map_character_${i}_direction", Character.DOWN);
        character.solid = Editor.getCheckboxInputBoolValue("#map_character_${i}_solid");
        
        character.x = character.mapX * character.motionAmount;
        character.y = character.mapY * character.motionAmount;
      } catch(e) {
        // could not update this character
        print("Error updating map character: " + e.toString());
      }
    });
    
    update();
  }

  void update() {
    setState({});
    MapEditor.updateMap();
    Editor.debounceExport();
  }

  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "Label"),
        td({}, "X"),
        td({}, "Y"),
        td({}, "Layer"),
        td({}, "Direction"),
        td({}, "Solid"),
        td({})
      )
    ];

    int i = -1;

    World.characters.forEach((String key, Character character) {
      i += 1;
      
      if(character.map != Main.world.curMap)
        return;

      List<String> layers = ["Ground", "Below", "Player", "Above"];
      List<JsObject> layerOptions = [];
      for(int layer=0; layer<layers.length; layer++) {
        layerOptions.add(
          option({'value': layer}, layers[layer])
        );
      }

      List<String> directions = ["Down", "Right", "Up", "Left"];
      List<JsObject> directionOptions = [];
      for(int direction=0; direction<directions.length; direction++) {
        directionOptions.add(
          option({'value': direction}, directions[direction])
        );
      }

      tableRows.add(
        tr({},
          td({}, i),
          td({}, key),
          td({},
            input({
              'id': 'map_character_${i}_map_x',
              'type': 'text',
              'className': 'number',
              'value': character.mapX,
              'onChange': onInputChange
            })
          ),
          td({},
            input({
              'id': 'map_character_${i}_map_y',
              'type': 'text',
              'className': 'number',
              'value': character.mapY,
              'onChange': onInputChange
            })
          ),
          td({},
            select({
              'id': 'map_character_${i}_layer',
              'value': character.layer,
              'onChange': onInputChange
            }, layerOptions)
          ),
          td({},
            select({
              'id': 'map_character_${i}_direction',
              'value': character.direction,
              'onChange': onInputChange
            }, directionOptions)
          ),
          td({},
            input({
              'id': 'map_character_${i}_solid',
              'type': 'checkbox',
              'checked': character.solid,
              'onChange': onInputChange
            })
          )
        )
      );
    });

    return
      div({'id': 'map_characters_tab', 'className': 'tab'},
        div({'id': 'map_characters_container'},
          table({'className': 'editor_table'}, tbody({}, tableRows))
        )
      );
  }
}