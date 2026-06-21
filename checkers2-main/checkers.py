print("Добро пожаловать в Шашки!")
board = [
            [' ', 'w', ' ', 'w', ' ', 'w', ' ', 'w'],  # Начальное распределение черных шашек.
            ['w', ' ', 'w', ' ', 'w', ' ', 'w', ' '],
            [' ', 'w', ' ', 'w', ' ', 'w', ' ', 'w'],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],  # Пустая строка, разделяющая доску.
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            ['b', ' ', 'b', ' ', 'b', ' ', 'b', ' '],  # Начальное распределение белых шашек.
            [' ', 'b', ' ', 'b', ' ', 'b', ' ', 'b'],
            ['b', ' ', 'b', ' ', 'b', ' ', 'b', ' ']
]
score = "0:0"
hod = "w"
def start():
    print("Инструкция:")
    print("1. Введите свои ходы в формате 'a5 b4', где 'a5' - начальная позиция, а 'b4' - конечная.")
    print("2. Игра заканчивается, если один из игроков захватит 12 фигур противника.")
    print("3. Вы можете ввести 'end' в свой ход, чтобы завершить игру и увидеть итоговый счет.")
    print("Пусть игра начнется!\n")
def print_board():
    """Выводит текущее состояние доски для шашек.

        Доска отображается с координатами и расположением фигур.

        :return: None"""
    print("  A  B  C  D  E  F  G  H")
    for i in range(8):
        s = str(i + 1)
        for k in range(8):
            s += " " + board[i][k] + "|"
        print(s)
def usual_move(x1, y1, x2, y2):
    """Выполняет стандартный ход на доске для шашек.

        Перемещает фигуру с одной позиции на другую без захвата.

        :param x1: начальный индекс строки
        :type x1: int
        :param y1: начальный индекс столбца
        :type y1: int
        :param x2: индекс строки назначения
        :type x2: int
        :param y2: индекс столбца назначения
        :type y2: int
        :return: None"""
    board[x2][y2] = board[x1][y1]
    board[x1][y1] = ' '
def one_kill(x1, y1, x2, y2):
    """Выполняет захватывающий ход на доске для шашек.

        Перемещает фигуру с одной позиции на другую, захватывая фигуру противника.

        :param x1: начальный индекс строки
        :type x1: int
        :param y1: начальный индекс столбца
        :type y1: int
        :param x2: индекс строки назначения
        :type x2: int
        :param y2: индекс столбца назначения
        :type y2: int
        :return: None"""
    board[x2][y2] = board[x1][y1]
    board[x1][y1] = " "
    board[abs(x1 + x2) // 2][abs(y1 + y2) // 2] = " "
start()
print_board()
while True:
    print(hod)
    move = input("Введите ход (например, a5 b4) или введите 'end' для завершения игры: ")
    move = move.split()
    if move[0] == "end":
        pobed = input("Введите номер победившего игрока(1 или 2): ")
        if pobed == "1":
            score = str(int(score[0]) + 1) + score[1:]
        else:
            score = score[:2] + str(int(score[2]) + 1)
        print("Счет:", score)
        board = [
            [' ', 'w', ' ', 'w', ' ', 'w', ' ', 'w'],  # Начальное распределение черных шашек.
            ['w', ' ', 'w', ' ', 'w', ' ', 'w', ' '],
            [' ', 'w', ' ', 'w', ' ', 'w', ' ', 'w'],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],  # Пустая строка, разделяющая доску.
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            ['b', ' ', 'b', ' ', 'b', ' ', 'b', ' '],  # Начальное распределение белых шашек.
            [' ', 'b', ' ', 'b', ' ', 'b', ' ', 'b'],
            ['b', ' ', 'b', ' ', 'b', ' ', 'b', ' ']
        ]
        start()
        print_board()
        continue
    x1 = int(move[0][1]) - 1
    y1 = int(ord(move[0][0].lower()) - 96) - 1
    x2 = int(move[1][1]) - 1
    y2 = int(ord(move[1][0].lower()) - 96) - 1
    if board[x1][y1].lower() != hod:
        print("Недопустимый ход. Не ваш ход.")
        continue
    if board[x2][y2] != " " or board[x1][y1] == " ":
        print("Недопустимый ход")
        continue
    elif board[x1][y1].isupper():
        for l in range(len(move) - 1):
            x1 = int(move[l][1]) - 1
            y1 = int(ord(move[l][0].lower()) - 96) - 1
            x2 = int(move[l + 1][1]) - 1
            y2 = int(ord(move[l + 1][0].lower()) - 96) - 1
            if abs(x1 - x2) == 2 and abs(y1 - y2) == 2:
                one_kill(x1, y1, x2, y2)
            elif abs(x1 - x2) == 1 and abs(y1 - y2) == 1:
                usual_move(x1, y1, x2, y2)
        print_board()
    elif len(move) > 2:
        for l in range(len(move) - 1):
            x1 = int(move[l][1]) - 1
            y1 = int(ord(move[l][0].lower()) - 96) - 1
            x2 = int(move[l + 1][1]) - 1
            y2 = int(ord(move[l + 1][0].lower()) - 96) - 1
            one_kill(x1, y1, x2, y2)
        print_board()
    elif hod == "w" and x2 - x1 == 1 and abs(y1 - y2) == 1 or hod == "b" and x1 - x2 == 1 and abs(y1 - y2) == 1:
        usual_move(x1, y1, x2, y2)
        print_board()
    elif abs(x1 - x2) == 2 and abs(y1 - y2) == 2:
        if hod == "w" and board[abs(x1 + x2) // 2][abs(y1 + y2) // 2] != "b" or hod == "b" and board[abs(x1 + x2) // 2][abs(y1 + y2) // 2] != "w":
            print("Недопустимый ход")
            continue
        one_kill(x1, y1, x2, y2)
        print_board()
    else:
        print("Недопустимый ход.")
        continue
    print(move[-1][1])
    if hod == "w" and move[-1][1] == "8" or hod == "b" and move[-1][1] == "1":
        board[x2][y2] = "W"
    elif hod == "b" and move[-1][1] == "1":
        board[x2][y2] = "B"
    if hod == "w":
        hod = "b"
    else:
        hod = "w"
