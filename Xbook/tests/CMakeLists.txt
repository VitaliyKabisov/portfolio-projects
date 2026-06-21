# Добавляем тестовый исходный файл
set(TEST_SOURCE_FILES
    test_bookstore.cpp
)

# Создаем исполняемый файл для тестов
add_executable(Xbookstore_tests ${TEST_SOURCE_FILES})

# Устанавливаем цель и связываем с заголовочными и исходными файлами
target_include_directories(Xbookstore_tests PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_sources(Xbookstore_tests PRIVATE ${CMAKE_SOURCE_DIR}/src/book.cpp ${CMAKE_SOURCE_DIR}/src/bookstore.cpp)

