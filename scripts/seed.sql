-- DAT302 standalone quick-seed: intentionally unindexed email/last_name lookups.
-- DISPOSABLE LAB ONLY, called by seed.sh after explicit confirmation.
\echo 'Recreating HR tables in the disposable workshop DB'
DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE employees (
    emp_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(80),
    email VARCHAR(100),
    department_id INT,
    salary NUMERIC(10,2)
);
CREATE TABLE departments (dept_id SERIAL PRIMARY KEY, dept_name VARCHAR(50));
CREATE TABLE projects (proj_id BIGSERIAL PRIMARY KEY, proj_name VARCHAR(50), budget NUMERIC(12,2));
CREATE TABLE employee_projects (
    emp_id BIGINT REFERENCES employees(emp_id),
    proj_id BIGINT REFERENCES projects(proj_id),
    PRIMARY KEY (emp_id, proj_id)
);
INSERT INTO departments (dept_name)
SELECT 'dept_name_' || gs FROM generate_series(1, 100) AS gs;
INSERT INTO employees(first_name,last_name,email,department_id,salary)
SELECT 'first_name_' || (gs % 3000), 'last_name_' || (gs % 50000),
       'user' || gs || '@company.com', 1 + (gs % 100), (25000 + (gs % 90000))::numeric
FROM generate_series(1, :employee_rows) AS gs;
INSERT INTO projects(proj_name,budget)
SELECT 'project_' || gs, (gs * 100)::numeric FROM generate_series(1, 10000) AS gs;
INSERT INTO employee_projects(emp_id,proj_id)
SELECT gs, 1 + (gs % 10000) FROM generate_series(1, :employee_rows) AS gs;
CREATE INDEX idx_emp_department ON employees(department_id);
CREATE INDEX idx_emp_salary ON employees(salary);
CREATE INDEX idx_emp_proj_emp_id ON employee_projects(emp_id);
ANALYZE;
\echo 'No index on employees.email or employees.last_name (the DAT302 scenario).'
SELECT relname, n_live_tup FROM pg_stat_user_tables WHERE relname='employees';
