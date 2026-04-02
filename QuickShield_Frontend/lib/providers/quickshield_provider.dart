import 'package:flutter/material.dart';

class QuickShieldProvider extends ChangeNotifier {
  String zoneTip = "Safe zone";

  void updateZone(String tip) {
    zoneTip = tip;
    notifyListeners();
  }
}