```sql
-- Drop existing tables (if any) in reverse order to avoid FK conflicts
DROP TABLE IF EXISTS request_updates;
DROP TABLE IF EXISTS advance_balances;
DROP TABLE IF EXISTS advance_requests;
DROP TABLE IF EXISTS reimbursement_requests;
DROP TABLE IF EXISTS statuses;
DROP TABLE IF EXISTS purposes;
DROP TABLE IF EXISTS cost_categories;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS departments;

-- Create departments table
CREATE TABLE departments (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE (name)
);

-- Create users table
CREATE TABLE users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    department_id INT UNSIGNED NOT NULL,
    manager_id INT UNSIGNED NULL,
    updated_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    UNIQUE (email),
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create permissions table
CREATE TABLE permissions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE (module, action)
);

-- Create roles table
CREATE TABLE roles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE (name)
);

-- Create role_permissions table
CREATE TABLE role_permissions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    role_id INT UNSIGNED NOT NULL,
    permission_id INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE (role_id, permission_id)
);

-- Create user_roles table
CREATE TABLE user_roles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE (user_id, role_id)
);

-- Create cost_categories table
CREATE TABLE cost_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE (name)
);

-- Create purposes table
CREATE TABLE purposes (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    cost_category_id INT UNSIGNED NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (cost_category_id) REFERENCES cost_categories(id) ON DELETE SET NULL,
    UNIQUE (name, cost_category_id)
);

-- Create statuses table
CREATE TABLE statuses (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    is_reimbursement BOOLEAN NOT NULL,
    is_advance BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE (name)
);

-- Create reimbursement_requests table
CREATE TABLE reimbursement_requests (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    expense_date DATE NOT NULL,
    cost_category_id INT UNSIGNED NOT NULL,
    purpose_id INT UNSIGNED NOT NULL,
    description TEXT NULL,
    amount DECIMAL(8,2) NOT NULL,
    ref_bill_number VARCHAR(255) NOT NULL,
    bill_attached BLOB NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cost_category_id) REFERENCES cost_categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (purpose_id) REFERENCES purposes(id) ON DELETE RESTRICT
);

-- Create advance_requests table
CREATE TABLE advance_requests (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    request_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    cost_category_id INT UNSIGNED NOT NULL,
    purpose_id INT UNSIGNED NOT NULL,
    description TEXT NULL,
    amount DECIMAL(8,2) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cost_category_id) REFERENCES cost_categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (purpose_id) REFERENCES purposes(id) ON DELETE RESTRICT
);

-- Create advance_balances table
CREATE TABLE advance_balances (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    balance DECIMAL(8,2) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (employee_id)
);

-- Create request_updates table
CREATE TABLE request_updates (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    reimbursement_request_id INT UNSIGNED NULL,
    advance_request_id INT UNSIGNED NULL,
    status_id INT UNSIGNED NOT NULL,
    reason TEXT NULL,
    updated_by_id INT UNSIGNED NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (reimbursement_request_id) REFERENCES reimbursement_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (advance_request_id) REFERENCES advance_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES statuses(id) ON DELETE RESTRICT,
    FOREIGN KEY (updated_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT check_request_type CHECK (
        (reimbursement_request_id IS NOT NULL AND advance_request_id IS NULL) OR
        (reimbursement_request_id IS NULL AND advance_request_id IS NOT NULL)
    )
);

-- Create indexes for performance
CREATE INDEX idx_users_department ON users(department_id);
CREATE INDEX idx_users_manager ON users(manager_id);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_reimbursement_requests_employee ON reimbursement_requests(employee_id);
CREATE INDEX idx_advance_requests_employee ON advance_requests(employee_id);
CREATE INDEX idx_advance_balances_employee ON advance_balances(employee_id);
CREATE INDEX idx_request_updates_reimbursement ON request_updates(reimbursement_request_id);
CREATE INDEX idx_request_updates_advance ON request_updates(advance_request_id);
CREATE INDEX idx_request_updates_status ON request_updates(status_id);

-- Seed initial data
-- Departments
INSERT INTO departments (name, created_at, updated_at)
VALUES
    ('Engineering', NOW(), NOW()),
    ('Finance', NOW(), NOW()),
    ('HR', NOW(), NOW());

-- Users (sample)
INSERT INTO users (first_name, last_name, email, department_id, manager_id, created_at, updated_at)
VALUES
    ('John', 'Doe', 'john@humanventures.in', 1, NULL, NOW(), NOW()),
    ('Jane', 'Smith', 'jane@humanventures.in', 1, 1, NOW(), NOW()),
    ('Alice', 'Johnson', 'alice@humanventures.in', 2, NULL, NOW(), NOW());

-- Permissions
INSERT INTO permissions (module, action, description, created_at, updated_at)
VALUES
    ('Reimbursement', 'create', 'Create reimbursement requests', NOW(), NOW()),
    ('Reimbursement', 'view_own', 'View own reimbursement requests', NOW(), NOW()),
    ('Reimbursement', 'edit_own', 'Edit own Pending reimbursement requests', NOW(), NOW()),
    ('Reimbursement', 'delete_own', 'Delete own Pending reimbursement requests', NOW(), NOW()),
    ('Reimbursement', 'view_team', 'View team’s reimbursement requests', NOW(), NOW()),
    ('Reimbursement', 'approve_team', 'Approve/reject team’s requests', NOW(), NOW()),
    ('Reimbursement', 'approve_final', 'Final approve/reject ManagerApproved', NOW(), NOW()),
    ('Reimbursement', 'pay', 'Mark as Paid', NOW(), NOW()),
    ('Advance', 'create', 'Create advance requests', NOW(), NOW()),
    ('Advance', 'view_own', 'View own advance requests', NOW(), NOW()),
    ('Advance', 'edit_own', 'Edit own Pending advance requests', NOW(), NOW()),
    ('Advance', 'delete_own', 'Delete own Pending advance requests', NOW(), NOW()),
    ('Advance', 'view_team', 'View team’s advance requests', NOW(), NOW()),
    ('Advance', 'approve_team', 'Approve/reject team’s advance requests', NOW(), NOW()),
    ('Advance', 'approve_final', 'Final approve/reject ManagerApproved', NOW(), NOW()),
    ('Advance', 'disburse', 'Mark as Disbursed', NOW(), NOW()),
    ('Balance', 'view_own', 'View own advance balance', NOW(), NOW()),
    ('Balance', 'view_team', 'View team’s advance balances', NOW(), NOW()),
    ('Balance', 'view_all', 'View all advance balances', NOW(), NOW()),
    ('Master', 'edit', 'Edit cost_categories, purposes, etc.', NOW(), NOW()),
    ('Report', 'view', 'Access MIS reports, audit trails', NOW(), NOW());

-- Roles
INSERT INTO roles (name, description, created_at, updated_at)
VALUES
    ('Employee', 'Submits requests', NOW(), NOW()),
    ('Manager', 'Approves team requests', NOW(), NOW()),
    ('Approver', 'Final approval, payments', NOW(), NOW()),
    ('Admin', 'Manages users, roles, master data', NOW(), NOW());

-- Role Permissions
INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
SELECT r.id, p.id, NOW(), NOW()
FROM roles r, permissions p
WHERE (r.name = 'Employee' AND p.module IN ('Reimbursement', 'Advance', 'Balance') 
       AND p.action IN ('create', 'view_own', 'edit_own', 'delete_own'))
   OR (r.name = 'Manager' AND p.module IN ('Reimbursement', 'Advance', 'Balance') 
       AND p.action IN ('view_team', 'approve_team'))
   OR (r.name = 'Approver' AND p.module IN ('Reimbursement', 'Advance', 'Balance') 
       AND p.action IN ('approve_final', 'pay', 'disburse', 'view_all'))
   OR (r.name = 'Admin' AND p.module IN ('Master', 'Report') 
       AND p.action IN ('edit', 'view'));

-- User Roles (sample)
INSERT INTO user_roles (user_id, role_id, created_at, updated_at)
SELECT u.id, r.id, NOW(), NOW()
FROM users u, roles r
WHERE (u.email = 'john@humanventures.in' AND r.name = 'Employee')
   OR (u.email = 'jane@humanventures.in' AND r.name = 'Manager')
   OR (u.email = 'alice@humanventures.in' AND r.name = 'Approver')
   OR (u.email = 'alice@humanventures.in' AND r.name = 'Admin');

-- Cost Categories
INSERT INTO cost_categories (name, created_at, updated_at)
VALUES
    ('Product', NOW(), NOW()),
    ('Office Travel', NOW(), NOW()),
    ('Others', NOW(), NOW());

-- Purposes
INSERT INTO purposes (name, cost_category_id, created_at, updated_at)
SELECT name, id, NOW(), NOW()
FROM (
    SELECT 'Purchase' AS name, (SELECT id FROM cost_categories WHERE name = 'Product') AS cost_category_id
    UNION
    SELECT 'Rent', (SELECT id FROM cost_categories WHERE name = 'Product')
    UNION
    SELECT 'Porter', (SELECT id FROM cost_categories WHERE name = 'Office Travel')
    UNION
    SELECT 'Flight', (SELECT id FROM cost_categories WHERE name = 'Office Travel')
    UNION
    SELECT 'Miscellaneous', (SELECT id FROM cost_categories WHERE name = 'Others')
) AS purposes;

-- Statuses
INSERT INTO statuses (name, is_reimbursement, is_advance, created_at, updated_at)
VALUES
    ('Pending', TRUE, TRUE, NOW(), NOW()),
    ('ManagerApproved', TRUE, TRUE, NOW(), NOW()),
    ('FinalApproved', TRUE, TRUE, NOW(), NOW()),
    ('Rejected', TRUE, TRUE, NOW(), NOW()),
    ('Paid', TRUE, FALSE, NOW(), NOW()),
    ('Disbursed', FALSE, TRUE, NOW(), NOW()),
    ('Edited', TRUE, TRUE, NOW(), NOW()),
    ('Deleted', TRUE, TRUE, NOW(), NOW());
```
