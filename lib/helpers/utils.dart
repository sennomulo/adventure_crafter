import 'dart:math';

final Random _random = Random();

int rollDie(int faces) => _random.nextInt(faces) + 1;

int roll100() => rollDie(100);

int roll10() => rollDie(10);

int rowForRoll(int d100) => (d100 - 1) ~/ 4;
