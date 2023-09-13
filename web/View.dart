import 'dart:convert';
import 'dart:html';
import 'AppPage.dart';
import 'HttpResponseParser.dart';
import 'Model.dart';
import 'StatusMessage.dart';
import 'game/Obstacle.dart';
import 'package:http/http.dart' as http;

class View {
  Model model;
  final player = querySelector('#dino');
  final _gameContentContainer = querySelector('#gameContentContainer');
  final List<Element> _obstacles = [];
  late LIElement _highscoreEntry;
  final _statusMessageLogin = StatusMessage('#statusMessageLogin');
  final _statusMessageRanking = StatusMessage('#statusMessageRanking');
  final _gameOverMsg = StatusMessage('#gameOverMessage');
  
  View(Model m) : model = m;

  String _getPageClass(AppPage page) {
    switch (page) {
      case AppPage.levelSelection: return "#levelSelectionContainer";
      case AppPage.login: return "#loginContainer";
      case AppPage.mainSelection: return "#mainSelectionMenu";
      case AppPage.ranking: return ".rankingList";
      case AppPage.game: return '.gameContainer';
      case AppPage.about: return '.aboutPage';
      default: return "#mainSelectionMenu";
    }
  }

  void showGame() {
    querySelector('#gameOverScreen')?.style.display = 'none';
    querySelector('#levelSelectionContainer')?.classes.add('hidden');
    querySelector('.gameContainer')?.classes.remove('hidden');
  }

  Future<void> showRanking(int level) async {
    querySelector('#levelSelectionContainer')?.classes.add('hidden');
    querySelector('.rankingList')?.classes.remove('hidden');

    final rankListContent = querySelector('.rankListContent');
    rankListContent?.children.clear();
    final deleteHighscoreBtn = querySelector('#deleteHighscoreBtn') as ButtonElement; 
    deleteHighscoreBtn.classes.add('hidden');

    final parsedResponse = HttpResponseParser(await model.getHighscores(level));
    if (!parsedResponse.parse(
      (p0, p1) => {}, 
      (p0) => showAuthError(), 
      (p0, p1) => _statusMessageRanking.showError('Rangliste konnte nicht geladen werden<br>($p0: $p1)'), 
      () => _statusMessageRanking.showError('Rangliste konnte nicht geladen werden<br>(Unbekannter Fehler)'))) {
        return;
    }

    _statusMessageRanking.show('Du hast bisher keinen Highscore für dieses Level');

    final List<Element> highscoreListItems = [];
    final highscoreData = parsedResponse.bodyData['highscore'];
    String myUsername = model.username;

    for (int i = 0; i < highscoreData.length; i++) {
      final highscore = highscoreData[i];
      final username = highscore['username'];
      final score = highscore['score'];

      if (myUsername.compareTo(username) == 0) {
        _statusMessageRanking.show('<center>Deine Ranglistenposition: ${i + 1}<br>(mit ${score}s)</center>');
        deleteHighscoreBtn.classes.remove('hidden');
      }
/* 
      double spanScore = score >= 60 ? (score / 60) as double
        : score >= 3600 ? ((score / 60) / 60) as double : score; */
  
      final listItem = LIElement()
        ..classes.add('rankingItem')
        ..children = [
      
        SpanElement()
          ..classes.add('username')
          ..text = myUsername.compareTo(username) == 0
            ? 'You ($username)' : username,
      
        SpanElement()
          ..classes.add('highscore')
          ..text = '${score}s'
    ];

    //Needed for delete highscore
    if (myUsername.compareTo(username) == 0) {
      _highscoreEntry = listItem;
    }

    if (i == 0) listItem.classes.add('topPlayer');
    highscoreListItems.add(listItem);
  }

    final rankingList = UListElement()..children = highscoreListItems;
    rankingList.classes.add('rankListContent');
    rankListContent?.children.add(rankingList);
  }

  Future<void> handleDeleteHighscore() async {
    if (!window.confirm('Möchstest du wirklich deinen Highscore löschen?')) {
      return;
    }

    HttpResponseParser(await model.deleteHighscore()).parse(
      (p0, p1) {
        _statusMessageRanking.showSuccess('Dein Highscore wurde erfolgreich gelöscht');
        //Delete element from list
        _highscoreEntry.remove();
        //Hide delete Highscore button
        querySelector('#deleteHighscoreBtn')?.classes.add('hidden');
      }, 
      (p0) => showAuthError(), 
      (p0, p1) => _statusMessageRanking.showError('Highscore konnte nicht gelöscht werden<br>($p0: $p1)'), 
      () => _statusMessageRanking.showError('Unbekannter Fehler ist aufgetreten<br>(Highscore konnte nicht gelöscht werden)'));
  }

  Future<void> handleDeleteAccount() async {
    if (!window.confirm('Möchstest du wirklich dein Benutzerkonto löschen?\n(ACHTUNG: deine bisherigen Highscores gehen damit verloren)')) {
      return;
    }

    HttpResponseParser(await model.deleteAccount()).parse(
      (p0, p1) => window.alert('Benutzerkonto wurde erfolgreich gelöscht'), 
      (p0) => showAuthError(), 
      (p0, p1) => window.alert('Benutzerkonto konnte nicht gelöscht werden: $p0: $p1'), 
      () => window.alert('Unbekannter Fehler aufgetreten'));

    window.alert('Benutzerkonto wurde erfolgreich gelöscht');
    _statusMessageLogin.domElement?.classes.add('hidden');
    changePage(AppPage.mainSelection, AppPage.login);
  }

  Future<void> updateGameContent() async {
    player?.style.bottom = '${model.player.playerBottom}px';

    final modelObstacles = model.obstacles;

    //Obstacles
    int i = 0;
    for (final obstacle in _obstacles) {
      final obstacleModel = modelObstacles.elementAt(i);
      obstacle.style.bottom = '${obstacleModel.bottom}px';
      obstacle.style.left = '${obstacleModel.left}px';
      obstacle.style.height = '${obstacleModel.height}px';     
      i++;
    }

    if (model.isGameOver) {
      await handleGameOver();
    }
  }

  Future<void> handleGameOver() async {
    querySelector('#gameOverScreen')?.style.display = 'flex';
    HttpResponseParser(await model.updateHighscore()).parse(
      (p0, p1) {
        final highscore = p0['highscore'] as int;

        _gameOverMsg.show(model.score == highscore
        ? '<center>Neuer Highscore erreicht (Zeit in Sekunden):<br><br>${highscore}s</center>'
        : '<center>Erreichter Score (Zeit in Sekunden): ${model.score}s<br><br>Aktueller Highscore: ${highscore}s</center>');
      }, 
      (p0) => showAuthError(), 
      (p0, p1) => _gameOverMsg.showError('Highscore fehler: $p0: $p1'), 
      () => window.alert('Unbekannter Fehler bei Abfrage des Highscors aufgetreten'));
  }

  void changePage(AppPage currPage, AppPage newPage) {
    querySelector(_getPageClass(currPage))?.classes.add('hidden');
    querySelector(_getPageClass(newPage))?.classes.remove('hidden');
  }

  void stopGame({bool isRetry = false}) {
    //Remove all existing obstacles (div-elements)
    final domObstacles = querySelectorAll('.obstacle');
    for (final domObstacle in domObstacles) {
      domObstacle.remove();
    }

    _obstacles.clear();
    querySelector('#gameOverScreen')?.style.display = 'none';
    if (!isRetry) changePage(AppPage.game, AppPage.mainSelection);
  }

  void showAuthError() {
    _statusMessageLogin.showError('Fehler bei der Authentisierung.<br>Bitte loggen Sie sich neue ein.');
  }

  void changeLevelHeadlineText(String newText) {
    querySelector('#gameHeadlineLevel')?.text = newText;
  }

  void allAllObstacles() {
    for (final obstacle in model.obstacles) {
      addObstacle(obstacle);
    } 
  }

  void addObstacle(Obstacle obstacle) {
    DivElement obstacleElement = DivElement();
    //obstacleElement.className = '.${obstacle.type}';
    obstacleElement.classes.add('obstacle');

    obstacleElement.style.position = "absolute";
    obstacleElement.style.bottom = "${obstacle.bottom}px";
    obstacleElement.style.left = "${obstacle.left}px";
    obstacleElement.style.width = "${obstacle.width}px";
    obstacleElement.style.height = "${obstacle.height}px";

    _gameContentContainer?.append(obstacleElement);
    _obstacles.add(obstacleElement);
  }

  void handleLogin(http.Response response) {
    if (model.isUserLoggedIn) {
        querySelector('#loginContainer')?.classes.add('hidden');
        querySelector('#mainSelectionMenu')?.classes.remove('hidden');
    } else {
      //Show error message according to the http response
      final responseMessage = json.decode(response.body)['message'];
      _statusMessageLogin.showError('Login fehlgeschlagen<br>($responseMessage: ${response.statusCode})');
    }
  }

  void handleRegister(http.Response response) {
    HttpResponseParser(response).parse(
      (p0, p1) => _statusMessageLogin.showSuccess('Benutzerkonto erfolgreich angelegt'), 
      (p0) => null, (p0, p1) => _statusMessageLogin.showError('Registrierung fehlgeschlagen<br>($p0: $p1)'), 
      () => null);
  }

  void handleInputErrorLogin() {
    _statusMessageLogin.showError('Benutzername oder Passwort fehlt');
  }
}