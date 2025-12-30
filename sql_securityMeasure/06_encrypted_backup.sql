-- Create a Certificate for Encrypted Backups

USE master;
GO

CREATE CERTIFICATE HRFeedbackDB_BackupCert
WITH SUBJECT='Certificate for Encrypted Database Backups';
GO

-- Backup the Certificate to a file for recovery purposes

BACKUP DATABASE HRFeedbackDB
TO DISK='C:\SQLBackups\HRFeedbackDB_Encrypted.bak'
WITH
    INIT,
    COMPRESSION,
    ENCRYPTION
    (
        ALGORITHM= AES_256,
        SERVER CERTIFICATE= HRFeedbackDB_BackupCert
    );
GO

-- Backup the Certificate and Private Key to files

USE master;
GO

BACKUP CERTIFICATE HRFeedbackDB_BackupCert
TO FILE='C:\SQLBackups\HRFeedbackDB_BackupCert.cer'
WITH PRIVATE KEY
(
    FILE='C:\SQLBackups\HRFeedbackDB_BackupCert_PrivateKey.pvk',
    ENCRYPTION BY PASSWORD='StrongBackupCertPassword@123'
);
GO


