library dart_rpg.game_screen;

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/tile.dart';

class GameScreen extends Interactable {
  List<List<Tile>> backgroundTiles = [];
  
  void render() {
    // background
    for(int y=0; y<backgroundTiles.length; y++) {
      for(int x=0; x<backgroundTiles[0].length; x++) {
        backgroundTiles[y][x].sprite.renderStatic();
        backgroundTiles[y][x].sprite.renderStatic();
      }
    }
  }
}