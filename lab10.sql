-- Lab 10: SQL Transactions and Isolation Levels
-- Setup

DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
    id      SERIAL PRIMARY KEY,
    shop    VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price   DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob',   500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke',  2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

-- 3.2 Task 1: Basic transaction with COMMIT

BEGIN;

UPDATE accounts
SET balance = balance - 100.00
WHERE name = 'Alice';

UPDATE accounts
SET balance = balance + 100.00
WHERE name = 'Bob';

COMMIT;

SELECT * FROM accounts;

-- 3.3 Task 2: Using ROLLBACK

SELECT * FROM accounts WHERE name = 'Alice';

BEGIN;

UPDATE accounts
SET balance = balance - 500.00
WHERE name = 'Alice';

SELECT * FROM accounts WHERE name = 'Alice';

ROLLBACK;

SELECT * FROM accounts WHERE name = 'Alice';

-- 3.4 Task 3: Working with SAVEPOINTs

BEGIN;

UPDATE accounts
SET balance = balance - 100.00
WHERE name = 'Alice';

SAVEPOINT my_savepoint;

UPDATE accounts
SET balance = balance + 100.00
WHERE name = 'Bob';

ROLLBACK TO my_savepoint;

UPDATE accounts
SET balance = balance + 100.00
WHERE name = 'Wally';

COMMIT;

SELECT * FROM accounts;

-- 3.5 Task 4: Isolation level demonstration

-- Scenario A: READ COMMITTED
-- Terminal 1

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT * FROM products WHERE shop = 'Joe''s Shop';

-- (run Terminal 2 below, then again:)

SELECT * FROM products WHERE shop = 'Joe''s Shop';

COMMIT;

-- Terminal 2

BEGIN;

DELETE FROM products WHERE shop = 'Joe''s Shop';

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);

COMMIT;

-- Scenario B: SERIALIZABLE
-- Terminal 1

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT * FROM products WHERE shop = 'Joe''s Shop';

-- (run Terminal 2 again)

SELECT * FROM products WHERE shop = 'Joe''s Shop';

COMMIT;

-- Terminal 2

BEGIN;

DELETE FROM products WHERE shop = 'Joe''s Shop';

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);

COMMIT;

-- 3.6 Task 5: Phantom read demonstration (REPEATABLE READ)

-- Terminal 1

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT MAX(price), MIN(price)
FROM products
WHERE shop = 'Joe''s Shop';

-- (run Terminal 2)

SELECT MAX(price), MIN(price)
FROM products
WHERE shop = 'Joe''s Shop';

COMMIT;

-- Terminal 2

BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);

COMMIT;

-- 3.7 Task 6: Dirty read demonstration (READ UNCOMMITTED)

-- Terminal 1

BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT * FROM products WHERE shop = 'Joe''s Shop';

-- (run Terminal 2 UPDATE, but do not commit yet)

SELECT * FROM products WHERE shop = 'Joe''s Shop';

-- (run Terminal 2 ROLLBACK)

SELECT * FROM products WHERE shop = 'Joe''s Shop';

COMMIT;

-- Terminal 2

BEGIN;

UPDATE products
SET price = 99.99
WHERE product = 'Fanta';

-- (wait here)

ROLLBACK;

-- Independent Exercise 1: transfer with error handling

DROP FUNCTION IF EXISTS transfer_if_enough(text, text, numeric);

CREATE OR REPLACE FUNCTION transfer_if_enough(
    p_from   text,
    p_to     text,
    p_amount numeric
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance numeric;
BEGIN
    SELECT balance
    INTO v_balance
    FROM accounts
    WHERE name = p_from
    FOR UPDATE;

    IF v_balance IS NULL THEN
        RAISE EXCEPTION 'Account % not found', p_from;
    END IF;

    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds on %, balance=%, needed=%',
            p_from, v_balance, p_amount;
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE name = p_from;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE name = p_to;
END;
$$;

BEGIN;

SELECT transfer_if_enough('Bob', 'Wally', 200.00);

COMMIT;

SELECT * FROM accounts;

-- Independent Exercise 2: transaction with multiple savepoints

BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'DemoProduct', 10.00);

SAVEPOINT sp_insert;

UPDATE products
SET price = 12.00
WHERE shop = 'Joe''s Shop' AND product = 'DemoProduct';

SAVEPOINT sp_update;

DELETE FROM products
WHERE shop = 'Joe''s Shop' AND product = 'DemoProduct';

ROLLBACK TO sp_insert;

COMMIT;

SELECT * FROM products WHERE product = 'DemoProduct';

-- Independent Exercise 3: concurrent withdrawals

UPDATE accounts SET balance = 1000.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';

-- READ COMMITTED example (two terminals)
-- Terminal 1

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT balance FROM accounts WHERE name = 'Alice';

UPDATE accounts
SET balance = balance - 600
WHERE name = 'Alice';

-- (wait, then COMMIT)

COMMIT;

SELECT * FROM accounts WHERE name = 'Alice';

-- Terminal 2

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT balance FROM accounts WHERE name = 'Alice';

UPDATE accounts
SET balance = balance - 600
WHERE name = 'Alice';

COMMIT;

SELECT * FROM accounts WHERE name = 'Alice';

-- Independent Exercise 4: Sells(shop, product, price)

DROP TABLE IF EXISTS sells;

CREATE TABLE sells (
    shop    VARCHAR(100),
    product VARCHAR(100),
    price   DECIMAL(10, 2)
);

INSERT INTO sells (shop, product, price) VALUES
    ('Joe''s Shop', 'Tea',    2.00),
    ('Joe''s Shop', 'Coffee', 3.00),
    ('Joe''s Shop', 'Cake',   4.00);

-- Bad scenario (no transactions)
-- Sally, Terminal 1

SELECT MAX(price) AS max_price
FROM sells
WHERE shop = 'Joe''s Shop';

-- Joe, Terminal 2

BEGIN;

UPDATE sells
SET price = price + 5.00
WHERE shop = 'Joe''s Shop';

COMMIT;

-- Sally again

SELECT MIN(price) AS min_price
FROM sells
WHERE shop = 'Joe''s Shop';

-- Fixed scenario (Sally uses one transaction)

BEGIN;

SELECT MAX(price) AS max_price
FROM sells
WHERE shop = 'Joe''s Shop';

SELECT MIN(price) AS min_price
FROM sells
WHERE shop = 'Joe''s Shop';

COMMIT;
