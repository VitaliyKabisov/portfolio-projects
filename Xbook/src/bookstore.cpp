#include "bookstore.h" // Подключение заголовочного файла bookstore.h, в котором объявлен класс BookStore
#include <iostream> // Подключение библиотеки для работы с вводом-выводом

// Конструктор класса BookStore
BookStore::BookStore(const std::string& name) : _name(name) {}
// Инициализация поля _name с помощью списка инициализации

// Метод для добавления книги в магазин
void BookStore::add_book(const Book& book) {
    _store.push_back(book); // Добавляет книгу в вектор _store
}

// Метод для вывода всех книг в магазине
void BookStore::show_books() const {
    for (const auto& book : _store) {
        // Перебирает все книги в векторе _store
        book.print(); // Выводит информацию о книге
    }
}

// Метод для поиска книг по автору
void BookStore::search_by_author(const std::string& author) const {
    for (const auto& book : _store) {
        // Перебирает все книги в векторе _store
        if (book.get_author() == author) {
            // Проверяет, совпадает ли автор книги с заданным
            book.print(); // Выводит информацию о книге
        }
    }
}

// Метод для поиска книг по названию
void BookStore::search_by_title(const std::string& title) const {
    for (const auto& book : _store) {
        // Перебирает все книги в векторе _store
        if (book.get_title() == title) {
            // Проверяет, совпадает ли название книги с заданным
            book.print(); // Выводит информацию о книге
        }
    }
}

// Метод для поиска книг по году издания
void BookStore::search_by_year(int year) const {
    for (const auto& book : _store) {
        // Перебирает все книги в векторе _store
        if (book.get_year() == year) {
            // Проверяет, совпадает ли год издания книги с заданным
            book.print(); // Выводит информацию о книге
        }
    }
}

// Метод для покупки книги из магазина
void BookStore::buy_book(int code, int amount) {
    for (auto& book : _store) {
        // Перебирает все книги в векторе _store
        if (book.get_code() == code) {
            // Проверяет, совпадает ли код книги с заданным
            book.decrease_amount(amount); // Уменьшает количество экземпляров книги
            std::cout << "Book purchased successfully!" << std::endl; // Выводит сообщение об успешной покупке
            return; // Выход из метода
        }
    }
    std::cout << "Book with code " << code << " not found." << std::endl; // Выводит сообщение, если книга не найдена
}

// Метод для возврата книги в магазин
void BookStore::return_book(int code, int amount) {
    for (auto& book : _store) {
        // Перебирает все книги в векторе _store
        if (book.get_code() == code) {
            // Проверяет, совпадает ли код книги с заданным
            book.increase_amount(amount); // Увеличивает количество экземпляров книги
            std::cout << "Book returned successfully!" << std::endl; // Выводит сообщение об успешном возврате
            return; // Выход из метода
        }
    }
    std::cout << "Book with code " << code << " not found." << std::endl; // Выводит сообщение, если книга не найдена
}
