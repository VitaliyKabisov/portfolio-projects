#include "book.h" // Подключение заголовочного файла book.h, в котором объявлен класс Book
#include <iostream> // Подключение библиотеки для работы с вводом-выводом

// Конструктор класса Book
Book::Book(const std::string& title, const std::string& author, int year, int code, int amount)
    : _title(title), _author(author), _year(year), _code(code), _amount(amount) {}
// Инициализация полей класса с помощью списка инициализации

// Метод для вывода информации о книге
void Book::print() const {
    std::cout << "Title: " << _title << ", Author: " << _author << ", Year: " << _year
        << ", Code: " << _code << ", Amount: " << _amount << std::endl;
}

// Геттеры для получения информации о книге
int Book::get_code() const {
    return _code; // Возвращает значение поля _code
}

std::string Book::get_title() const {
    return _title; // Возвращает значение поля _title
}

std::string Book::get_author() const {
    return _author; // Возвращает значение поля _author
}

int Book::get_year() const {
    return _year; // Возвращает значение поля _year
}

int Book::get_amount() const {
    return _amount; // Возвращает значение поля _amount
}

// Методы для изменения количества книг
void Book::decrease_amount(int num) {
    _amount -= num; // Уменьшает количество экземпляров книги на num
}

void Book::increase_amount(int num) {
    _amount += num; // Увеличивает количество экземпляров книги на num
}

// Реализация метода set_amount(int)
void Book::set_amount(int amount) {
    _amount = amount; // Устанавливает количество экземпляров книги в amount
}
