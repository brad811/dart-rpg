library dart_rpg.object_editor_types;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class ObjectEditorTypes extends Component {
  bool shouldScrollIntoView = false;

  getInitialState() => {
    'selected': -1
  };
  
  void addNewType(MouseEvent e) {
    String name = Editor.getUniqueName("New Type", World.types);
    World.types[name] = new GameType(name);

    shouldScrollIntoView = true;
    this.setState({
      'selected': World.types.keys.length - 1
    });
  }
  
  void update() {
    setState({});
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    if(state['selected'] > World.types.keys.length - 1) {
      setState({
        'selected': World.types.keys.length - 1
      });
    }

    if(shouldScrollIntoView) {
      shouldScrollIntoView = false;
      querySelector('#type_row_${state['selected']}').scrollIntoView();
    }
  }

  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "Name"),
        td({})
      )
    ];

    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);

      tableRows.add(
        tr({
          'id': 'type_row_${i}',
          'className': state['selected'] == i ? 'selected' : '',
          'onClick': (MouseEvent e) { setState({'selected': i}); },
          'onFocus': (MouseEvent e) { setState({'selected': i}); }
        }, [
          td({}, i),
          td({},
            input({'id': 'type_${i}_name', 'type': 'text', 'value': gameType.name, 'onChange': onInputChange})
          ),
          td({},
            button({
              'id': 'delete_type_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(World.types, gameType.name, "type", update, atLeastOneRequired: true)
            }, "Delete")
          )
        ])
      );
    }

    return
      div({'id': 'object_editor_types_container', 'className': 'object_editor_tab_container'},

        table({
          'id': 'object_editor_types_advanced',
          'className': 'object_editor_advanced_tab'}, tbody({},
          tr({},
            td({'className': 'tab_headers'},
              div({
                'id': 'type_effectiveness_tab_header',
                'className': 'tab_header selected'
              }, "Effectiveness")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'id': 'type_effectiveness_tab', 'className': 'tab'},
                div({'id': 'type_effectiveness_container'}, getEffectivenessTab())
              )
            )
          )
        )),

        div({'id': 'object_editor_types_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'}, [
            button({'id': 'add_type_button', 'onClick': addNewType}, "Add new type"),
            hr({}),
            div({'id': 'types_container'}, [
              table({'className': 'editor_table'}, tbody({}, tableRows))
            ])
          ])
        )

      );
  }

  JsObject getEffectivenessTab() {
    List<JsObject> typeContainers = [];

    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);

      List<JsObject> tableRows = [
        tr({}, [
          td({}, "Num"),
          td({}, "Defending Type"),
          td({}, "Effectiveness")
        ])
      ];

      for(int j=0; j<World.types.keys.length; j++) {
        GameType defendingGameType = World.types.values.elementAt(j);

        tableRows.add(
          tr({}, [
            td({}, j),
            td({}, defendingGameType.name),
            td({},
              input({
                'id': 'type_${i}_effectiveness_${j}',
                'type': 'text',
                'className': 'number decimal',
                'value': gameType.getEffectiveness(defendingGameType.name).toString(),
                'onChange': onInputChange
              })
            )
          ])
        );
      }

      typeContainers.add(
        div({'id': 'type_${i}_effectiveness_container', 'className': state['selected'] == i ? '' : 'hidden'},
          table({}, tbody({}, tableRows))
        )
      );
    }

    return div({}, typeContainers);
  }

  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.types);

    String oldName = World.types.keys.elementAt(state['selected']);
    String name = Editor.getTextInputStringValue('#type_${state['selected']}_name');

    Map<String, GameType> newTypes = {};

    World.types.forEach((String key, GameType type) {
      try {
        if(key != oldName) {
          newTypes[key] = type;
        } else {
          String name = Editor.getTextInputStringValue("#type_${state['selected']}_name");
          newTypes[name] = new GameType(name);
        }
      } catch(e) {
        // could not update this type
        print("Error updating type: " + e.toString());
      }
    });

    World.types = newTypes;

    for(int j=0; j<World.types.keys.length; j++) {
      try {
        World.types[name].setEffectiveness(
          World.types.keys.elementAt(j),
          Editor.getTextInputDoubleValue("#type_${state['selected']}_effectiveness_${j}", 1.0)
        );
      } catch(e) {
        // could not update this type
        print("Error updating type effectiveness: " + e.toString());
      }
    }
    
    update();

    Editor.debounceExport();
  }

  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> typesJson = {};
    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);
      
      Map<String, Object> typeJson = {};
      typeJson["name"] = gameType.name;
      
      Map<String, double> typeEffectivenessJson = {};
      
      // iterate through effectiveness
      for(int j=0; j<World.types.length; j++) {
        typeEffectivenessJson[World.types.keys.elementAt(j)] = gameType.getEffectiveness(World.types.keys.elementAt(j));
      }
      
      typeJson["effectiveness"] = typeEffectivenessJson;
      
      typesJson[gameType.name] = typeJson;
    }
    
    exportJson["types"] = typesJson;
  }
}

