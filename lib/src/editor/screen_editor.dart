library dart_rpg.screen_editor;

import 'dart:html';

import 'package:dart_rpg/src/main.dart';

import 'package:react/react.dart';

class ScreenEditor extends Component {
  static CanvasElement screenCanvas;
  static CanvasRenderingContext2D ctx;

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
    return tr({'id': 'screen_editor_tab'}, [
      td({'id': 'screen_editor_left'},
        canvas({'id': 'screen_editor_canvas'})
      ),
      td({'id': 'screen_editor_right'},
        div({'className': 'tab'})
      )
    ]);
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    // TODO
  }
}