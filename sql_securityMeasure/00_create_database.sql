CREATE DATABASE HRFeedbackDB;
GO
USE HRFeedbackDB;
GO

-- Users table
CREATE TABLE users (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password_hash NVARCHAR(255),
    role NVARCHAR(50) DEFAULT 'EMPLOYEE'
);

-- Grievances table
CREATE TABLE grievances (
    grievance_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    status NVARCHAR(50) DEFAULT 'PENDING',
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (employee_id) REFERENCES users(employee_id)
);

-- Insert test users with hashed passwords
-- Password: "password123" hashed with werkzeug
INSERT INTO users (name, email, password_hash, role) VALUES 
('John Doe', 'employee@test.com', 'scrypt:32768:8:1$BEmXk3gmIQoRkLyF$7762bd4f3652fa90bb42829cc57d815ea4f53d7922d05a3c05c2a14b282374ba46f762f8c03756648a4012322f1da77e00b8cf0e890286020df79392364169f5', 'EMPLOYEE'),
('Jane Smith', 'jane@test.com', 'scrypt:32768:8:1$BEmXk3gmIQoRkLyF$7762bd4f3652fa90bb42829cc57d815ea4f53d7922d05a3c05c2a14b282374ba46f762f8c03756648a4012322f1da77e00b8cf0e890286020df79392364169f5', 'EMPLOYEE'),
('Admin User', 'admin@test.com', 'scrypt:32768:8:1$BEmXk3gmIQoRkLyF$7762bd4f3652fa90bb42829cc57d815ea4f53d7922d05a3c05c2a14b282374ba46f762f8c03756648a4012322f1da77e00b8cf0e890286020df79392364169f5', 'ADMIN');

-- Insert grievances
INSERT INTO grievances (employee_id, title, description, status, created_at) VALUES 
(1, 'Office Temperature', 'The AC is too cold in the north wing.', 'PENDING', GETDATE()),
(2, 'Safety Hazard', 'Loose cables in the hallway.', 'RESOLVED', GETDATE());