#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"
#include "book.h"
#include "bookstore.h"

TEST_CASE("Book class") {
    Book book("Test Title", "Test Author", 2000, 12345, 10);

    CHECK(book.get_title() == "Test Title");
    CHECK(book.get_author() == "Test Author");
    CHECK(book.get_year() == 2000);
    CHECK(book.get_code() == 12345);
    CHECK(book.get_amount() == 10);

    book.decrease_amount(2);
    CHECK(book.get_amount() == 8);

    book.increase_amount(5);
    CHECK(book.get_amount() == 13);

    book.set_amount(20);
    CHECK(book.get_amount() == 20);
}

TEST_CASE("BookStore add_book and show_books") {
    BookStore store("Test Store");

    Book book1("Book One", "Author One", 2001, 1, 5);
    Book book2("Book Two", "Author Two", 2002, 2, 3);

    store.add_book(book1);
    store.add_book(book2);

    std::ostringstream output;
    std::streambuf* oldCoutBuf = std::cout.rdbuf(output.rdbuf());

    store.show_books();

    std::cout.rdbuf(oldCoutBuf);

    std::string expected_output = "Title: Book One, Author: Author One, Year: 2001, Code: 1, Amount: 5\n"
        "Title: Book Two, Author: Author Two, Year: 2002, Code: 2, Amount: 3\n";

    CHECK(output.str() == expected_output);
}

TEST_CASE("BookStore buy_book and return_book") {
    BookStore store("Test Store");

    Book book1("Book One", "Author One", 2001, 1, 5);
    store.add_book(book1);

    store.buy_book(1, 2);
    CHECK(book1.get_amount() == 3);

    store.return_book(1, 1);
    CHECK(book1.get_amount() == 4);

    std::ostringstream output;
    std::streambuf* oldCoutBuf = std::cout.rdbuf(output.rdbuf());

    store.buy_book(1, 10); // Покупка недоступного количества книг
    std::cout.rdbuf(oldCoutBuf);

    CHECK(output.str() == "Book with code 1 not found.\n");
}


