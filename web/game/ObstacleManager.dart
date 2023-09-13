import 'dart:math';
import 'Obstacle.dart';
import 'Player.dart';
import 'util.dart';

class ObstacleManager {
  final List<Obstacle> _obstacles;
  final int _level;
  //final int _playerBottom;
  final int _playerHeight;
  final int _playerWidth;
  final int _groundBottom;
  int _lastUpdate = DateTime.now().millisecondsSinceEpoch;
  final DateTime _startTime = DateTime.now();
  int _nextUpdate = 10;
  int _dxLeft = -5;
  final Player _player;

  ObstacleManager(int level, int playerBottom, int playerHeight, int playerWidth, int groundBottom, Player player) :
    _obstacles = [],
    _level = level,
    //_playerBottom = playerBottom,
    _playerHeight = playerHeight,
    _playerWidth = playerWidth,
    _groundBottom = groundBottom,
    _player = player;

  List<Obstacle> get obstacles {
    return _obstacles;
  }

  bool isCollisionWithPlayer() {
    for (final o in _obstacles) {
      if (_player.isCollision(o)) {
        return true;
      }
    }

    return false;
  }

  int _genHeight() {
    final max = (_playerHeight / 2) as int;
    final min = (_playerHeight / 4) as int;
    return min + Random().nextInt(max - min + 1);
  }

  int _genLeftOffset() {
    final min = _playerWidth * 2;
    final max = _playerWidth * 3;
    return min + Random().nextInt(max - min + 1);
  }

  void _setNextUpdate() {
    final elapsedSec = DateTime.now().difference(_startTime).inSeconds;
    if (elapsedSec > 90) return;

    switch (_level) {
      case 1: {
        if (elapsedSec >= 30 && elapsedSec < 60) {
          _nextUpdate = 9;
        } else if (elapsedSec >= 60 && elapsedSec < 90) {
          _nextUpdate = 8;
          _player.setJmpTime(5);
        } else if (elapsedSec > 90) {
          _nextUpdate = 7;
          _player.setJmpTime(4);
        }

        break;
      }

      case 2: {
        if (elapsedSec >= 20 && elapsedSec < 40) {
          _nextUpdate = 9;
        } else if (elapsedSec >= 40 && elapsedSec < 60) {
          _nextUpdate = 8;
          _player.setJmpTime(5);
        } else if (elapsedSec > 60) {
          _nextUpdate = 7;
          _player.setJmpTime(4);
        }

        break;
      }

      case 3: {
        if (elapsedSec >= 15 && elapsedSec < 30) {
          _nextUpdate = 9;
        } else if (elapsedSec >= 30 && elapsedSec < 45) {
          _nextUpdate = 8;
          _player.setJmpTime(5);
        } else if (elapsedSec > 45) {
          _nextUpdate = 7;
          _player.setJmpTime(4);
        }

        break;
      }

      default: break;
    }
  }

  void update() {
    final currTime = DateTime.now().millisecondsSinceEpoch;
    if (currTime - _lastUpdate < _nextUpdate) return;
    _lastUpdate = currTime;

    final obstacleLen = obstacles.length;
    final gWidth = getCurrentGroundWidthPx();

    for (int i = 0; i < obstacleLen; i++) {
      final currObstacle = obstacles.elementAt(i);

      if (currObstacle.isOutOfRange) {

        if (i == obstacleLen - 1) {
          currObstacle.setLeft(gWidth);
        } else {
          final nextObstacle = obstacles.elementAt(i + 1);
          final randomLeftOffset = _genLeftOffset();
          if (gWidth - randomLeftOffset < nextObstacle.left) continue;
          currObstacle.setLeft(gWidth);
        }

        currObstacle.setHeight(_genHeight());

        //Only update if last element is out of range, so player has time to react to speed increase
        if (i == 0) _setNextUpdate();

      } else {
        currObstacle.move(_dxLeft);
      }
    }
  }

  void spawn() {
    //Test
    int obstaclesToSpawn = 0;
    switch (_level) {
      case 1: {
        obstaclesToSpawn = 3;
        break;
      }
      case 2: {
        obstaclesToSpawn = 4;
        break;
      }

      case 3: {
        obstaclesToSpawn = 5;
        break;
      }

      default: obstaclesToSpawn = 1;
    }

    int groundWidth = getCurrentGroundWidthPx();

    for (int i = 0; i < obstaclesToSpawn; i++) {
      final randomeLeftOffset = i == 0 ? 0 : _genLeftOffset();
      _obstacles.add(Obstacle(_groundBottom, 0, _genHeight(), groundWidth - randomeLeftOffset));
      groundWidth -= (randomeLeftOffset + Obstacle.DEFAULT_WIDTH);
    }
  }
}