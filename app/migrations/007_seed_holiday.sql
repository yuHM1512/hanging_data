-- =============================================================
-- Migration 007 - Seed app.tHoliday voi danh sach nghi le 2022-2026
-- Source: user-provided list (le quoc gia + nghi bao + ngap lut)
-- Idempotent: dung MERGE de upsert theo HolidayDate (PK).
-- =============================================================

MERGE app.tHoliday AS tgt
USING (VALUES
    ('2022-09-27', N'Nghỉ bão'),
    ('2022-09-28', N'Nghỉ bão'),
    ('2022-10-15', N'Ngập lụt'),
    ('2023-01-02', N'Tết Dương lịch'),
    ('2023-01-16', N'Tết Âm lịch'),
    ('2023-01-17', N'Tết Âm lịch'),
    ('2023-01-18', N'Tết Âm lịch'),
    ('2023-01-19', N'Tết Âm lịch'),
    ('2023-01-20', N'Tết Âm lịch'),
    ('2023-01-21', N'Tết Âm lịch'),
    ('2023-01-23', N'Tết Âm lịch'),
    ('2023-01-24', N'Tết Âm lịch'),
    ('2023-01-25', N'Tết Âm lịch'),
    ('2023-01-26', N'Tết Âm lịch'),
    ('2023-01-27', N'Tết Âm lịch'),
    ('2023-01-28', N'Tết Âm lịch'),
    ('2023-04-29', N'Nghỉ 30/4 + 1/5'),
    ('2023-05-01', N'Nghỉ 30/4 + 1/5'),
    ('2023-05-02', N'Nghỉ 30/4 + 1/5'),
    ('2023-09-01', N'Nghỉ lễ 2/9'),
    ('2023-09-02', N'Nghỉ lễ 2/9'),
    ('2023-09-04', N'Nghỉ lễ 2/9'),
    ('2024-01-01', N'Nghỉ Tết Dương'),
    ('2024-02-07', N'Tết Âm lịch'),
    ('2024-02-08', N'Tết Âm lịch'),
    ('2024-02-09', N'Tết Âm lịch'),
    ('2024-02-10', N'Tết Âm lịch'),
    ('2024-02-12', N'Tết Âm lịch'),
    ('2024-02-13', N'Tết Âm lịch'),
    ('2024-02-14', N'Tết Âm lịch'),
    ('2024-04-18', N'Giỗ Tổ'),
    ('2024-04-29', N'Nghỉ 30-4 & 1-5'),
    ('2024-04-30', N'Nghỉ 30-4 & 1-5'),
    ('2024-05-01', N'Nghỉ 30-4 & 1-5'),
    ('2024-09-02', N'Nghỉ Quốc khánh'),
    ('2024-09-03', N'Nghỉ Quốc khánh'),
    ('2025-01-01', N'Nghỉ Tết Dương'),
    ('2025-01-25', N'Tết Âm lịch'),
    ('2025-01-27', N'Tết Âm lịch'),
    ('2025-01-28', N'Tết Âm lịch'),
    ('2025-01-29', N'Tết Âm lịch'),
    ('2025-01-30', N'Tết Âm lịch'),
    ('2025-01-31', N'Tết Âm lịch'),
    ('2025-02-01', N'Tết Âm lịch'),
    ('2025-02-03', N'Tết Âm lịch'),
    ('2025-02-04', N'Tết Âm lịch'),
    ('2025-04-07', N'Giỗ Tổ'),
    ('2025-04-30', N'Nghỉ 30-4 & 1-5'),
    ('2025-05-01', N'Nghỉ 30-4 & 1-5'),
    ('2025-09-01', N'Nghỉ Quốc khánh'),
    ('2025-09-02', N'Nghỉ Quốc khánh'),
    ('2026-01-01', N'Nghỉ Tết Dương'),
    ('2026-02-12', N'Tết Âm lịch'),
    ('2026-02-13', N'Tết Âm lịch'),
    ('2026-02-14', N'Tết Âm lịch'),
    ('2026-02-16', N'Tết Âm lịch'),
    ('2026-02-17', N'Tết Âm lịch'),
    ('2026-02-18', N'Tết Âm lịch'),
    ('2026-02-19', N'Tết Âm lịch'),
    ('2026-02-20', N'Tết Âm lịch'),
    ('2026-02-21', N'Tết Âm lịch'),
    ('2026-04-27', N'Giỗ Tổ'),
    ('2026-04-30', N'Nghỉ 30-4 & 1-5'),
    ('2026-05-01', N'Nghỉ 30-4 & 1-5')
) AS src(HolidayDate, Description)
   ON tgt.HolidayDate = src.HolidayDate
WHEN MATCHED AND ISNULL(tgt.Description, N'') <> src.Description
    THEN UPDATE SET Description = src.Description
WHEN NOT MATCHED
    THEN INSERT (HolidayDate, Description, CreatedBy)
         VALUES (src.HolidayDate, src.Description, N'migration-007');
GO

PRINT 'Migration 007 applied - seeded app.tHoliday';
GO
