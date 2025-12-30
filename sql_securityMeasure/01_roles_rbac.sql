-- Step 1: Create Database Roles

USE HRFeedbackDB;
GO

CREATE ROLE EmployeeRole;
CREATE ROLE AdminRole;
GO


-- Step 2: Grant Permissions to Roles

-- EmployeeRole Permissions
GRANT SELECT, INSERT ON grievances TO EmployeeRole;
GRANT SELECT ON users TO EmployeeRole;

-- AdminRole Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON grievances TO AdminRole;
GRANT SELECT ON users TO AdminRole;


-- Step 3: Create Login Users

USE master
CREATE LOGIN EmployeeLogin WITH PASSWORD = 'Employee@123';
CREATE LOGIN AdminLogin WITH PASSWORD = 'Admin@123';
GO

USE HRFeedbackDB
CREATE USER EmployeeUser FOR LOGIN EmployeeLogin;
CREATE USER AdminUser FOR LOGIN AdminLogin;
GO


-- Step 4: Assign Roles to Users

ALTER ROLE EmployeeRole ADD MEMBER EmployeeUser;
ALTER ROLE AdminRole ADD MEMBER AdminUser;
GO