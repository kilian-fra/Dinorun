import 'dart:html';

class StatusMessage {
  final Element? _domElement;

  StatusMessage(String selector)
    : _domElement = querySelector(selector);

  void showError(String innerHtml) {
    _domElement?.innerHtml = innerHtml;
    _domElement?.classes.remove('successMessage');
    _domElement?.classes.add('errorMessage');
    _domElement?.classes.remove('hidden');
  }  

  void showSuccess(String innerHtml) {
    _domElement?.innerHtml = innerHtml;
    _domElement?.classes.remove('errorMessage');
    _domElement?.classes.add('successMessage');
    _domElement?.classes.remove('hidden');
  }

  void show(String innerHtml) {
    _domElement?.innerHtml = innerHtml;
    _domElement?.classes.remove('errorMessage');
    _domElement?.classes.remove('successMessage');
    _domElement?.classes.remove('hidden');
  }

  Element? get domElement {
    return _domElement;
  }
}