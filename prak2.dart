import 'dart:io';
import 'dart:math';

void main() {
  bool exitGame = false;
  
  while (!exitGame) {
    print('1) Играть с другим игроком');
    print('2) Играть с роботом');
    print('3) Выход');
    print('Выберите режим игры (номер):');
    
    try {
      String input = stdin.readLineSync()!;
      int mode = int.parse(input);
      
      if (mode == 3) {
        exitGame = true;
        print('Программа закрывается . . .');
        continue;
      }
      
      if (mode != 1 && mode != 2) {
        print('Неверный выбор. Попробуйте снова.');
        continue;
      }

      Igrok igrok1 = Igrok();
      Igrok igrok2 = mode == 1 ? Igrok() : Robot();

      print('Игрок 1, разместите свои корабли:');
      igrok1.razmestitKorabli();
      print('Игрок 2, разместите свои корабли:');
      igrok2.razmestitKorabli();

      bool igraZavershena = false;

      while (!igraZavershena) {
        print('Ход Игрока 1:');
        igraZavershena = igrok1.sdelatHod(igrok2);

        if (igraZavershena) {
          print('Игрок 1 выиграл!');
          break;
        }

        print('Ход Игрока 2:');
        igraZavershena = igrok2.sdelatHod(igrok1);

        if (igraZavershena) {
          print('Игрок 2 выиграл!');
          break;
        }
      }
      
      print('Нажмите enter чтобы вернуться в меню...');
      stdin.readLineSync();
      
    } catch (e) {
      print('Ошибка ввода, введите число от 1 до 3.');
    }
  }
}

class Korabl {
  int razmer;
  int popadaniya = 0;
  List<List<int>> pozicii = [];

  Korabl(this.razmer);

  bool potoplen() => popadaniya >= razmer;
}

class Pole {
  List<List<String>> setka = List.generate(10, (_) => List.filled(10, ' '));
  List<Korabl> korabli = [];

  void razmestitKorabl(Korabl korabl, int x, int y, bool gorizontalno) {
    for (int i = 0; i < korabl.razmer; i++) {
      if (gorizontalno) {
        setka[x][y + i] = 'S';
        korabl.pozicii.add([x, y + i]);
      } else {
        setka[x + i][y] = 'S';
        korabl.pozicii.add([x + i, y]);
      }
    }
    korabli.add(korabl);
  }

  bool popadanie(int x, int y) => setka[x][y] == 'S';
  bool promah(int x, int y) => setka[x][y] == ' ';
  bool ujeStrelyali(int x, int y) => setka[x][y] == 'X' || setka[x][y] == 'O';
  void otmetitPopadanie(int x, int y) => setka[x][y] = 'X';
  void otmetitPromah(int x, int y) => setka[x][y] = 'O';
  
  bool vseKorabliPotopleny() {
    for (var korabl in korabli) {
      if (!korabl.potoplen()) return false;
    }
    return true;
  }

  void otobrazhit(bool pokazatKorabli) {
    print('  0 1 2 3 4 5 6 7 8 9');
    
    for (int i = 0; i < 10; i++) {
      stdout.write('$i ');
      
      for (int j = 0; j < 10; j++) {
        String kletka = setka[i][j];
        if (!pokazatKorabli && kletka == 'S') {
          kletka = ' ';
        }
        stdout.write('$kletka ');
      }
      print('');
    }
    print('');
  }
}

class Igrok {
  Pole moePole = Pole();
  Pole poleProtivnika = Pole();

  void razmestitKorabli() {
    List<int> razmeryKorabley = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
    
    print('Расставляйте корабли:');
    print('Сначала введите координату X (0-9):');
    print('Потом координату Y (0-9):'); 
    print('Потом направление (g - горизонтально, v - вертикально):');

    for (int razmer in razmeryKorabley) {
      while (true) {
        print('\nРазместите корабль размером $razmer:');
        moePole.otobrazhit(true);

        try {
          print('Введите координату Y (0-9):');
          int x = int.parse(stdin.readLineSync()!);
          
          print('Введите координату X (0-9):');
          int y = int.parse(stdin.readLineSync()!);
          
          print('Введите направление (g - горизонтально, v - вертикально):');
          String napravlenie = stdin.readLineSync()!.trim().toLowerCase();
          
          bool gorizontalno;
          if (napravlenie == 'g' || napravlenie == 'горизонтально') {
            gorizontalno = true;
          } else if (napravlenie == 'v' || napravlenie == 'вертикально') {
            gorizontalno = false;
          } else {
            print('Неверное направление! Используйте "g" или "v"');
            continue;
          }

          if (_razmestitKorablProverka(moePole, x, y, razmer, gorizontalno)) {
            moePole.razmestitKorabl(Korabl(razmer), x, y, gorizontalno);
            print('Корабль размещен успешно!');
            break;
          } else {
            print('X Невозможно разместить корабль здесь. Попробуйте снова.');
          }
        } catch (e) {
          print('Ошибка ввода, вводите числа для координат.');
        }
      }
    }
    
    print('\nВсе корабли расставлены!');
    moePole.otobrazhit(true);
  }

  bool _razmestitKorablProverka(Pole pole, int x, int y, int razmer, bool gorizontalno) {
    if (gorizontalno) {
      if (y + razmer > 10) {
        print('Корабль выходит за границы поля по горизонтали');
        return false;
      }
    } else {
      if (x + razmer > 10) {
        print('Корабль выходит за границы поля по вертикали');
        return false;
      }
    }

    for (int i = 0; i < razmer; i++) {
      int checkX = gorizontalno ? x : x + i;
      int checkY = gorizontalno ? y + i : y;
      
      if (checkX < 0 || checkX >= 10 || checkY < 0 || checkY >= 10) {
        return false;
      }
      
      if (pole.setka[checkX][checkY] != ' ') {
        print('Клетка ($checkX, $checkY) уже занята');
        return false;
      }
      
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          int neighborX = checkX + dx;
          int neighborY = checkY + dy;
          
          if (neighborX >= 0 && neighborX < 10 && neighborY >= 0 && neighborY < 10) {
            if (pole.setka[neighborX][neighborY] != ' ') {
              print('Слишком близко к другому кораблю в клетке ($neighborX, $neighborY)');
              return false;
            }
          }
        }
      }
    }
    
    return true;
  }

  bool sdelatHod(Igrok protivnik) {
    while (true) {
      print('\nВаше поле:');
      moePole.otobrazhit(true);

      print('Поле противника:');
      poleProtivnika.otobrazhit(false);

      try {
        print('Введите координату X для выстрела (0-9):');
        int x = int.parse(stdin.readLineSync()!);
        
        print('Введите координату Y для выстрела (0-9):');
        int y = int.parse(stdin.readLineSync()!);

        if (x < 0 || x >= 10 || y < 0 || y >= 10) {
          print('Координаты должны быть от 0 до 9. Попробуйте снова.');
          continue;
        }

        if (poleProtivnika.ujeStrelyali(x, y)) {
          print('Вы уже стреляли в эту клетку. Попробуйте снова.');
          continue;
        }

        if (protivnik.moePole.popadanie(x, y)) {
          print('Попадание в ($x, $y)! ');
          
          protivnik.moePole.otmetitPopadanie(x, y);
          poleProtivnika.otmetitPopadanie(x, y);

          for (var korabl in protivnik.moePole.korabli) {
            for (var poziciya in korabl.pozicii) {
              if (poziciya[0] == x && poziciya[1] == y) {
                korabl.popadaniya++;
                if (korabl.potoplen()) {
                  print(' Корабль размером ${korabl.razmer} потоплен!');
                }
              }
            }
          }

          if (protivnik.moePole.vseKorabliPotopleny()) return true;
          
        } else {
          print('О Промах в ($x, $y)');
          protivnik.moePole.otmetitPromah(x, y);
          poleProtivnika.otmetitPromah(x, y);
          return false;
        }

      } catch (e) {
        print('Ошибка ввода, вводите числа для координат.');
      }
    }
  }
}

class Robot extends Igrok {
  Random random = Random();

  @override
  void razmestitKorabli() {
    List<int> razmeryKorabley = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
    
    print('Робот расставляет корабли...');
    
    for (int razmer in razmeryKorabley) {
      int popytki = 0;
      while (popytki < 100) {
        int x = random.nextInt(10);
        int y = random.nextInt(10);
        bool gorizontalno = random.nextBool();

        if (_razmestitKorablProverka(moePole, x, y, razmer, gorizontalno)) {
          moePole.razmestitKorabl(Korabl(razmer), x, y, gorizontalno);
          break;
        }
        popytki++;
      }
    }
    
    print('Робот расставил все корабли!');
  }

  @override
  bool sdelatHod(Igrok protivnik) {
    print('Робот делает ход...');
    
    sleep(Duration(milliseconds: 1000));
    
    while (true) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);

      if (!poleProtivnika.ujeStrelyali(x, y)) {
        if (protivnik.moePole.popadanie(x, y)) {
          print('Робот попал в ($x, $y)!');
          
          protivnik.moePole.otmetitPopadanie(x, y);
          poleProtivnika.otmetitPopadanie(x, y);
          
          for (var korabl in protivnik.moePole.korabli) {
            for (var poziciya in korabl.pozicii) {
              if (poziciya[0] == x && poziciya[1] == y) {
                korabl.popadaniya++;
                if (korabl.potoplen()) {
                  print('Робот потопил корабль размером ${korabl.razmer}!');
                }
              }
            }
          }
          
          if (protivnik.moePole.vseKorabliPotopleny()) return true;
          
        } else {
          print('Робот промахнулся в ($x, $y)');
          protivnik.moePole.otmetitPromah(x, y);
          poleProtivnika.otmetitPromah(x, y);
          return false;
        }
      }
    }
  }
}