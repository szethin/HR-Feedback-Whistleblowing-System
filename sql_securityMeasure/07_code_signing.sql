-- Create a certificate for Code Signing

USE HRFeedbackDB;
GO

CREATE CERTIFICATE CodeSigningCert
WITH SUBJECT='Certificate for SQL Code Signing';
GO

-- Create a simple demo stored procedure

CREATE PROCEDURE sp_ViewAllGrievances
AS
BEGIN
SELECT grievance_id, employee_id, title, status, created_at
FROM grievances;
END;
GO

-- Sign the stored procedure with the certificate
ADD SIGNATURE
TO OBJECT::sp_ViewAllGrievances
BY CERTIFICATE CodeSigningCert;
GO



