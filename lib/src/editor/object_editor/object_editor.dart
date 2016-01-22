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
var objectEditorBattlerTypes = registerComponent(() => new ObjectEditorBattlerTypes());

class ObjectEditor extends Component {
  getInitialState() => {
    'selectedTab': 'attacks'
  };

  render() {
    /*
    return
      tr({'id': 'object_editor_tab'}, [
        td({'colSpan': 2}, [
          table({'id': 'object_editor_inner_container'}, [
            tr({}, [
              td({'colSpan': 2}, [
                div({'id': 'object_editor_attacks_tab_header', 'className': 'tab_header'}, "Attacks"),
                div({'id': 'object_editor_types_tab_header', 'className': 'tab_header'}, "Types"),
                div({'id': 'object_editor_battler_types_tab_header', 'className': 'tab_header'}, "Battler Types"),
                div({'id': 'object_editor_characters_tab_header', 'className': 'tab_header'}, "Characters"),
                div({'id': 'object_editor_items_tab_header', 'className': 'tab_header'}, "Items"),
                div({'id': 'object_editor_game_event_chains_tab_header', 'className': 'tab_header'}, "Game Events")
              ])
            ]),
            tr({}, [
              td({'id': 'object_editor_inner_main_area'}, [

                div({'id': 'object_editor_types_tab', 'className': 'tab'}, [
                  button({'id': 'add_type_button'}, "Add new type"),
                  hr({}),
                  div({'id': 'types_container'})
                ]),

                div({'id': 'object_editor_characters_tab', 'className': 'tab'}, [
                  button({'id': 'add_character_button'}, "Add new character"),
                  hr({}),
                  div({'id': 'characters_container'})
                ]),

                div({'id': 'object_editor_items_tab', 'className': 'tab'}, [
                  button({'id': 'add_item_button'}, "Add new item"),
                  hr({}),
                  div({'id': 'items_container'})
                ]),

                div({'id': 'object_editor_game_event_chains_tab', 'className': 'tab'}, [
                  button({'id': 'add_game_event_chain_button'}, "Add new game event chain"),
                  hr({}),
                  div({'id': 'game_event_chains_container'})
                ])

              ]),
              td({'id': 'object_editor_right'}, [
                table({}, [
                  tr({}, [
                    td({}, [

                      table({'id': 'object_editor_types_advanced', 'className': 'hidden'}, [
                        tr({},
                          td({'className': 'tab_headers'},
                            div({'id': 'type_effectiveness_tab_header', 'className': 'tab_header'}, "Effectiveness")
                          )
                        ),
                        tr({},
                          td({'className': 'object_editor_tabs_container'},
                            div({'id': 'type_effectiveness_tab', 'className': 'tab'},
                              div({'id': 'type_effectiveness_container'})
                            )
                          )
                        )
                      ]),

                      table({'id': 'object_editor_characters_advanced', 'className': 'hidden'}, [
                        tr({},
                          td({'className': 'tab_headers'},
                            div({'id': 'character_inventory_tab_header', 'className': 'tab_header'}, "Inventory"),
                            div({'id': 'character_game_event_tab_header', 'className': 'tab_header'}, "Game Event"),
                            div({'id': 'character_battle_tab_header', 'className': 'tab_header'}, "Battle")
                          )
                        ),
                        tr({},
                          td({'className': 'object_editor_tabs_container'},
                            div({'id': 'character_inventory_tab', 'className': 'tab'}, [
                              button({'id': 'add_inventory_item_button'}, "Add new inventory item"),
                              hr({}),
                              div({'id': 'inventory_container'})
                            ]),
                            div({'id': 'character_game_event_tab', 'className': 'tab'},
                              div({'id': 'character_game_event_container'})
                            ),
                            div({'id': 'character_battle_tab', 'className': 'tab'},
                              div({'id': 'battle_container'})
                            )
                          )
                        )
                      ]),

                      table({'id': 'object_editor_items_advanced', 'className': 'hidden'}, [
                        tr({},
                          td({'className': 'tab_headers'},
                            div({'id': 'item_game_event_tab_header', 'className': 'tab_header'}, "Game Event")
                          )
                        ),
                        tr({},
                          td({'className': 'object_editor_tabs_container'},
                            div({'id': 'item_game_event_tab', 'className': 'tab'},
                              div({'id': 'item_game_event_container'})
                            )
                          )
                        )
                      ]),

                      table({'id': 'object_editor_game_event_chains_advanced', 'className': 'hidden'}, [
                        tr({},
                          td({'className': 'tab_headers'},
                            div({'id': 'game_event_chain_game_events_tab_header', 'className': 'tab_header'}, "Game Events")
                          )
                        ),
                        tr({},
                          td({'className': 'object_editor_tabs_container'},
                            div({'id': 'game_event_chain_game_events_tab', 'className': 'tab'},
                              button({'id': 'add_game_event_button'}, "Add new game event"),
                              hr({}),
                              div({'id': 'game_event_chain_game_events_container'})
                            )
                          )
                        )
                      ])

                    ])
                  ]),
                  tr({},
                    td({'className': 'export_json_container'},
                      textarea({'id': 'export_json_object_editor'})
                    )
                  )
                ])
              ])
            ])
          ])
        ])
      ]);
    */

    JsObject selectedTab;

    if(state['selectedTab'] == "attacks") {
      selectedTab = objectEditorAttacks({'update': props['update']});
    } else if(state['selectedTab'] == "battler_types") {
      selectedTab = objectEditorBattlerTypes({'update': props['update']});
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