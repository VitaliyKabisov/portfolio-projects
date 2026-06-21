/**

\file bookstore.h
Заголовочный файл, содержащий описание класса BookStore
**/
#ifndef BOOKSTORE_H_INCLUDED
#define BOOKSTORE_H_INCLUDED

#include "book.h" // Подключение заголовочного файла book.h
#include <vector> // Подключение библиотеки для работы с контейнером std::vector
#include <string> // Подключение библиотеки для работы с типом std::string

/**

\brief Класс, представляющий книжный магазин
/
class BookStore {
public:
/

\brief Конструктор книжного магазина
\param name Название книжного магазина
**/
BookStore(const std::string& name = "Xbookstore");
/**

\brief Добавление книги в магазин
\param book Книга для добавления
**/
void add_book(const Book& book);
/**

\brief Вывод всех книг в магазине в консоль
**/
void show_books() const;
/**

\brief Поиск книг по автору
\param author Имя автора для поиска
**/
void search_by_author(const std::string& author) const;
/**

\brief Поиск книг по названию
\param title Название книги для поиска
**/
void search_by_title(const std::string& title) const;
/**

\brief Поиск книг по году издания
\param year Год издания книги для поиска
**/
void search_by_year(int year) const;
/**

\brief Покупка книги из магазина
\param code Уникальный код книги для покупки
\param amount Количество экземпляров книги для покупки
**/
void buy_book(int code, int amount);
/**

\brief Возврат книги в магазин
\param code Уникальный код книги для возврата
\param amount Количество экземпляров книги для возврата
**/
void return_book(int code, int amount);
private:
	std::string _name; ///< Название книжного магазина
	std::vector<Book> _store; ///< Вектор, содержащий книги в магазине
};

#endif // BOOKSTORE_H_INCLUDED
