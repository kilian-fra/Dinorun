class Obstacle {
  final int _bottom;
  int _left;
  int _height;
  final int _width;
  final String _type = "";

  static final int DEFAULT_WIDTH = 15;

  Obstacle(int bottom, int width, int height, int left) :
    _bottom = bottom,
    _left = left,
    _height = height,
    _width = width == 0 ? DEFAULT_WIDTH : width; //Test

  void move(int dxLeft) {
      _left += dxLeft;
  }

  void setHeight(int newHeight) {
    _height = newHeight;
  }

  void setLeft(int newLeft) {
    _left = newLeft;
  }

  bool get isOutOfRange {
    return _left < 0;
  }

  //Getters
  int get bottom {
    return _bottom;
  }

  String get type {
    return _type;
  }

  int get left {
    return _left;
  }

  int get height {
    return _height;
  }

  int get width {
    return _width;
  }
}