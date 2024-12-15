import 'package:flutter/material.dart';

class CustomTextShadow {
  static const List<Shadow> shadows = [
    Shadow( // Bottom-left shadow
      offset: Offset(-1.5, -1.5),
      color: Colors.black,
    ),
    Shadow( // Bottom-right shadow
      offset: Offset(1.5, -1.5),
      color: Colors.black,
    ),
    Shadow( // Top-left shadow
      offset: Offset(-1.5, 1.5),
      color: Colors.black,
    ),
    Shadow( // Top-right shadow
      offset: Offset(1.5, 1.5),
      color: Colors.black,
    ),
  ];
}