CREATE OR REPLACE FUNCTION magical_transfer(
    from_account_number VARCHAR,
    to_account_number VARCHAR,
    amount NUMERIC,
    currency CHAR(3),
    description TEXT
)
RETURNS VOID AS $$
DECLARE
    from_balance NUMERIC;
    to_balance NUMERIC;
    daily_limit NUMERIC;
    daily_total NUMERIC;
    exchange_rate NUMERIC;
    current_date DATE := CURRENT_DATE;
BEGIN
    BEGIN
        SELECT balance INTO from_balance 
        FROM accounts 
        WHERE account_number = from_account_number 
        FOR UPDATE;

        SELECT balance INTO to_balance 
        FROM accounts 
        WHERE account_number = to_account_number 
        FOR UPDATE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Magical incantation failed when locking accounts: %', SQLERRM;
    END;

    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_number = from_account_number AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Sender account % is not activated for magic', from_account_number;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_number = to_account_number AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Receiver account % is not activated for magic', to_account_number;
    END IF;

    SELECT COALESCE(SUM(amount), 0) INTO daily_total
    FROM transactions
    WHERE from_account_number = from_account_number
    AND DATE(created_at) = current_date;

    SELECT daily_limit_kzt INTO daily_limit
    FROM accounts
    WHERE account_number = from_account_number;

    IF daily_total + amount > daily_limit THEN
        RAISE EXCEPTION 'Magical limit exceeded! Current total: %, Limit: %', daily_total, daily_limit;
    END IF;

    IF currency != 'KZT' THEN
        SELECT rate INTO exchange_rate
        FROM exchange_rates
        WHERE from_currency = currency AND to_currency = 'KZT' AND valid_from <= current_date AND valid_to > current_date
        ORDER BY valid_from DESC LIMIT 1;

        IF exchange_rate IS NULL THEN
            RAISE EXCEPTION 'Unable to find the magical exchange rate for % to KZT', currency;
        END IF;

        amount := amount * exchange_rate;
    END IF;

    IF from_balance < amount THEN
        RAISE EXCEPTION 'Not enough magic in sender account %: Available: %, Required: %', from_account_number, from_balance, amount;
    END IF;

    SAVEPOINT magic_transfer_point;

    UPDATE accounts SET balance = from_balance - amount WHERE account_number = from_account_number;
    UPDATE accounts SET balance = to_balance + amount WHERE account_number = to_account_number;

    INSERT INTO audit_log (table_name, record_id, action, new_values)
    VALUES ('transactions', nextval('transaction_id_seq'), 'INSERT', jsonb_build_object('from_account', from_account_number, 'to_account', to_account_number, 'amount', amount, 'description', description));

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT magic_transfer_point;
        RAISE EXCEPTION 'Magical transfer failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;





CREATE VIEW customer_balance_summary AS
SELECT a.customer_id, 
       SUM(a.balance) AS total_balance,
       SUM(CASE 
               WHEN a.currency != 'KZT' THEN a.balance * er.rate
               ELSE a.balance 
           END) AS total_balance_kzt
FROM accounts a
LEFT JOIN exchange_rates er ON a.currency = er.from_currency AND er.to_currency = 'KZT'
GROUP BY a.customer_id;

CREATE VIEW daily_transaction_report AS
SELECT t.transaction_date, 
       t.transaction_type, 
       COUNT(t.transaction_id) AS total_transactions,
       SUM(t.amount) AS total_volume,
       AVG(t.amount) AS avg_amount,
       MAX(t.transaction_date) OVER (PARTITION BY t.transaction_date ORDER BY t.amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS peak_time
FROM transactions t
GROUP BY t.transaction_date, t.transaction_type;

CREATE VIEW suspicious_activity_view SECURITY BARRIER AS
SELECT t.transaction_id,
       t.from_account_number,
       t.to_account_number,
       t.amount,
       t.transaction_date,
       CASE 
           WHEN t.amount > 5000000 THEN 'Suspicious - Large Amount'
           WHEN EXISTS (SELECT 1 FROM transactions t2 
                        WHERE t2.from_account_number = t.from_account_number 
                        AND t2.transaction_date BETWEEN t.transaction_date - INTERVAL '1 hour' AND t.transaction_date 
                        HAVING COUNT(*) > 10) THEN 'Suspicious - Rapid Transactions'
           ELSE 'Normal Magic'
       END AS activity_status
FROM transactions t;


CREATE INDEX idx_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_from_account_number ON transactions(from_account_number);
CREATE INDEX idx_to_account_number ON transactions(to_account_number);
CREATE INDEX idx_transaction_type ON transactions(transaction_type);





CREATE INDEX idx_balance ON accounts(balance);


CREATE INDEX idx_currency_hash ON accounts USING HASH(currency);


CREATE INDEX idx_audit_log_changes ON audit_log USING GIN (new_values);


CREATE INDEX idx_active_accounts ON accounts(account_number) WHERE is_active = TRUE;



CREATE INDEX idx_email_lowercase ON accounts (LOWER(email));


CREATE INDEX idx_account_transaction_type ON transactions(from_account_number, transaction_type);


CREATE INDEX idx_transaction_amount_date ON transactions(amount, transaction_date);


CREATE INDEX idx_transaction_date ON transactions(transaction_date);


CREATE INDEX idx_transaction_amount ON transactions(amount);


CREATE INDEX idx_transaction_description ON transactions USING GIN (description gin_trgm_ops);


CREATE INDEX idx_transaction_status_date ON transactions(transaction_status, transaction_date);


CREATE INDEX idx_suspicious_activity_flag ON transactions(suspicious_activity_flag);


CREATE INDEX idx_transaction_type ON transactions(transaction_type);


CREATE INDEX idx_account_pair ON transactions(from_account_number, to_account_number);


CREATE INDEX idx_transaction_sum ON transactions(amount);


CREATE INDEX idx_recent_transactions ON transactions(transaction_date DESC);


CREATE INDEX idx_customer_latest_transactions ON transactions(from_account_number, transaction_date DESC);

CREATE INDEX idx_active_transactions ON transactions(transaction_status) WHERE transaction_status = 'active';


CREATE INDEX idx_suspicious_activity_on_flag ON transactions(suspicious_activity_flag) WHERE suspicious_activity_flag = 'true';


CREATE INDEX idx_large_amount_and_account ON transactions(amount, from_account_number, to_account_number) WHERE amount > 5000000;


CREATE INDEX idx_transaction_multi_criteria ON transactions(transaction_date, transaction_status, amount);


CREATE INDEX idx_type_and_date ON transactions(transaction_type, transaction_date);


CREATE INDEX idx_transaction_status_update ON transactions(transaction_status);


EXPLAIN ANALYZE 
SELECT * FROM accounts WHERE balance > 10000;

EXPLAIN ANALYZE 
SELECT * FROM transactions WHERE from_account_number = '87012320499' AND transaction_date BETWEEN '2022-01-01' AND '2022-12-31';


CREATE INDEX idx_recent_transactions_period ON transactions(transaction_date DESC) WHERE transaction_date BETWEEN '2022-01-01' AND '2022-12-31';


CREATE INDEX idx_transactions_by_status ON transactions(transaction_status) WHERE transaction_status = 'completed';


CREATE INDEX idx_customer_and_status ON transactions(from_account_number, transaction_status);


CREATE INDEX idx_transaction_type_and_amount ON transactions(transaction_type, amount);


CREATE INDEX idx_transaction_year_month ON transactions(EXTRACT(YEAR FROM transaction_date), EXTRACT(MONTH FROM transaction_date));


CREATE INDEX idx_large_amount_multiple_dates ON transactions(amount, transaction_date) WHERE amount > 5000000;




CREATE OR REPLACE FUNCTION process_salary_batch(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    payment JSONB;
    total_batch_amount NUMERIC := 0;
    successful_count INT := 0;
    failed_count INT := 0;
    failed_details JSONB := '[]'::JSONB;
    company_balance NUMERIC;
    transaction_id BIGINT;
    payment_amount NUMERIC;
BEGIN
    SELECT balance INTO company_balance
    FROM accounts
    WHERE account_number = company_account_number;

    IF company_balance < (SELECT SUM((payment->>'amount')::NUMERIC) FROM jsonb_array_elements(payments) AS payment) THEN
        RAISE EXCEPTION 'The magical energy (balance) of the company is insufficient for all payments';
    END IF;

    FOR payment IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        BEGIN
            SELECT nextval('transaction_id_seq') INTO transaction_id;

            payment_amount := (payment->>'amount')::NUMERIC;

            INSERT INTO transactions (transaction_id, from_account_number, amount, transaction_date, description)
            VALUES (transaction_id, company_account_number, payment_amount, CURRENT_DATE, payment->>'description');

            successful_count := successful_count + 1;

            INSERT INTO transaction_logs (transaction_id, status, log_message)
            VALUES (transaction_id, 'SUCCESS', 'Payment processed successfully for ' || payment->>'description');
        EXCEPTION
            WHEN OTHERS THEN
                failed_count := failed_count + 1;
                failed_details := failed_details || jsonb_build_object('payment', payment, 'error', SQLERRM);
                INSERT INTO transaction_logs (transaction_id, status, log_message)
                VALUES (transaction_id, 'FAILED', 'Payment failed due to error: ' || SQLERRM);
        END;
    END LOOP;

    RETURN jsonb_build_object('successful_count', successful_count, 'failed_count', failed_count, 'failed_details', failed_details);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_batch_total(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    total_batch NUMERIC := 0;
BEGIN
    FOR payment IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        total_batch := total_batch + (payment->>'amount')::NUMERIC;
    END LOOP;

    RETURN (total_batch <= (SELECT balance FROM accounts WHERE account_number = company_account_number));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION log_failed_payment(
    payment JSONB,
    error_message TEXT
)
RETURNS VOID AS $$
DECLARE
    transaction_id BIGINT;
BEGIN
    SELECT nextval('transaction_id_seq') INTO transaction_id;
    INSERT INTO transaction_logs (transaction_id, status, log_message)
    VALUES (transaction_id, 'FAILED', 'Payment failed: ' || error_message || '. Payment Details: ' || payment::TEXT);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_individual_payment(
    company_account_number VARCHAR,
    payment JSONB
)
RETURNS VOID AS $$
DECLARE
    payment_amount NUMERIC := (payment->>'amount')::NUMERIC;
    transaction_id BIGINT;
BEGIN
    SELECT nextval('transaction_id_seq') INTO transaction_id;

    IF NOT validate_batch_total(company_account_number, payment) THEN
        RAISE EXCEPTION 'Insufficient balance for this payment.';
    END IF;

    INSERT INTO transactions (transaction_id, from_account_number, amount, transaction_date, description)
    VALUES (transaction_id, company_account_number, payment_amount, CURRENT_DATE, payment->>'description');

    INSERT INTO transaction_logs (transaction_id, status, log_message)
    VALUES (transaction_id, 'SUCCESS', 'Payment processed successfully for ' || payment->>'description');
EXCEPTION
    WHEN OTHERS THEN
        PERFORM log_failed_payment(payment, SQLERRM);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_batch(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS VOID AS $$
DECLARE
    payment JSONB;
BEGIN
    FOR payment IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        PERFORM process_individual_payment(company_account_number, payment);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_salary_batch_v2(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    payment JSONB;
    total_batch_amount NUMERIC := 0;
    successful_count INT := 0;
    failed_count INT := 0;
    failed_details JSONB := '[]'::JSONB;
    company_balance NUMERIC;
    transaction_id BIGINT;
    payment_amount NUMERIC;
BEGIN
    SELECT balance INTO company_balance
    FROM accounts
    WHERE account_number = company_account_number;

    IF company_balance < (SELECT SUM((payment->>'amount')::NUMERIC) FROM jsonb_array_elements(payments) AS payment) THEN
        RAISE EXCEPTION 'The magical energy (balance) of the company is insufficient for all payments';
    END IF;

    FOR payment IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        BEGIN
            SELECT nextval('transaction_id_seq') INTO transaction_id;

            payment_amount := (payment->>'amount')::NUMERIC;

            INSERT INTO transactions (transaction_id, from_account_number, amount, transaction_date, description)
            VALUES (transaction_id, company_account_number, payment_amount, CURRENT_DATE, payment->>'description');

            successful_count := successful_count + 1;

            INSERT INTO transaction_logs (transaction_id, status, log_message)
            VALUES (transaction_id, 'SUCCESS', 'Payment processed successfully for ' || payment->>'description');
        EXCEPTION
            WHEN OTHERS THEN
                failed_count := failed_count + 1;
                failed_details := failed_details || jsonb_build_object('payment', payment, 'error', SQLERRM);
                INSERT INTO transaction_logs (transaction_id, status, log_message)
                VALUES (transaction_id, 'FAILED', 'Payment failed due to error: ' || SQLERRM);
        END;
    END LOOP;

    RETURN jsonb_build_object('successful_count', successful_count, 'failed_count', failed_count, 'failed_details', failed_details);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_batch_v2(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    payment JSONB;
    total_batch_amount NUMERIC := 0;
    successful_count INT := 0;
    failed_count INT := 0;
    failed_details JSONB := '[]'::JSONB;
    company_balance NUMERIC;
BEGIN
    SELECT balance INTO company_balance
    FROM accounts
    WHERE account_number = company_account_number;

    IF company_balance < (SELECT SUM((payment->>'amount')::NUMERIC) FROM jsonb_array_elements(payments) AS payment) THEN
        RAISE EXCEPTION 'The magical energy (balance) of the company is insufficient for all payments';
    END IF;

    FOR payment IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        BEGIN
            SELECT nextval('transaction_id_seq') INTO transaction_id;

            payment_amount := (payment->>'amount')::NUMERIC;

            INSERT INTO transactions (transaction_id, from_account_number, amount, transaction_date, description)
            VALUES (transaction_id, company_account_number, payment_amount, CURRENT_DATE, payment->>'description');

            successful_count := successful_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                failed_count := failed_count + 1;
                failed_details := failed_details || jsonb_build_object('payment', payment, 'error', SQLERRM);
        END;
    END LOOP;

    RETURN jsonb_build_object('successful_count', successful_count, 'failed_count', failed_count, 'failed_details', failed_details);
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION log_payment_error(
    payment JSONB,
    error_message TEXT
)
RETURNS VOID AS $$
DECLARE
    transaction_id BIGINT;
BEGIN
    SELECT nextval('transaction_id_seq') INTO transaction_id;
    INSERT INTO transaction_logs (transaction_id, status, log_message)
    VALUES (transaction_id, 'FAILED', 'Payment failed: ' || error_message || '. Payment Details: ' || payment::TEXT);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_salary_batch_v3(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    payment JSONB;
    total_batch_amount NUMERIC := 0;
    successful_count INT := 0;
    failed_count INT := 0;
    failed_details JSONB := '[]'::JSONB;
    company_balance NUMERIC;
    transaction_id BIGINT;
    payment_amount NUMERIC;
BEGIN
    SELECT balance INTO company_balance
    FROM accounts
    WHERE account_number = company_account_number;

    IF company_balance < (SELECT SUM((payment->>'amount')::NUMERIC) FROM jsonb_array_elements(payments) AS payment) THEN
        RAISE EXCEPTION 'The magical energy (balance) of the company is insufficient for all payments';
    END IF;

    FOR payment IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        BEGIN
            SELECT balance INTO company_balance
            FROM accounts
            WHERE account_number = company_account_number
            FOR UPDATE;

            SELECT nextval('transaction_id_seq') INTO transaction_id;

            payment_amount := (payment->>'amount')::NUMERIC;

            INSERT INTO transactions (transaction_id, from_account_number, amount, transaction_date, description)
            VALUES (transaction_id, company_account_number, payment_amount, CURRENT_DATE, payment->>'description');

            INSERT INTO transaction_logs (transaction_id, status, log_message)
            VALUES (transaction_id, 'SUCCESS', 'Payment processed successfully for ' || payment->>'description');
            
            successful_count := successful_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                failed_count := failed_count + 1;
                failed_details := failed_details || jsonb_build_object('payment', payment, 'error', SQLERRM);
                PERFORM log_payment_error(payment, SQLERRM);
        END;
    END LOOP;

    RETURN jsonb_build_object('successful_count', successful_count, 'failed_count', failed_count, 'failed_details', failed_details);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION send_payment_report(
    company_account_number VARCHAR,
    successful_count INT,
    failed_count INT,
    failed_details JSONB
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO notifications (company_account_number, message, status, created_at)
    VALUES (company_account_number, 
            'Salary Batch Processed: Successful: ' || successful_count || ', Failed: ' || failed_count,
            'completed', CURRENT_TIMESTAMP);

    IF failed_count > 0 THEN
        INSERT INTO notifications (company_account_number, message, status, failed_details, created_at)
        VALUES (company_account_number, 
                'Some payments failed. Please check the logs for details.', 
                'failed', failed_details, CURRENT_TIMESTAMP);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_salary_with_notifications(
    company_account_number VARCHAR,
    payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    result := process_salary_batch_v3(company_account_number, payments);

    PERFORM send_payment_report(company_account_number, 
                                (result->>'successful_count')::INT, 
                                (result->>'failed_count')::INT, 
                                result->'failed_details');
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

SELECT process_salary_with_notifications('company123', '[{"amount": 1000, "description": "Salary for Employee A"}, {"amount": 2000, "description": "Salary for Employee B"}]');






