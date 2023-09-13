import 'dart:async';
import 'dart:html';

import 'AppPage.dart';
import 'Model.dart';
import 'View.dart';

class Controller {
  final Model _model;
  final View _view;

  //Needed for page navigation
  AppPage _currPage = AppPage.login;
  AppPage _lastPage = AppPage.login;
  bool _bIsPlaySelection = false;

  Controller(Model m) : _model = m, _view = View(m);

  void _gameTimer() {
    Timer.periodic(Duration(milliseconds: 1), (timer) {
      _model.updateGame(); 
      _view.updateGameContent(); //Update _view for current running game
      if (_model.isGameOver) timer.cancel(); //Exit if game is over
    });
  }

  Future<void> _handleLogin(String username, String password) async {
    final response = await _model.handleLoginRegister(username, password, true);
    if (response == null) {
      //error
      return;
    }

    _view.handleLogin(response);

    //change page status
    if (_model.isUserLoggedIn) {
      _lastPage = _currPage = AppPage.mainSelection;
    }
  }

  Future<void> _handleRegister(String username, String password) async {
    final response = await _model.handleLoginRegister(username, password, false);
    if (response == null) {
      //error
      return;
    }

    _view.handleRegister(response);
  }

  Future<void> _handleLoginRegisterBtn(Event event, bool isLogin) async {
    event.preventDefault();
    final usernameInput = (querySelector('input[name="Username"]') as InputElement).value;
    final passwordInput = (querySelector('input[name="Passwort"]') as InputElement).value; 

    if (usernameInput == null || usernameInput.isEmpty || passwordInput == null || passwordInput.isEmpty) {
      _view.handleInputErrorLogin();
      return;
    }

    return isLogin ? await _handleLogin(usernameInput, passwordInput) 
      : await _handleRegister(usernameInput, passwordInput);
  }

  Future<void> _handleLvlBtn(int lvl) async {
    if (_bIsPlaySelection) {
      _view.showGame();
      _model.startGame(lvl);
      _view.allAllObstacles();
      _gameTimer(); //Start game timer     
    } else {
      await _view.showRanking(lvl);
      
      if (_model.isAuthError) {
        _handleAuthError();
      } {
        _currPage = AppPage.ranking;
        _lastPage = AppPage.levelSelection;
      }
    }
  }

  void _handleAuthError() {
    _view.changePage(_currPage, AppPage.login);
    _currPage = _lastPage = AppPage.login;
    _view.showAuthError();
  }

  void _handlePlayBtn(Event event) {
    _view.changePage(_currPage, AppPage.levelSelection);
    _lastPage = _currPage;
    _currPage = AppPage.levelSelection;
    _view.changeLevelHeadlineText('Levelauswahl - Spielen');
    _bIsPlaySelection = true;
  }

  void _handleRankingBtn(Event event) {
    _view.changePage(_currPage, AppPage.levelSelection);
    _lastPage = _currPage;
    _currPage = AppPage.levelSelection;
    _view.changeLevelHeadlineText('Levelauswahl - Rangliste');
    _bIsPlaySelection = false;
  }

  void _handleBackNavigation(Event event) {
    _view.changePage(_currPage, _lastPage);
    
    if (_currPage == AppPage.ranking) {
      _lastPage = AppPage.mainSelection;
      _currPage = AppPage.levelSelection;
    } else {
      _lastPage = _currPage = AppPage.mainSelection;
    }
  }

  void _handleSpaceKey(KeyboardEvent event) {
    if (!_model.isGameRunning) return;

    //Player jump
    if (event.keyCode == KeyCode.SPACE) {
      _model.player.jump();
    }
  }

  void setupEventListeners() {
    querySelector('#loginBtn')?.onClick.listen((event) async => await _handleLoginRegisterBtn(event, true));
    querySelector('#registerBtn')?.onClick.listen((event) async => await _handleLoginRegisterBtn(event, false));

    querySelector('#playBtn')?.onClick.listen(_handlePlayBtn);
    querySelector('#rankingBtn')?.onClick.listen(_handleRankingBtn);

    querySelector('#levelButton1')?.onClick.listen((e) async => await _handleLvlBtn(1));
    querySelector('#levelButton2')?.onClick.listen((e) async => await _handleLvlBtn(2));
    querySelector('#levelButton3')?.onClick.listen((e) async => await _handleLvlBtn(3));

    querySelector('#goBackBtn')?.onClick.listen(_handleBackNavigation);

    //Ranking
    querySelector('#goBackRanking')?.onClick.listen(_handleBackNavigation);

    querySelector('#deleteHighscoreBtn')?.onClick.listen((event) async {
      await _view.handleDeleteHighscore();
    });

    //Game over screen
    querySelector('#gameOverRetryBtn')?.onClick.listen((event) async {
      _bIsPlaySelection = true;
      _model.stopGame();
      _view.stopGame(isRetry: true);
      await _handleLvlBtn(_model.currLevel);
    });

    querySelector('#gameOverReturnBtn')?.onClick.listen((event) {
      _view.stopGame();
      _model.stopGame();
      _currPage = _lastPage = AppPage.mainSelection;
    });

    //Delete account
    querySelector('#deleteAccountBtn')?.onClick.listen((event) {
      _view.handleDeleteAccount();
    });

    //About
    querySelector('#aboutBtn')?.onClick.listen((event) {
      _view.changePage(AppPage.mainSelection, AppPage.about);
    });

    querySelector('#aboutReturnBtn')?.onClick.listen((event) {
      _view.changePage(AppPage.about, AppPage.mainSelection);
      _currPage = _lastPage = AppPage.mainSelection;
    });

    window.onKeyDown.listen(_handleSpaceKey);
  }
}