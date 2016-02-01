import 'dart:html';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';
import 'package:react/react_client.dart' as reactClient;

var editor = registerComponent(() => new Editor());

void main() {
  reactClient.setClientConfiguration();

  render(editor({}), querySelector('#editor_container'));
}