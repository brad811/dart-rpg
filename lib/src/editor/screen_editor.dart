library dart_rpg.screen_editor;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/editor/screen_editor/screen_editor_battle.dart';
import 'package:dart_rpg/src/editor/screen_editor/screen_editor_title.dart';

import 'package:react/react.dart';

var screenEditorTitle = registerComponent(() => new ScreenEditorTitle());
var screenEditorBattle = registerComponent(() => new ScreenEditorBattle());

class ScreenEditor extends Component {
  static CanvasElement screenCanvas;
  static CanvasRenderingContext2D ctx;

  @override
  getInitialState() => {
    'selectedTab': 'title'
  };

  @override
  componentDidMount() {
    screenCanvas = querySelector("#screen_editor_canvas");
    ctx = screenCanvas.getContext("2d");

    setUpCanvas();

    // TODO: do this with CSS instead
    Function resizeFunction = (Event e) {
      querySelector('#screen_editor_left').style.width = "${window.innerWidth - 662}px";
      querySelector('#screen_editor_left').style.height = "${window.innerHeight - 60}px";
    };
    
    window.onResize.listen(resizeFunction);
    resizeFunction(null);
  }

  @override
  componentDidUpdate(Map prevProps, Map prevState) {
    setUpCanvas();
  }

  setUpCanvas() {
    Main.fixImageSmoothing(screenCanvas, Main.canvasWidth, Main.canvasHeight);

    ctx.fillStyle = "#ff00ff";
    ctx.fillRect(0, 0, Main.canvasWidth, Main.canvasHeight);
  }
  
  void update() {
    setState({});
  }

  @override
  render() {
    JsObject selectedTab;

    if(state['selectedTab'] == "title") {
      selectedTab = screenEditorTitle({});
    } else if(state['selectedTab'] == "battle") {
      selectedTab = screenEditorBattle({});
    }

    List<JsObject> tabHeaders = [];

    List<String> tabNames = ["title", "battle"];
    List<String> prettyTabNames = ["Title", "Battle"];
    for(int i=0; i<tabNames.length; i++) {
      tabHeaders.add(
        div(
          {
            'id': 'screen_editor_${tabNames[i]}_tab_header',
            'className': 'tab_header ' + (state['selectedTab'] == tabNames[i] ? 'selected' : ''),
            'onClick': (MouseEvent e) { setState({'selectedTab': tabNames[i]}); }
          },
          prettyTabNames[i]
        )
      );
    }

    return
      tr({'id': 'screen_editor_tab'},
        td({'id': 'screen_editor_left'},
          canvas({'id': 'screen_editor_canvas'})
        ),
        td({'id': 'screen_editor_right'},
          table({'id': 'right_half_container'}, tbody({},
            tr({},
              td({'className': 'tab_headers'},
                div({
                  'className': 'tab_header ' + (state['selectedTab'] == "title" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'title'}); }
                  }, "Title"),
                div({
                  'className': 'tab_header ' + (state['selectedTab'] == "battle" ? 'selected' : ''),
                  'onClick': (MouseEvent e) { setState({'selectedTab': 'battle'}); }
                }, "Battle")
              )
            ),
            tr({},
              td({'id': 'editor_tabs_container'},
                selectedTab
              )
            )
          ))
        )
      );
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    // TODO
  }
}