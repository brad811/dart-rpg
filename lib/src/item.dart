library dart_rpg.item;

import 'package:dart_rpg/src/battler.dart';

abstract class Item {
  final String name = "Item";
  int price = 100;
  
  void use(Battler target);
}