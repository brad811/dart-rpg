library dart_rpg.undo_redo;

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class UndoRedo extends Component {
  @override
  render() {
    return
      span({'id': 'undo_redo_container'},
        button({
          'onClick': (_) { this.props["undo"](); },
          'disabled': Editor.undoPosition <= 1
        }, i({'className': 'fa fa-undo'}), " Undo"),
        button({
          'onClick': (_) { this.props["redo"](); },
          'disabled': Editor.undoPosition == Editor.undoList.length
        }, i({'className': 'fa fa-undo fa-flip-horizontal'}), " Redo")
      );
  }
}