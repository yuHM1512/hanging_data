-- Migration 003 — Thêm cột OWE_Target vào tSAM
-- Lưu mục tiêu OWE theo từng StyleNo (từ Google Sheet TARGET_OWE).

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('app.tSAM') AND name = 'OWE_Target')
    ALTER TABLE app.tSAM ADD OWE_Target decimal(6,4) NULL;
GO

PRINT '✓ Migration 003 applied.';
GO
