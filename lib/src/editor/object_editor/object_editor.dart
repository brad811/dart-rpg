library dart_rpg.object_editor;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/editor/object_editor/object_editor_attacks.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_battler_types.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_characters.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_game_events.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_items.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_types.dart';

import 'package:react/react.dart';

var objectEditorAttacks = registerComponent(() => new ObjectEditorAttacks());
var objectEditorTypes = registerComponent(() => new ObjectEditorTypes());
var objectEditorBattlerTypes = registerComponent(() => new ObjectEditorBattlerTypes());
var objectEditorCharacters = registerComponent(() => new ObjectEditorCharacters());
var objectEditorItems = registerComponent(() => new ObjectEditorItems());
var objectEditorGameEvents = registerComponent(() => new ObjectEditorGameEvents());

class ObjectEditor extends Component {
  getInitialState() => {
    'selectedTab': 'attacks'
  };

  render() {
    JsObject selectedTab;

    if(state['selectedTab'] == "attacks") {
      selectedTab = objectEditorAttacks({});
    } else if(state['selectedTab'] == "types") {
      selectedTab = objectEditorTypes({});
    } else if(state['selectedTab'] == "battler_types") {
      selectedTab = objectEditorBattlerTypes({});
    } else if(state['selectedTab'] == "characters") {
      selectedTab = objectEditorCharacters({});
    } else if(state['selectedTab'] == "items") {
      selectedTab = objectEditorItems({});
    } else if(state['selectedTab'] == "game_event_chains") {
      selectedTab = objectEditorGameEvents({});
    }

    List<JsObject> tabHeaders = [];

    List<String> tabNames = ["attacks", "types", "battler_types", "characters", "items", "game_event_chains"];
    List<String> prettyTabNames = ["Attacks", "Types", "Battler Types", "Characters", "Items", "Game Events"];
    for(int i=0; i<tabNames.length; i++) {
      tabHeaders.add(
        div(
          {
            'id': 'object_editor_${tabNames[i]}_tab_header',
            'className': 'tab_header ' + (state['selectedTab'] == tabNames[i] ? 'selected' : ''),
            'onClick': (MouseEvent e) { setState({'selectedTab': tabNames[i]}); }
          },
          prettyTabNames[i]
        )
      );
    }

    return
      tr({'id': 'object_editor_tab'}, [
        td({'colSpan': 2}, [
          div({'id': 'object_editor_inner_container'}, [
            div({'id': 'object_editor_tab_headers_container'}, tabHeaders),
            br({'className': 'breaker hidden'}),
            div({'id': 'object_editor_inner_main_area'}, selectedTab),
            textarea({'id': 'export_json_object_editor'})
          ])
        ])
      ]);
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    ObjectEditorAttacks.export(exportJson);
    ObjectEditorTypes.export(exportJson);
    ObjectEditorBattlerTypes.export(exportJson);
    ObjectEditorCharacters.export(exportJson);
    ObjectEditorItems.export(exportJson);
    ObjectEditorGameEvents.export(exportJson);
  }
}