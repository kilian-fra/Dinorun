import 'dart:html';

int getCurrentGroundWidthPx() {
  final pxValue = (99 * (window.innerWidth ?? 0) / 100);
  return pxValue.round();
}

/* int getCurrentGroundHeighthPx(int vw) {
  final pxValue = (85 * window.innerHeight) / 100;
  return pxValue.round();
} */