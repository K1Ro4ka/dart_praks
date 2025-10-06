import 'dart:io';
import 'dart:math';

void main() {
  final random = Random();
  int bonusX = 0;
  int bonusO = 0;

  while (true) {
    print(
        "\nВыберите действие: \n 1 - Начать новую игру (два игрока)\n 2 - Начать новую игру с роботом\n 3 - Закрыть программу");
    int vibor = int.parse(stdin.readLineSync()!);

    if (vibor == 1 || vibor == 2) {
      print('Введите размер матрицы (от 3 до 9):');
      int razmer = int.parse(stdin.readLineSync()!);
      razmer += 1;

      if (razmer < 4 || razmer > 10) {
        print('Неверный размер матрицы. Введите число от 3 до 9.');
        continue;
      }

      List<List<String>> matrix =
          List.generate(razmer, (i) => List.filled(razmer, ''));

      for (int i = 0; i < razmer; i++) {
        for (int j = 0; j < razmer; j++) {
          if (i == 0 && j == 0) {
            matrix[i][j] = '';
          } else if (i == 0) {
            matrix[i][j] = j.toString();
          } else if (j == 0) {
            matrix[i][j] = i.toString();
          } else {
            matrix[i][j] = '.';
          }
        }
      }

      String player = random.nextBool() ? 'X' : 'O';
      print('Первый ход делает игрок: $player');

      int hodX = 0;
      int hodO = 0;

      while (true) {
        printMatrix(matrix);

        if (vibor == 2 && player == 'O') {
          print('Ходит робот...');
          List<List<int>> freeCells = [];
          for (int i = 1; i < razmer; i++) {
            for (int j = 1; j < razmer; j++) {
              if (matrix[i][j] == '.') {
                freeCells.add([i, j]);
              }
            }
          }
          if (freeCells.isNotEmpty) {
            var move = freeCells[random.nextInt(freeCells.length)];
            int row = move[0];
            int col = move[1];
            matrix[row][col] = player;
            print('Робот сделал ход: $row $col');
          }
        } else {
          print('Игрок $player, ваш ход!');
          print(
              'Введите номер строки и столбца (например, 1 2, где 1 - номер строки, а 2 - номер столбца):');
          var input = stdin.readLineSync()!.split(' ');
          int nomerstroki = int.parse(input[0]);
          int nomerstolba = int.parse(input[1]);

          if (nomerstroki < 1 ||
              nomerstroki >= razmer ||
              nomerstolba < 1 ||
              nomerstolba >= razmer ||
              matrix[nomerstroki][nomerstolba] != '.') {
            print('Некорректный ход. Попробуйте снова.');
            continue;
          }
          matrix[nomerstroki][nomerstolba] = player;
        }

        if (player == 'X') hodX++;
        if (player == 'O') hodO++;

        if (proverkapobedi(matrix, player, 1, 1)) {
          printMatrix(matrix);
          print('Игрок $player победил!');

          if (player == 'X' && hodX <= 5) {
            bonusX++;
            print('Игрок X получает бонусное очко за быструю победу!');
          } else if (player == 'O' && hodO <= 5) {
            bonusO++;
            print('Игрок O получает бонусное очко за быструю победу!');
          }
          break;
        }

        if (proverkanichya(matrix)) {
          printMatrix(matrix);
          print('\nНичья!');
          break;
        }

        player = (player == 'X') ? 'O' : 'X';
      }

      print('\nТекущие бонусные очки: X - $bonusX, O - $bonusO');
    } else if (vibor == 3) {
      print('Программа закрывается...');
      break;
    } else {
      print('Неверный выбор. Попробуйте снова.');
    }
  }
}

void printMatrix(List<List<String>> matrix) {
  print('\nТекущее поле:');
  for (int i = 0; i < matrix.length; i++) {
    for (int j = 0; j < matrix[i].length; j++) {
      stdout.write(matrix[i][j].padLeft(3));
    }
    print('');
  }
}

bool proverkapobedi(List<List<String>> matrix, String player, int row, int col) {
  int n = matrix.length;
  for (int i = 1; i < n; i++) {
    bool rowWin = true;
    for (int j = 1; j < n; j++) {
      if (matrix[i][j] != player) {
        rowWin = false;
        break;
      }
    }
    if (rowWin) return true;
  }

  for (int j = 1; j < n; j++) {
    bool colWin = true;
    for (int i = 1; i < n; i++) {
      if (matrix[i][j] != player) {
        colWin = false;
        break;
      }
    }
    if (colWin) return true;
  }

  bool diag1 = true, diag2 = true;
  for (int i = 1; i < n; i++) {
    if (matrix[i][i] != player) diag1 = false;
    if (matrix[i][n - i] != player) diag2 = false;
  }
  return diag1 || diag2;
}

bool proverkanichya(List<List<String>> matrix) {
  for (int i = 1; i < matrix.length; i++) {
    for (int j = 1; j < matrix.length; j++) {
      if (matrix[i][j] == '.') {
        return false;
      }
    }
  }
  return true;
}
