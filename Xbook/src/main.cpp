/**
\file main.cpp
\brief Главный файл программы книжного магазина Xbookstore
**/
#include <iostream> // Подключение библиотеки для работы с вводом-выводом
#include "book.h" // Подключение заголовочного файла book.h
#include "bookstore.h" // Подключение заголовочного файла bookstore.h

/**
\brief Главная функция программы.

В этой функции создается объект книжного магазина Labirint и добавляются различные книги в магазин.

Затем запускается интерактивное меню для взаимодействия с пользователем: показ списка книг, поиск по автору, покупка и возврат книг.
**/
int main() {
    std::cout << "The Xbookstore welcomes you!" << std::endl; // Приветственное сообщение

    // Создание объекта книжного магазина
    BookStore Labirint("Xbookstore");

    // Добавление книг в магазин
    Book Mumu("Mumu", "I.S. Turgenev", 1852, 1, 10);
    Book Idiot("Idiot", "F.M. Dostoevski", 1868, 2, 112);
    Book Harry_Potter_and_philosopher_stone("Harry Potter and the Philosopher's Stone", "Dj.K. Rouling", 1997, 3, 1110);
    Book War_and_Peace("War and Peace", "L.N. Tolstoy", 1869, 4, 100);
    Book The_Master_and_Margarita("The Master and Margarita", "M. Bulgakov", 1967, 5, 85);
    Book Crime_and_Punishment("Crime and Punishment", "F.M. Dostoevski", 1866, 6, 75);

    Labirint.add_book(Mumu); // Добавление книги "Муму" в магазин
    Labirint.add_book(Idiot); // Добавление книги "Идиот" в магазин
    Labirint.add_book(Harry_Potter_and_philosopher_stone); // Добавление книги "Гарри Поттер и философский камень" в магазин
    Labirint.add_book(War_and_Peace); // Добавление книги "Война и мир" в магазин
    Labirint.add_book(The_Master_and_Margarita); // Добавление книги "Мастер и Маргарита" в магазин
    Labirint.add_book(Crime_and_Punishment); // Добавление книги "Преступление и наказание" в магазин

    int choice = 0; // Переменная для хранения выбора пользователя

    // Основной цикл работы программы
    while (choice != 4) {
        std::cout << "Choose an option:" << std::endl;
        std::cout << "1. Show all books" << std::endl;
        std::cout << "2. Search by author" << std::endl;
        std::cout << "3. Buy a book" << std::endl;
        std::cout << "4. Exit" << std::endl;
        std::cout << "5. Return a book" << std::endl; // Добавленный пункт в меню

        std::cin >> choice; // Считывание выбора пользователя

        switch (choice) {
        case 1:
            Labirint.show_books(); // Показать все книги
            break;
        case 2: {
            std::string author;
            std::cout << "Enter author name: ";
            std::cin.ignore(); // Игнорирование предыдущего ввода
            std::getline(std::cin, author); // Считывание имени автора
            Labirint.search_by_author(author); // Поиск книг по автору
            break;
        }
        case 3: {
            int code;
            std::cout << "Enter book code to buy: ";
            std::cin >> code; // Считывание кода книги
            Labirint.buy_book(code, 1); // Покупка одной книги
            break;
        }
        case 5: {
            int code;
            std::cout << "Enter book code to return: ";
            std::cin >> code; // Считывание кода книги
            Labirint.return_book(code, 1); // Возврат одной книги
            break;
        }
        case 4:
            std::cout << "Exiting..." << std::endl; // Выход из программы
            break;
        default:
            std::cout << "Invalid choice!" << std::endl; // Сообщение о неверном выборе
            break;
        }
    }

    return 0; // Возврат успешного завершения программы
}
