

CREATE SCHEMA IF NOT EXISTS exts;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA exts;

DROP SCHEMA IF EXISTS varava_food CASCADE;
CREATE SCHEMA varava_food;

SET search_path TO varava_food, exts, public;

-- Последовательность используется только для генерации уникальных телефонных номеров и ИНН в insert_test_data().
-- Это убирает случайные дубли при повторных вызовах процедуры.
CREATE SEQUENCE test_unique_number_seq START 1000000000;

-- ============================================================
-- ENUM-типы
-- ============================================================

CREATE TYPE courier_status AS ENUM ('active', 'dismissed');
CREATE TYPE restaurant_status AS ENUM ('active', 'closed');
CREATE TYPE product_status AS ENUM ('available', 'unavailable');
CREATE TYPE order_status AS ENUM ('created', 'cooking', 'delivering', 'delivered', 'cancelled');
CREATE TYPE pay_status AS ENUM ('not_paid', 'paid', 'refunded');
CREATE TYPE payment_status AS ENUM ('created', 'success', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('card', 'cash', 'sbp');
CREATE TYPE review_entity_type AS ENUM ('restaurant', 'product', 'order');

-- ============================================================
-- Нормализованная структура
-- ============================================================

CREATE TABLE city (
    city_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    city_name varchar(80) NOT NULL,
    CONSTRAINT chk_city_name CHECK (length(trim(city_name)) BETWEEN 1 AND 80)
);

CREATE TABLE street (
    street_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    city_id uuid NOT NULL REFERENCES city(city_id),
    street_name varchar(100) NOT NULL,
    CONSTRAINT chk_street_name CHECK (length(trim(street_name)) BETWEEN 1 AND 100)
);

CREATE TABLE address (
    address_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    street_id uuid NOT NULL REFERENCES street(street_id),
    house_number varchar(20) NOT NULL,
    building varchar(20) NOT NULL,
    apartment_office varchar(20) NOT NULL,
    CONSTRAINT chk_address_house CHECK (length(trim(house_number)) BETWEEN 1 AND 20),
    CONSTRAINT chk_address_building CHECK (length(trim(building)) BETWEEN 1 AND 20),
    CONSTRAINT chk_address_apartment CHECK (length(trim(apartment_office)) BETWEEN 1 AND 20)
);

CREATE TABLE client (
    client_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    login varchar(50) NOT NULL UNIQUE,
    password_hash varchar(64) NOT NULL,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    middle_name varchar(50) NOT NULL,
    phone_number char(12) NOT NULL UNIQUE,
    email varchar(80) NOT NULL UNIQUE,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_client_login CHECK (length(trim(login)) BETWEEN 3 AND 50),
    CONSTRAINT chk_client_password CHECK (length(trim(password_hash)) BETWEEN 10 AND 64),
    CONSTRAINT chk_client_first_name CHECK (length(trim(first_name)) BETWEEN 1 AND 50),
    CONSTRAINT chk_client_last_name CHECK (length(trim(last_name)) BETWEEN 1 AND 50),
    CONSTRAINT chk_client_middle_name CHECK (length(trim(middle_name)) BETWEEN 1 AND 50),
    CONSTRAINT chk_client_phone CHECK (phone_number ~ '^\+7[0-9]{10}$'),
    CONSTRAINT chk_client_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE TABLE client_address (
    client_id uuid NOT NULL REFERENCES client(client_id) ON DELETE CASCADE,
    address_id uuid NOT NULL REFERENCES address(address_id) ON DELETE CASCADE,
    is_default boolean NOT NULL DEFAULT false,
    PRIMARY KEY (client_id, address_id)
);

CREATE TABLE courier (
    courier_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    middle_name varchar(50) NOT NULL,
    phone_number char(12) NOT NULL UNIQUE,
    status courier_status NOT NULL,
    hire_date date NOT NULL,
    dismissal_date date,
    CONSTRAINT chk_courier_first_name CHECK (length(trim(first_name)) BETWEEN 1 AND 50),
    CONSTRAINT chk_courier_last_name CHECK (length(trim(last_name)) BETWEEN 1 AND 50),
    CONSTRAINT chk_courier_middle_name CHECK (length(trim(middle_name)) BETWEEN 1 AND 50),
    CONSTRAINT chk_courier_phone CHECK (phone_number ~ '^\+7[0-9]{10}$'),
    CONSTRAINT chk_courier_dates CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date)
);

-- Ставка курьера хранится отдельно по месяцу.
-- Ложного surrogate PK нет: один курьер имеет одну ставку на один месяц.
CREATE TABLE courier_rate (
    courier_id uuid NOT NULL REFERENCES courier(courier_id) ON DELETE CASCADE,
    year int NOT NULL,
    month int NOT NULL,
    percent_rate numeric(4,2) NOT NULL,
    PRIMARY KEY (courier_id, year, month),
    CONSTRAINT chk_courier_rate_year CHECK (year BETWEEN 2020 AND 2100),
    CONSTRAINT chk_courier_rate_month CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT chk_courier_rate_percent CHECK (percent_rate IN (0.05, 0.10, 0.20, 0.30, 0.40, 0.50))
);

-- По ТЗ таблица выплат содержит год, месяц, курьера и сумму выплаты.
CREATE TABLE courier_pay (
    year int NOT NULL,
    month int NOT NULL,
    courier_id uuid NOT NULL REFERENCES courier(courier_id) ON DELETE CASCADE,
    amount numeric(9,2) NOT NULL,
    PRIMARY KEY (year, month, courier_id),
    CONSTRAINT chk_courier_pay_year CHECK (year BETWEEN 2020 AND 2100),
    CONSTRAINT chk_courier_pay_month CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT chk_courier_pay_amount CHECK (amount >= 0 AND amount <= 9999999.99)
);

CREATE TABLE restaurant_legal_detail (
    restaurant_legal_detail_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    legal_name varchar(120) NOT NULL,
    inn char(10) NOT NULL UNIQUE,
    CONSTRAINT chk_legal_name CHECK (length(trim(legal_name)) BETWEEN 1 AND 120),
    CONSTRAINT chk_legal_inn CHECK (inn ~ '^[0-9]{10}$')
);

CREATE TABLE restaurant (
    restaurant_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    restaurant_name varchar(100) NOT NULL,
    address_id uuid NOT NULL REFERENCES address(address_id),
    restaurant_legal_detail_id uuid NOT NULL REFERENCES restaurant_legal_detail(restaurant_legal_detail_id),
    phone_number char(12) NOT NULL UNIQUE,
    description varchar(300) NOT NULL,
    rating numeric(3,2) NOT NULL DEFAULT 0,
    status restaurant_status NOT NULL,
    CONSTRAINT chk_restaurant_name CHECK (length(trim(restaurant_name)) BETWEEN 1 AND 100),
    CONSTRAINT chk_restaurant_phone CHECK (phone_number ~ '^\+7[0-9]{10}$'),
    CONSTRAINT chk_restaurant_description CHECK (length(trim(description)) BETWEEN 1 AND 300),
    CONSTRAINT chk_restaurant_rating CHECK (rating BETWEEN 0 AND 5)
);

-- График работы вынесен из ресторана, чтобы не хранить массив/несколько значений в одном поле.
CREATE TABLE restaurant_work_time (
    restaurant_id uuid NOT NULL REFERENCES restaurant(restaurant_id) ON DELETE CASCADE,
    week_day int NOT NULL,
    open_time time NOT NULL,
    close_time time NOT NULL,
    PRIMARY KEY (restaurant_id, week_day),
    CONSTRAINT chk_restaurant_week_day CHECK (week_day BETWEEN 1 AND 7),
    CONSTRAINT chk_restaurant_work_time CHECK (open_time < close_time)
);

CREATE TABLE product_category (
    product_category_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    product_category_name varchar(80) NOT NULL,
    CONSTRAINT chk_product_category_name CHECK (length(trim(product_category_name)) BETWEEN 1 AND 80)
);

CREATE TABLE product (
    product_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    product_name varchar(100) NOT NULL,
    product_category_id uuid NOT NULL REFERENCES product_category(product_category_id),
    restaurant_id uuid NOT NULL REFERENCES restaurant(restaurant_id),
    price numeric(7,2) NOT NULL,
    photo_url varchar(200) NOT NULL,
    rating numeric(3,2) NOT NULL DEFAULT 0,
    status product_status NOT NULL,
    description varchar(300) NOT NULL,
    CONSTRAINT chk_product_name CHECK (length(trim(product_name)) BETWEEN 1 AND 100),
    CONSTRAINT chk_product_price CHECK (price > 0 AND price <= 50000),
    CONSTRAINT chk_product_photo CHECK (length(trim(photo_url)) BETWEEN 1 AND 200),
    CONSTRAINT chk_product_rating CHECK (rating BETWEEN 0 AND 5),
    CONSTRAINT chk_product_description CHECK (length(trim(description)) BETWEEN 1 AND 300)
);

CREATE TABLE "order" (
    order_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    courier_id uuid REFERENCES courier(courier_id),
    client_id uuid NOT NULL REFERENCES client(client_id),
    address_id uuid NOT NULL REFERENCES address(address_id),
    restaurant_id uuid NOT NULL REFERENCES restaurant(restaurant_id),
    order_timestamp timestamp NOT NULL,
    delivery_timestamp timestamp,
    order_amount numeric(9,2) NOT NULL DEFAULT 0,
    commission numeric(9,2) NOT NULL DEFAULT 0,
    total_amount numeric(9,2) NOT NULL DEFAULT 0,
    rating numeric(3,2) NOT NULL DEFAULT 0,
    status order_status NOT NULL,
    pay_status pay_status NOT NULL,
    description varchar(300) NOT NULL,
    CONSTRAINT chk_order_amount CHECK (order_amount >= 0 AND order_amount <= 9999999.99),
    CONSTRAINT chk_order_commission CHECK (commission >= 0 AND commission <= 999999.99),
    CONSTRAINT chk_order_total CHECK (total_amount >= 0 AND total_amount <= 9999999.99),
    CONSTRAINT chk_order_rating CHECK (rating BETWEEN 0 AND 5),
    CONSTRAINT chk_order_delivery CHECK (delivery_timestamp IS NULL OR delivery_timestamp >= order_timestamp),
    CONSTRAINT chk_order_description CHECK (length(trim(description)) BETWEEN 1 AND 300)
);

CREATE TABLE order_structure (
    order_id uuid NOT NULL REFERENCES "order"(order_id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES product(product_id),
    quantity int NOT NULL,
    price numeric(7,2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT chk_order_structure_quantity CHECK (quantity BETWEEN 1 AND 99),
    CONSTRAINT chk_order_structure_price CHECK (price > 0 AND price <= 50000)
);

CREATE TABLE payment (
    payment_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    order_id uuid NOT NULL UNIQUE REFERENCES "order"(order_id) ON DELETE CASCADE,
    payment_transaction varchar(80) NOT NULL UNIQUE,
    payment_method payment_method NOT NULL,
    amount numeric(9,2) NOT NULL,
    status payment_status NOT NULL,
    created_at timestamp NOT NULL,
    paid_at timestamp,
    CONSTRAINT chk_payment_transaction CHECK (length(trim(payment_transaction)) BETWEEN 10 AND 80),
    CONSTRAINT chk_payment_amount CHECK (amount > 0 AND amount <= 9999999.99),
    CONSTRAINT chk_payment_paid_at CHECK (paid_at IS NULL OR paid_at >= created_at)
);

CREATE TABLE review (
    review_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    client_id uuid NOT NULL REFERENCES client(client_id) ON DELETE CASCADE,
    review_timestamp timestamp NOT NULL,
    entity_id uuid NOT NULL,
    entity_type review_entity_type NOT NULL,
    order_id uuid NOT NULL REFERENCES "order"(order_id) ON DELETE CASCADE,
    description varchar(500) NOT NULL,
    photo_url varchar(200) NOT NULL,
    rating numeric(2,1) NOT NULL,
    CONSTRAINT chk_review_description CHECK (length(trim(description)) BETWEEN 1 AND 500),
    CONSTRAINT chk_review_photo CHECK (length(trim(photo_url)) BETWEEN 1 AND 200),
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_client_address_address ON client_address(address_id);
CREATE INDEX idx_order_client ON "order"(client_id);
CREATE INDEX idx_order_courier ON "order"(courier_id);
CREATE INDEX idx_order_restaurant ON "order"(restaurant_id);
CREATE INDEX idx_order_timestamp ON "order"(order_timestamp);
CREATE INDEX idx_order_status ON "order"(status);
CREATE INDEX idx_product_restaurant ON product(restaurant_id);
CREATE INDEX idx_review_entity ON review(entity_type, entity_id);
CREATE INDEX idx_payment_status ON payment(status);

-- ============================================================
-- Процедура add_product()
-- ============================================================

CREATE OR REPLACE PROCEDURE add_product(
    p_product_name varchar,
    p_product_category_id uuid,
    p_price numeric,
    p_restaurant_id uuid,
    p_photo_url varchar,
    p_status product_status,
    p_description varchar
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM product_category WHERE product_category_id = p_product_category_id) THEN
        RAISE EXCEPTION 'Категория не найдена: %', p_product_category_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM restaurant WHERE restaurant_id = p_restaurant_id) THEN
        RAISE EXCEPTION 'Ресторан не найден: %', p_restaurant_id;
    END IF;

    INSERT INTO product (
        product_id,
        product_name,
        product_category_id,
        restaurant_id,
        price,
        photo_url,
        rating,
        status,
        description
    )
    VALUES (
        exts.uuid_generate_v4(),
        p_product_name,
        p_product_category_id,
        p_restaurant_id,
        p_price,
        p_photo_url,
        0,
        p_status,
        p_description
    );
END;
$$;

-- ============================================================
-- rating_change(): один триггер, без вспомогательной декомпозиции
-- ============================================================

CREATE OR REPLACE FUNCTION rating_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_entity_id uuid;
    v_old_entity_type review_entity_type;
    v_new_entity_id uuid;
    v_new_entity_type review_entity_type;
BEGIN
    -- При DELETE пересчитывается старая сущность.
    -- При UPDATE, если отзыв перенесли на другую сущность/тип, пересчитывается и старая, и новая.
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_old_entity_id := OLD.entity_id;
        v_old_entity_type := OLD.entity_type;

        IF v_old_entity_type = 'restaurant' THEN
            UPDATE restaurant
            SET rating = COALESCE((
                SELECT round(avg(r.rating)::numeric, 2)
                FROM review r
                WHERE r.entity_type = 'restaurant'
                  AND r.entity_id = v_old_entity_id
            ), 0)
            WHERE restaurant_id = v_old_entity_id;
        ELSIF v_old_entity_type = 'product' THEN
            UPDATE product
            SET rating = COALESCE((
                SELECT round(avg(r.rating)::numeric, 2)
                FROM review r
                WHERE r.entity_type = 'product'
                  AND r.entity_id = v_old_entity_id
            ), 0)
            WHERE product_id = v_old_entity_id;
        ELSIF v_old_entity_type = 'order' THEN
            UPDATE "order"
            SET rating = COALESCE((
                SELECT round(avg(r.rating)::numeric, 2)
                FROM review r
                WHERE r.entity_type = 'order'
                  AND r.entity_id = v_old_entity_id
            ), 0)
            WHERE order_id = v_old_entity_id;
        END IF;
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_new_entity_id := NEW.entity_id;
        v_new_entity_type := NEW.entity_type;

        -- Если UPDATE не менял сущность/тип, рейтинг уже пересчитан выше, второй раз не пересчитываем.
        IF TG_OP = 'INSERT'
           OR v_new_entity_id IS DISTINCT FROM OLD.entity_id
           OR v_new_entity_type IS DISTINCT FROM OLD.entity_type THEN

            IF v_new_entity_type = 'restaurant' THEN
                UPDATE restaurant
                SET rating = COALESCE((
                    SELECT round(avg(r.rating)::numeric, 2)
                    FROM review r
                    WHERE r.entity_type = 'restaurant'
                      AND r.entity_id = v_new_entity_id
                ), 0)
                WHERE restaurant_id = v_new_entity_id;
            ELSIF v_new_entity_type = 'product' THEN
                UPDATE product
                SET rating = COALESCE((
                    SELECT round(avg(r.rating)::numeric, 2)
                    FROM review r
                    WHERE r.entity_type = 'product'
                      AND r.entity_id = v_new_entity_id
                ), 0)
                WHERE product_id = v_new_entity_id;
            ELSIF v_new_entity_type = 'order' THEN
                UPDATE "order"
                SET rating = COALESCE((
                    SELECT round(avg(r.rating)::numeric, 2)
                    FROM review r
                    WHERE r.entity_type = 'order'
                      AND r.entity_id = v_new_entity_id
                ), 0)
                WHERE order_id = v_new_entity_id;
            END IF;
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_rating_change
AFTER INSERT OR UPDATE OR DELETE ON review
FOR EACH ROW
EXECUTE FUNCTION rating_change();

-- ============================================================
-- erase_test_data(): отдельная процедура очистки тестовых данных
-- insert_test_data() ее НЕ вызывает
-- ============================================================

CREATE OR REPLACE PROCEDURE erase_test_data()
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = varava_food, exts, public
AS $$
BEGIN
    TRUNCATE TABLE
        payment,
        review,
        order_structure,
        courier_pay,
        courier_rate,
        "order",
        product,
        product_category,
        restaurant_work_time,
        restaurant,
        restaurant_legal_detail,
        client_address,
        address,
        street,
        city,
        courier,
        client
    CASCADE;
END;
$$;

-- ============================================================
-- insert_test_data(value)
-- Генерация построена по примеру из ТЗ:
-- uuid через uuid-ossp, строки через строку символов, даты за последние 6 месяцев,
-- статусы через enum_range(), связи через SELECT ... ORDER BY random() LIMIT 1.
-- Процедура НЕ удаляет существующие данные.
-- ============================================================

CREATE OR REPLACE PROCEDURE insert_test_data(value int)
LANGUAGE plpgsql
AS $$
DECLARE
    str text := 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
    i int;
    j int;
    v_city_id uuid;
    v_street_id uuid;
    v_address_id uuid;
    v_client_id uuid;
    v_courier_id uuid;
    v_restaurant_id uuid;
    v_restaurant_legal_detail_id uuid;
    v_order_id uuid;
    v_product_id uuid;
    v_entity_id uuid;
    v_order_amount numeric(9,2);
    v_order_timestamp timestamp;
    v_delivery_timestamp timestamp;
    v_status order_status;
    v_pay_status pay_status;
    v_payment_status payment_status;
    v_entity_type review_entity_type;
    v_product_count int;
    v_word varchar(120);
BEGIN
    IF value IS NULL OR value <= 0 THEN
        RAISE EXCEPTION 'value должен быть положительным целым числом';
    END IF;

    -- value строк: клиенты, курьеры, категории, рестораны
    FOR i IN 1..value LOOP
        v_word := left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 80);

        INSERT INTO city (city_id, city_name)
        VALUES (exts.uuid_generate_v4(), left(v_word || i::text, 80))
        RETURNING city_id INTO v_city_id;

        INSERT INTO street (street_id, city_id, street_name)
        VALUES (
            exts.uuid_generate_v4(),
            v_city_id,
            left(left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 80) || i::text, 100)
        )
        RETURNING street_id INTO v_street_id;

        INSERT INTO address (address_id, street_id, house_number, building, apartment_office)
        VALUES (
            exts.uuid_generate_v4(),
            v_street_id,
            ceil(random() * 200)::text,
            ceil(random() * 5)::text,
            ceil(random() * 300)::text
        )
        RETURNING address_id INTO v_address_id;

        INSERT INTO client (
            client_id,
            login,
            password_hash,
            first_name,
            last_name,
            middle_name,
            phone_number,
            email,
            created_at
        )
        VALUES (
            exts.uuid_generate_v4(),
            'user' || floor(random() * 100000000)::text || i::text,
            md5(exts.uuid_generate_v4()::text),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 2)::int), 50),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 2)::int), 50),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 2)::int), 50),
            ('+7' || lpad(nextval('test_unique_number_seq')::text, 10, '0'))::char(12),
            'user' || floor(random() * 100000000)::text || i::text || '@example.com',
            current_timestamp - (random() * 262800)::int * interval '1 min'
        )
        RETURNING client_id INTO v_client_id;

        INSERT INTO client_address (client_id, address_id, is_default)
        VALUES (v_client_id, v_address_id, true);

        INSERT INTO courier (
            courier_id,
            first_name,
            last_name,
            middle_name,
            phone_number,
            status,
            hire_date,
            dismissal_date
        )
        VALUES (
            exts.uuid_generate_v4(),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 2)::int), 50),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 2)::int), 50),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 2)::int), 50),
            ('+7' || lpad(nextval('test_unique_number_seq')::text, 10, '0'))::char(12),
            'active',
            current_date - (random() * 180)::int,
            NULL
        )
        RETURNING courier_id INTO v_courier_id;

        INSERT INTO courier_rate (courier_id, year, month, percent_rate)
        VALUES (
            v_courier_id,
            extract(year from current_date)::int,
            extract(month from current_date)::int,
            0.05
        );

        INSERT INTO restaurant_legal_detail (restaurant_legal_detail_id, legal_name, inn)
        VALUES (
            exts.uuid_generate_v4(),
            left(left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 110) || i::text, 120),
            lpad(nextval('test_unique_number_seq')::text, 10, '0')
        )
        RETURNING restaurant_legal_detail_id INTO v_restaurant_legal_detail_id;

        INSERT INTO restaurant (
            restaurant_id,
            restaurant_name,
            address_id,
            restaurant_legal_detail_id,
            phone_number,
            description,
            rating,
            status
        )
        VALUES (
            exts.uuid_generate_v4(),
            left(left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 90) || i::text, 100),
            v_address_id,
            v_restaurant_legal_detail_id,
            ('+7' || lpad(nextval('test_unique_number_seq')::text, 10, '0'))::char(12),
            repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 8)::int),
            0,
            (enum_range(NULL::restaurant_status))[ceil(random() * cardinality(enum_range(NULL::restaurant_status)))]
        )
        RETURNING restaurant_id INTO v_restaurant_id;

        FOR j IN 1..7 LOOP
            INSERT INTO restaurant_work_time (restaurant_id, week_day, open_time, close_time)
            VALUES (
                v_restaurant_id,
                j,
                ((ceil(random() * 5 + 5))::int::text || ':00')::time,
                ((ceil(random() * 5 + 17))::int::text || ':00')::time
            );
        END LOOP;

        INSERT INTO product_category (product_category_id, product_category_name)
        VALUES (
            exts.uuid_generate_v4(),
            left(left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 70) || i::text, 80)
        );
    END LOOP;

    -- value * 5 строк: дополнительные адреса, продукты, заказы, платежи, отзывы
    FOR i IN 1..(value * 5) LOOP
        INSERT INTO street (street_id, city_id, street_name)
        VALUES (
            exts.uuid_generate_v4(),
            (SELECT city_id FROM city ORDER BY random() LIMIT 1),
            left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 80) || (value + i)::text
        )
        RETURNING street_id INTO v_street_id;

        INSERT INTO address (address_id, street_id, house_number, building, apartment_office)
        VALUES (
            exts.uuid_generate_v4(),
            v_street_id,
            ceil(random() * 200)::text,
            ceil(random() * 5)::text,
            ceil(random() * 300)::text
        )
        RETURNING address_id INTO v_address_id;

        INSERT INTO product (
            product_id,
            product_name,
            product_category_id,
            restaurant_id,
            price,
            photo_url,
            rating,
            status,
            description
        )
        VALUES (
            exts.uuid_generate_v4(),
            left(left(repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 3)::int), 90) || i::text, 100),
            (SELECT product_category_id FROM product_category ORDER BY random() LIMIT 1),
            (SELECT restaurant_id FROM restaurant ORDER BY random() LIMIT 1),
            (random() * 4900 + 100)::numeric(7,2),
            'https://example.com/' || floor(random() * 100000000)::text || '.jpg',
            0,
            (enum_range(NULL::product_status))[ceil(random() * cardinality(enum_range(NULL::product_status)))],
            repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 8)::int)
        );
    END LOOP;

    FOR i IN 1..(value * 5) LOOP
        SELECT restaurant_id INTO v_restaurant_id
        FROM restaurant
        WHERE EXISTS (
            SELECT 1 FROM product
            WHERE product.restaurant_id = restaurant.restaurant_id
              AND product.status = 'available'
        )
        ORDER BY random()
        LIMIT 1;

        IF v_restaurant_id IS NULL THEN
            SELECT restaurant_id INTO v_restaurant_id FROM restaurant ORDER BY random() LIMIT 1;
        END IF;

        SELECT client_id INTO v_client_id FROM client ORDER BY random() LIMIT 1;
        SELECT courier_id INTO v_courier_id FROM courier WHERE status = 'active' ORDER BY random() LIMIT 1;
        SELECT address_id INTO v_address_id FROM client_address WHERE client_id = v_client_id ORDER BY random() LIMIT 1;

        IF i <= value THEN
            -- Часть заказов специально попадает в текущий расчетный месяц,
            -- чтобы courier_salary() можно было сразу протестировать после insert_test_data(value).
            v_order_timestamp := date_trunc('month', current_timestamp)
                                 + (random() * GREATEST(extract(epoch FROM (current_timestamp - date_trunc('month', current_timestamp))), 3600))::int * interval '1 second';
            v_status := 'delivered';
        ELSE
            v_order_timestamp := current_timestamp - (random() * 262800)::int * interval '1 min';
            v_status := (enum_range(NULL::order_status))[ceil(random() * cardinality(enum_range(NULL::order_status)))];
        END IF;

        IF v_status = 'delivered' THEN
            v_pay_status := 'paid';
            v_payment_status := 'success';
            v_delivery_timestamp := v_order_timestamp + (ceil(random() * 90)::int + 20) * interval '1 min';
        ELSIF v_status = 'cancelled' THEN
            v_pay_status := 'refunded';
            v_payment_status := 'refunded';
            v_delivery_timestamp := NULL;
        ELSE
            v_pay_status := 'not_paid';
            v_payment_status := 'created';
            v_delivery_timestamp := NULL;
        END IF;

        INSERT INTO "order" (
            order_id,
            courier_id,
            client_id,
            address_id,
            restaurant_id,
            order_timestamp,
            delivery_timestamp,
            order_amount,
            commission,
            total_amount,
            rating,
            status,
            pay_status,
            description
        )
        VALUES (
            exts.uuid_generate_v4(),
            v_courier_id,
            v_client_id,
            v_address_id,
            v_restaurant_id,
            v_order_timestamp,
            v_delivery_timestamp,
            0,
            0,
            0,
            0,
            v_status,
            v_pay_status,
            repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 8)::int)
        )
        RETURNING order_id INTO v_order_id;

        v_product_count := ceil(random() * 3)::int;

        INSERT INTO order_structure (order_id, product_id, quantity, price)
        SELECT
            v_order_id,
            p.product_id,
            ceil(random() * 5)::int,
            p.price
        FROM product p
        WHERE p.restaurant_id = v_restaurant_id
          AND p.status = 'available'
        ORDER BY random()
        LIMIT v_product_count;

        IF NOT EXISTS (SELECT 1 FROM order_structure WHERE order_id = v_order_id) THEN
            INSERT INTO order_structure (order_id, product_id, quantity, price)
            SELECT v_order_id, p.product_id, ceil(random() * 5)::int, p.price
            FROM product p
            WHERE p.restaurant_id = v_restaurant_id
            ORDER BY random()
            LIMIT 1;
        END IF;

        SELECT sum(quantity * price)::numeric(9,2)
        INTO v_order_amount
        FROM order_structure
        WHERE order_id = v_order_id;

        UPDATE "order"
        SET
            order_amount = v_order_amount,
            commission = (v_order_amount * 0.10)::numeric(9,2),
            total_amount = (v_order_amount * 1.10)::numeric(9,2)
        WHERE order_id = v_order_id;

        INSERT INTO payment (
            payment_id,
            order_id,
            payment_transaction,
            payment_method,
            amount,
            status,
            created_at,
            paid_at
        )
        VALUES (
            exts.uuid_generate_v4(),
            v_order_id,
            md5(exts.uuid_generate_v4()::text),
            (enum_range(NULL::payment_method))[ceil(random() * cardinality(enum_range(NULL::payment_method)))],
            (SELECT total_amount FROM "order" WHERE order_id = v_order_id),
            v_payment_status,
            (SELECT order_timestamp FROM "order" WHERE order_id = v_order_id),
            CASE WHEN v_payment_status IN ('success', 'refunded')
                 THEN (SELECT order_timestamp FROM "order" WHERE order_id = v_order_id) + interval '1 minute'
                 ELSE NULL
            END
        );

        v_entity_type := (enum_range(NULL::review_entity_type))[ceil(random() * cardinality(enum_range(NULL::review_entity_type)))];

        IF v_entity_type = 'restaurant' THEN
            v_entity_id := v_restaurant_id;
        ELSIF v_entity_type = 'product' THEN
            SELECT product_id INTO v_entity_id
            FROM order_structure
            WHERE order_id = v_order_id
            ORDER BY random()
            LIMIT 1;
        ELSE
            v_entity_id := v_order_id;
        END IF;

        INSERT INTO review (
            review_id,
            client_id,
            review_timestamp,
            entity_id,
            entity_type,
            order_id,
            description,
            photo_url,
            rating
        )
        VALUES (
            exts.uuid_generate_v4(),
            v_client_id,
            current_timestamp - (random() * 262800)::int * interval '1 min',
            v_entity_id,
            v_entity_type,
            v_order_id,
            repeat(substring(str, 1, ceil(random() * 33)::int), ceil(random() * 8)::int),
            'https://example.com/' || floor(random() * 100000000)::text || '.jpg',
            ceil(random() * 5)::numeric(2,1)
        );
    END LOOP;
END;
$$;

-- ============================================================
-- courier_salary()
-- Бизнес-логика: расчет оплаты за текущий месяц по ставке текущего месяца
-- и назначение ставки на следующий месяц по количеству доставленных заказов.
-- ============================================================

CREATE OR REPLACE PROCEDURE courier_salary(
    p_year int DEFAULT extract(year from current_date)::int,
    p_month int DEFAULT extract(month from current_date)::int
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_month_start date := make_date(p_year, p_month, 1);
    next_month_start date := (make_date(p_year, p_month, 1) + interval '1 month')::date;
BEGIN
    IF p_year IS NULL OR p_year NOT BETWEEN 2020 AND 2100 THEN
        RAISE EXCEPTION 'Некорректный год: %', p_year;
    END IF;

    IF p_month IS NULL OR p_month NOT BETWEEN 1 AND 12 THEN
        RAISE EXCEPTION 'Некорректный месяц: %', p_month;
    END IF;
    -- 1. Если у активного курьера ещё нет ставки на расчётный месяц,
    -- создаём базовую ставку 5%. Существующую ставку не перезаписываем,
    -- потому что она могла быть назначена предыдущим запуском процедуры.
    INSERT INTO courier_rate (courier_id, year, month, percent_rate)
    SELECT
        c.courier_id,
        extract(year from current_month_start)::int,
        extract(month from current_month_start)::int,
        0.05
    FROM courier c
    WHERE c.status = 'active'
    ON CONFLICT (courier_id, year, month) DO NOTHING;

    -- 2. Рассчитываем выплаты за расчётный месяц.
    -- Важно: при повторном запуске процедура НЕ должна создавать дубль и
    -- НЕ должна оставлять старую сумму. Поэтому используется UPSERT.
    INSERT INTO courier_pay (year, month, courier_id, amount)
    SELECT
        extract(year from current_month_start)::int,
        extract(month from current_month_start)::int,
        c.courier_id,
        (COALESCE(sum(o.order_amount), 0) * cr.percent_rate)::numeric(9,2) AS amount
    FROM courier c
    JOIN courier_rate cr
      ON cr.courier_id = c.courier_id
     AND cr.year = extract(year from current_month_start)::int
     AND cr.month = extract(month from current_month_start)::int
    LEFT JOIN "order" o
      ON o.courier_id = c.courier_id
     AND o.status = 'delivered'
     AND o.delivery_timestamp >= current_month_start
     AND o.delivery_timestamp < next_month_start
    WHERE c.status = 'active'
    GROUP BY c.courier_id, cr.percent_rate
    ON CONFLICT (year, month, courier_id) DO UPDATE
    SET amount = EXCLUDED.amount;

    -- 3. По количеству доставок за расчётный месяц назначаем ставку на следующий месяц.
    -- При повторном запуске ставка на следующий месяц пересчитывается, а не дублируется.
    INSERT INTO courier_rate (courier_id, year, month, percent_rate)
    SELECT
        c.courier_id,
        extract(year from next_month_start)::int,
        extract(month from next_month_start)::int,
        CASE
            WHEN count(o.order_id) BETWEEN 0 AND 100 THEN 0.05
            WHEN count(o.order_id) BETWEEN 101 AND 200 THEN 0.10
            WHEN count(o.order_id) BETWEEN 201 AND 300 THEN 0.20
            WHEN count(o.order_id) BETWEEN 301 AND 400 THEN 0.30
            WHEN count(o.order_id) BETWEEN 401 AND 500 THEN 0.40
            ELSE 0.50
        END AS percent_rate
    FROM courier c
    LEFT JOIN "order" o
      ON o.courier_id = c.courier_id
     AND o.status = 'delivered'
     AND o.delivery_timestamp >= current_month_start
     AND o.delivery_timestamp < next_month_start
    WHERE c.status = 'active'
    GROUP BY c.courier_id
    ON CONFLICT (courier_id, year, month) DO UPDATE
    SET percent_rate = EXCLUDED.percent_rate;
END;
$$;

-- ============================================================
-- get_statistic()
-- Группировка выполняется по uuid ресторанов и клиентов, не по неуникальным названиям.
-- ============================================================

CREATE OR REPLACE FUNCTION get_statistic()
RETURNS TABLE (
    restaurant_name varchar,
    best_product_name varchar,
    total_amount numeric,
    avg_amount numeric,
    best_user varchar
)
LANGUAGE sql
AS $$
    WITH product_stat AS (
        SELECT
            r.restaurant_id,
            p.product_id,
            p.product_name,
            sum(os.quantity) AS quantity_sum,
            row_number() OVER (
                PARTITION BY r.restaurant_id
                ORDER BY sum(os.quantity) DESC, random()
            ) AS rn
        FROM restaurant r
        JOIN product p ON p.restaurant_id = r.restaurant_id
        JOIN order_structure os ON os.product_id = p.product_id
        JOIN "order" o ON o.order_id = os.order_id
        WHERE o.status = 'delivered'
        GROUP BY r.restaurant_id, p.product_id, p.product_name
    ),
    user_stat AS (
        SELECT
            o.restaurant_id,
            c.client_id,
            concat_ws(' ', c.last_name, c.first_name, c.middle_name)::varchar AS fio,
            count(o.order_id) AS order_count,
            row_number() OVER (
                PARTITION BY o.restaurant_id
                ORDER BY count(o.order_id) DESC, random()
            ) AS rn
        FROM "order" o
        JOIN client c ON c.client_id = o.client_id
        WHERE o.status = 'delivered'
        GROUP BY o.restaurant_id, c.client_id, c.last_name, c.first_name, c.middle_name
    ),
    order_stat AS (
        SELECT
            o.restaurant_id,
            sum(o.total_amount)::numeric(12,2) AS total_amount,
            avg(o.total_amount)::numeric(12,2) AS avg_amount
        FROM "order" o
        WHERE o.status = 'delivered'
        GROUP BY o.restaurant_id
    )
    SELECT
        r.restaurant_name::varchar,
        COALESCE(ps.product_name, '')::varchar AS best_product_name,
        COALESCE(os.total_amount, 0)::numeric AS total_amount,
        COALESCE(os.avg_amount, 0)::numeric AS avg_amount,
        COALESCE(us.fio, '')::varchar AS best_user
    FROM restaurant r
    LEFT JOIN product_stat ps ON ps.restaurant_id = r.restaurant_id AND ps.rn = 1
    LEFT JOIN user_stat us ON us.restaurant_id = r.restaurant_id AND us.rn = 1
    LEFT JOIN order_stat os ON os.restaurant_id = r.restaurant_id
    ORDER BY r.restaurant_name;
$$;

-- ============================================================
-- how_much_money
-- Формат колонок соответствует таблице из ТЗ.
-- ============================================================

CREATE OR REPLACE VIEW how_much_money AS
WITH RECURSIVE month_list(month_start) AS (
    SELECT date_trunc('month', COALESCE(min(order_timestamp), current_date))::date
    FROM "order"
    UNION ALL
    SELECT (month_start + interval '1 month')::date
    FROM month_list
    WHERE month_start < date_trunc('month', current_date)::date
),
order_month AS (
    SELECT
        date_trunc('month', order_timestamp)::date AS month_start,
        sum(order_amount)::numeric(12,2) AS amount_without_commission,
        sum(total_amount)::numeric(12,2) AS amount_with_commission,
        sum(commission)::numeric(12,2) AS commission_amount
    FROM "order"
    WHERE status = 'delivered'
    GROUP BY date_trunc('month', order_timestamp)::date
),
pay_month AS (
    SELECT
        make_date(year, month, 1) AS month_start,
        sum(amount)::numeric(12,2) AS courier_pay_amount
    FROM courier_pay
    GROUP BY make_date(year, month, 1)
),
report AS (
    SELECT
        ml.month_start,
        COALESCE(om.amount_without_commission, 0)::numeric(12,2) AS amount_without_commission,
        COALESCE(om.amount_with_commission, 0)::numeric(12,2) AS amount_with_commission,
        COALESCE(om.commission_amount, 0)::numeric(12,2) AS commission_amount,
        COALESCE(pm.courier_pay_amount, 0)::numeric(12,2) AS courier_pay_amount
    FROM month_list ml
    LEFT JOIN order_month om ON om.month_start = ml.month_start
    LEFT JOIN pay_month pm ON pm.month_start = ml.month_start
)
SELECT
    to_char(month_start, 'YYYY-MM') AS "год_месяц",
    amount_without_commission AS "сумма_за_месяц_без_комиссии",
    amount_with_commission AS "сумма_за_месяц_с_комиссией",
    commission_amount AS "сумма_комиссии",
    lag(commission_amount) OVER (ORDER BY month_start) AS "комиссия_пред_месяца",
    commission_amount - COALESCE(lag(commission_amount) OVER (ORDER BY month_start), 0) AS "разница_комиссии",
    courier_pay_amount AS "размер_оплаты_курьерам",
    commission_amount - courier_pay_amount AS "чистая_прибыль"
FROM report
ORDER BY month_start;

-- ============================================================
-- Пользователи и права
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'reviewer') THEN
        CREATE USER reviewer WITH PASSWORD 'NetoSQL2026';
    ELSE
        ALTER USER reviewer WITH PASSWORD 'NetoSQL2026';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'inspector') THEN
        CREATE USER inspector WITH PASSWORD 'NetoSQL2026';
    ELSE
        ALTER USER inspector WITH PASSWORD 'NetoSQL2026';
    END IF;
END;
$$;

GRANT USAGE ON SCHEMA varava_food TO reviewer, inspector;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA varava_food TO reviewer, inspector;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA varava_food TO reviewer, inspector;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA varava_food TO reviewer, inspector;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA varava_food TO reviewer, inspector;

GRANT USAGE ON SCHEMA exts TO reviewer, inspector;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA exts TO reviewer, inspector;

GRANT USAGE ON SCHEMA information_schema TO reviewer, inspector;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO reviewer, inspector;
GRANT USAGE ON SCHEMA pg_catalog TO reviewer, inspector;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO reviewer, inspector;

ALTER DEFAULT PRIVILEGES IN SCHEMA varava_food
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON TABLES TO reviewer, inspector;

ALTER DEFAULT PRIVILEGES IN SCHEMA varava_food
GRANT EXECUTE ON FUNCTIONS TO reviewer, inspector;

ALTER ROLE reviewer SET search_path = varava_food, exts, public;
ALTER ROLE inspector SET search_path = varava_food, exts, public;


