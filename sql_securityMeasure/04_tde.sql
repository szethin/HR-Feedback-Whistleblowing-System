USE master;
GO

CREATE MASTER KEY
ENCRYPTION BY PASSWORD='StrongMasterKey@123';
GO

-- Create a certificate for TDE

CREATE CERTIFICATE HRFeedbackDB_TDE_Cert
WITH SUBJECT='TDE Certificate for HRFeedbackDB';
GO

-- Backup the certificate and private key to files

BACKUP CERTIFICATE HRFeedbackDB_TDE_Cert
TO FILE='C:\TDE_Backup\HRFeedbackDB_TDE_Cert.cer'
WITH PRIVATE KEY (
    FILE='C:\TDE_Backup\HRFeedbackDB_TDE_Cert_PrivateKey.pvk',
    ENCRYPTION BY PASSWORD='StrongPrivateKey@123'
);
GO

USE HRFeedbackDB;
GO

-- Create Database Encryption Key

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM= AES_256
ENCRYPTION BY SERVER CERTIFICATE HRFeedbackDB_TDE_Cert;
GO

-- Enable TDE

ALTER DATABASE HRFeedbackDB
SET ENCRYPTION ON;
GO

-- Verify TDE status

SELECT
    db.nameAS DatabaseName,
    dek.encryption_state,
    dek.encryptor_type
FROM sys.databases db
LEFTJOIN sys.dm_database_encryption_keys dek
ON db.database_id= dek.database_id
WHERE db.name='HRFeedbackDB';

