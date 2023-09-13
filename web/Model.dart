import 'game/ObstacleManager.dart';
import 'RestRequest.dart';
import 'game/Obstacle.dart';
import 'game/Player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Model {
  bool _bIsUserLoggedIn = false;
  bool _bIsGameRunning = false;
  bool _bIsGameOver = false;
  late Player _player; //Model class for player
  String _authToken = "";
  String _username = "";
  late ObstacleManager _obstacleManager;
  int _currLevel = 0;
  bool _isAuthError = false;
  late DateTime _scoreStartTime;
  int _scoreTime = 0;

  Future<http.Response?> handleLoginRegister(String username, String password, bool isLogin) async {
    final Map<String, String> data = {
      'action': isLogin ? 'login' : 'register',
      'username': username,
      'password': password,
    };

    final response = await RESTRequest('user').make(HttpMethod.POST, data);
    if (response == null) {
      return response;
    }

    //Save returned auth_token for later use
    if (isLogin && response.statusCode == 200) {
      _authToken = json.decode(response.body)['auth_token'];
      _bIsUserLoggedIn = true;
      _username = username;
    }

    return response;
  }

  void logoutUser() {
    _bIsUserLoggedIn = false;
    _username = '';
    _authToken = '';
  }

  int get score {
    return _scoreTime;
  }

  void _checkAuthResult(http.Response? response) {
    if (response == null) return;
    final data = json.decode(response.body);

    if (data['session_expired'] == 'true') {
      _authToken = data['auth_token'];
    }
  }

  Future<http.Response?> deleteHighscore() async {
    final response = await RESTRequest('highscore').make(HttpMethod.DELETE, {'auth_token': _authToken, 'level': '$_currLevel'});
    _checkAuthResult(response);
    return response;   
  }

  Future<http.Response?> deleteAccount() async {
    final response = await RESTRequest('user').make(HttpMethod.DELETE, {'auth_token': _authToken });
    if (response != null && response.statusCode == 200) logoutUser();
    return response; 
  }

  Future<http.Response?> getHighscores(int level) async {
    _currLevel = level;
    final response = await RESTRequest('highscore?level=$level&auth_token=$_authToken')
                    .make(HttpMethod.GET, <String, String>{});
    if (response != null) _isAuthError = response.statusCode == 401;
    _checkAuthResult(response);
    return response;
  }

  Future<http.Response?> updateHighscore() async {
    final response = await RESTRequest('highscore').make(HttpMethod.PATCH, {'auth_token': _authToken, 'level': '$_currLevel', 'score': '$_scoreTime'});
    _checkAuthResult(response);
    return response;
  }

  int get currLevel {
    return _currLevel;
  }

  // ignore: unnecessary_getters_setters
  bool get isUserLoggedIn {
    return _bIsUserLoggedIn;
  }

  String get username {
    return _username;
  }

  bool get isAuthError {
    return _isAuthError;
  }

  bool get isGameRunning {
    return _bIsGameRunning;
  }

  Player get player {
    return _player;
  }

  bool get isGameOver {
    return _bIsGameOver;
  }

  set isUserLoggedIn(bool value) {
    _bIsUserLoggedIn = value;
  }

  void updateGame() {
    //Obstacle
    _obstacleManager.update();

    //Check collision
    _bIsGameOver = _obstacleManager.isCollisionWithPlayer();

    if (_bIsGameOver) {
      _scoreTime = DateTime.now().difference(_scoreStartTime).inSeconds;
    }
  }

  List<Obstacle> get obstacles {
    return _obstacleManager.obstacles;
  }

  void startGame(int level) {
    if (_bIsGameRunning) return;
    _currLevel = level;
    _player = Player();
    _obstacleManager = ObstacleManager(_currLevel, 42, 
          100, 100, 50, _player);
    _obstacleManager.spawn();
    _bIsGameOver = false;
    _bIsGameRunning = true;
    _scoreStartTime = DateTime.now(); //Save current time for highscore
  }

  void stopGame() {
    _bIsGameRunning = false;
  }
}