-- Create Master Key (Database Level)
USE HRFeedbackDB;
GO

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'HRFeedbackDB_MasterKey@123';
GO

-- Create Certificate for Column Encryption

CREATE CERTIFICATE GrievanceCert
WITH SUBJECT='Certificate for grievance column encryption';
GO

-- Create Symmetric Key
CREATE SYMMETRIC KEY GrievanceSymKey
WITH ALGORITHM= AES_256
ENCRYPTION BY CERTIFICATE GrievanceCert;
GO

-- Add Encrypted Column to Grievances Table

ALTER TABLE grievances
ADD description_encrypted VARBINARY(MAX);
GO

-- Encrypt Existing Data in description Column

OPEN SYMMETRIC KEY GrievanceSymKey
DECRYPTION BY CERTIFICATE GrievanceCert;
GO

UPDATE grievances
SET description_encrypted=
    EncryptByKey(
        Key_GUID('GrievanceSymKey'),
        description
    );
GO

CLOSE SYMMETRIC KEY GrievanceSymKey;
GO

-- May keep or later drop the plain text column
-- ALTER TABLE grievances DROP COLUMN description;

-- To Decrypt Data from description_encrypted Column
-- OPEN SYMMETRIC KEY GrievanceSymKey
-- DECRYPTION BY CERTIFICATE GrievanceCert;
-- GO

-- SELECT
--     grievance_id,
--     CONVERT(NVARCHAR(MAX),
--         DecryptByKey(description_encrypted)) AS description_decrypted
-- FROM grievances;
-- GO

-- CLOSE SYMMETRIC KEY GrievanceSymKey;
-- GO


