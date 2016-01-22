library dart_rpg.map_editor_battlers;

import 'dart:html';
import "dart:js";

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MapEditorBattlers extends Component {
  Map getInitialState() {
    return {
      'battlerChances': Main.world.maps[Main.world.curMap].battlerChances
    };
  }

  void updateState() {
    this.setState({
        'battlerChances': Main.world.maps[Main.world.curMap].battlerChances
    });
  }

  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    Main.world.maps[Main.world.curMap].battlerChances = new List<BattlerChance>();
    for(int i=0; querySelector('#map_battler_${i}_type') != null; i++) {
      try {
        String battlerTypeName = Editor.getSelectInputStringValue('#map_battler_${i}_type');
        int battlerTypeLevel = Editor.getTextInputIntValue('#map_battler_${i}_level', 1);
        double battlerTypeChance = Editor.getTextInputDoubleValue('#map_battler_${i}_chance', 1.0);
        
        Battler battler = new Battler(
          null,
          World.battlerTypes[battlerTypeName],
          battlerTypeLevel,
          World.battlerTypes[battlerTypeName].getAttacksForLevel(battlerTypeLevel)
        );
        
        BattlerChance battlerChance = new BattlerChance(battler, battlerTypeChance);
        Main.world.maps[Main.world.curMap].battlerChances.add(battlerChance);
      } catch(e) {
        // could not update this map battler
        print("Error updating map battler: " + e.toString());
      }
    }
    
    //Editor.updateAndRetainValue(e);
    updateState();
  }

  void addNewBattler(MouseEvent e) {
    Main.world.maps[Main.world.curMap].battlerChances.add(
      new BattlerChance(
        new Battler( World.battlerTypes.keys.first, World.battlerTypes.values.first, 1, [] ),
        1.0
      )
    );
    
    updateState();
    //Editor.update();
  }

  void deleteBattler(int battlerNum) {
    Main.world.maps[Main.world.curMap].battlerChances.removeAt(battlerNum);
    updateState();
    //Editor.update();
  }

  void render() {
    double totalChance = 0.0;
    for(int i=0; i<this.state['battlerChances'].length; i++) {
      totalChance += this.state['battlerChances'][i].chance;
    }

    List<JsObject> battlerTableRows = [];

    battlerTableRows.add(
      tr({}, [
        td({}, "#"),
        td({}, "Battler Type"),
        td({}, "Level"),
        td({}, "Chance"),
        td({}, "")
      ])
    );

    for(int i=0; i<this.state['battlerChances'].length; i++) {
      int percentChance = 0;
      if(totalChance != 0) {
        percentChance = (this.state['battlerChances'][i].chance / totalChance * 100).round();
      }

      List<JsObject> battlerTypeOptions = [];
      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        battlerTypeOptions.add(
          option({'defaultValue': battlerType.name}, battlerType.name)
        );
      });

      battlerTableRows.add(
        tr({}, [
          td({}, i),
          td({}, [
            select(
              {
                'id': 'map_battler_${i}_type',
                'onChange': onInputChange,
                'defaultValue': this.state['battlerChances'][i].battler.name
              },
              battlerTypeOptions
            )
          ]),
          td({}, [
            input({
              'id': 'map_battler_${i}_level',
              'type': 'text',
              'className': 'number',
              'onChange': onInputChange,
              'defaultValue': this.state['battlerChances'][i].battler.level
            })
          ]),
          td({}, [
            input({
              'id': 'map_battler_${i}_chance',
              'type': 'text',
              'className': 'number decimal',
              'onChange': onInputChange,
              'defaultValue': this.state['battlerChances'][i].chance
            }),
            span({'id': 'map_battler_${i}_percent_chance'}, " ${percentChance}%")
          ]),
          td({}, [
            button(
              {
                'id': 'delete_map_battler_${i}',
                'onClick': (MouseEvent e) { deleteBattler(i); }
              },
              'Delete'
            )
          ])
        ])
      );
    }

    return
      div({'id': 'battlers_tab', 'className': 'tab'}, [
        div({'id': 'battlers_container'}, [
          button({'id': 'add_battler_button', 'onClick': addNewBattler}, "Add new battler"),
          hr({}),
          div({'id': 'battlers_container'},
            table(
              {'className': 'editor_table'},
              tbody({}, battlerTableRows)
            )
          )
        ])
      ]);
  }

  static void export(Map jsonMap, String key) {
    jsonMap["battlers"] = [];
    for(BattlerChance battlerChance in Main.world.maps[key].battlerChances) {
      jsonMap["battlers"].add({
        "name": battlerChance.battler.name,
        "type": battlerChance.battler.name,
        "level": battlerChance.battler.level,
        "chance": battlerChance.chance
      });
    }
  }
}
