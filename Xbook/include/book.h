/**

\file book.h
Заголовочный файл, содержащий описание класса Book
**/
#ifndef BOOK_H_INCLUDED
#define BOOK_H_INCLUDED

#include <string> // Подключение библиотеки для работы с типом std::string

/**

\brief Класс, представляющий книгу в книжном магазине
/
class Book {
public:
/

\brief Конструктор книги
\param title Название книги
\param author Автор книги
\param year Год издания книги
\param code Уникальный код книги
\param amount Количество экземпляров книги в магазине
**/
Book(const std::string& title, const std::string& author, int year, int code, int amount);
/**

\brief Вывод информации о книге в консоль
**/
void print() const;
/**

\brief Получение уникального кода книги
\return Уникальный код книги
**/
int get_code() const;
/**

\brief Получение названия книги
\return Название книги
**/
std::string get_title() const;
/**

\brief Получение автора книги
\return Автор книги
**/
std::string get_author() const;
/**

\brief Получение года издания книги
\return Год издания книги
**/
int get_year() const;
/**

\brief Получение количества экземпляров книги в магазине
\return Количество экземпляров книги
**/
int get_amount() const;
/**

\brief Уменьшение количества экземпляров книги на заданное число
\param num Число, на которое уменьшается количество
**/
void decrease_amount(int num);
/**

\brief Увеличение количества экземпляров книги на заданное число
\param num Число, на которое увеличивается количество
**/
void increase_amount(int num);
/**

\brief Установка нового значения количества экземпляров книги
\param amount Новое значение количества экземпляров
**/
void set_amount(int amount);
private:
	std::string _title; ///< Название книги
	std::string _author; ///< Автор книги
	int _year; ///< Год издания книги
	int _code; ///< Уникальный код книги
	int _amount; ///< Количество экземпляров книги в магазине
};

#endif // BOOK_H_INCLUDED
