// ignore_for_file: file_names
import 'dart:async';
import 'Obstacle.dart';

class Player {

  static final int _COLLISION_TOLERANCE = 25;
  static final int INITIAL_JUMP_TIME = 6;

  int _jmpTime = INITIAL_JUMP_TIME;
  bool _isJumping = false;
  int _playerBottom = 42;
  final int _groundBottom = 40;
  final int _playerHeight = 100 - _COLLISION_TOLERANCE;
  final int _playerWidth = 100 - _COLLISION_TOLERANCE;
  final int _playerLeft = 50;

  void jump() {
     if (_isJumping) return;

     Timer.periodic(Duration(milliseconds: _jmpTime), (upTimer) { 
      if (_playerBottom >= 250) {
        upTimer.cancel();
        Timer.periodic(Duration(milliseconds: _jmpTime), (downTimer) {
           if (_playerBottom <= _groundBottom + 5) {
            downTimer.cancel();
            _isJumping = false;
           }

          _playerBottom -= 5;
        });
      }

      _playerBottom += 5;
      _isJumping = true;
     });
  }

  bool isCollision(Obstacle obstacle) {
    //Is there a horizontally collision?
    if (_playerLeft + _playerWidth >= obstacle.left
        && _playerLeft <= obstacle.left + obstacle.width) {
          //Vertical check
          return (_playerBottom + _playerHeight >= obstacle.bottom
        && _playerBottom <= obstacle.bottom + obstacle.height);
    }

    return false; //No collison
  }

  int get jmpTime {
    return _jmpTime;
  }

  void setJmpTime(int newJmpTime) {
    _jmpTime = newJmpTime;
  }

  bool get isJumping {
    return _isJumping;
  }

  int get playerBottom {
    return _playerBottom;
  }

  int get groundBottom {
    return _groundBottom;
  }

  int get playerHeight {
    return _playerHeight;
  }

  int get playerWidth {
    return _playerWidth;
  }

  int get playerLeft {
    return _playerLeft;
  }
}