\set emp_id random(1, 200000)
-- Intentionally expensive without email index.
SELECT emp_id, first_name, last_name, email FROM employees WHERE email = 'user' || :emp_id || '@company.com';
SELECT COUNT(*) FROM employees WHERE last_name LIKE 'last_name_100%';
