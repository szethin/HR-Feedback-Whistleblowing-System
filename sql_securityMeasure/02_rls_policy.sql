-- Step 1: Create a RLS predicate function

USE HRFeedbackDB;
GO

CREATE FUNCTION dbo.fn_rls_grievance_access(@employee_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS fn_access_result
    WHERE 
        DATABASE_PRINCIPAL_ID() = DATABASE_PRINCIPAL_ID('AdminUser')
        OR @employee_id = CAST(SESSION_CONTEXT(N'employee_id') AS INT)
);
GO


-- Step 2: Create a RLS security policy
CREATE SECURITY POLICY GrievanceRLS
ADD FILTER PREDICATE dbo.fn_rls_grievance_access(employee_id)
ON dbo.grievances
WITH (STATE = ON);
GO
