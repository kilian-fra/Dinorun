import 'Controller.dart';
import 'Model.dart';

void main() {
  final controller = Controller(Model());
  controller.setupEventListeners();
}