import 'dart:html';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react_client.dart' as reactClient;
import 'package:react/react.dart';
import 'package:react/react_dom.dart' as reactDom;

var editor = registerComponent(() => new Editor());

void main() {
  reactClient.setClientConfiguration();

  reactDom.render(editor({}), querySelector('#editor_container'));
}