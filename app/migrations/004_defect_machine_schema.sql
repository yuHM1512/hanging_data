-- =============================================================
-- Migration 004 — Defect log + Machine breakdown + Reinspect daily
-- + Extend tUser (Unit, Dept) cho tổ trưởng đăng nhập bằng employee_code
-- Idempotent: dùng IF NOT EXISTS / IF EXISTS guards.
-- =============================================================

-- ============== USERS: thêm Unit, Dept ==============
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('app.tUser') AND name = 'Unit')
    ALTER TABLE app.tUser ADD Unit nvarchar(20) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('app.tUser') AND name = 'Dept')
    ALTER TABLE app.tUser ADD Dept tinyint NULL;          -- = LineNo của tổ trưởng
GO


-- ============== B9: DefectCatalog ==============
IF OBJECT_ID('app.tDefectCatalog', 'U') IS NULL
CREATE TABLE app.tDefectCatalog (
    DefectCode      nvarchar(10)    NOT NULL CONSTRAINT PK_tDefectCatalog PRIMARY KEY,
    DefectName      nvarchar(300)   NOT NULL,
    DefectGroup     char(1)         NOT NULL,             -- C | S | F | M | T
    DisplayOrder    int             NOT NULL,             -- = group_idx*100 + num
    IsActive        bit             NOT NULL CONSTRAINT DF_tDefectCatalog_Active DEFAULT 1,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tDefectCatalog_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT CK_tDefectCatalog_Group CHECK (DefectGroup IN ('C', 'S', 'F', 'M', 'T'))
);
GO


-- ============== B10: MachineCatalog ==============
IF OBJECT_ID('app.tMachineCatalog', 'U') IS NULL
CREATE TABLE app.tMachineCatalog (
    MachineID       int             IDENTITY(1,1) NOT NULL CONSTRAINT PK_tMachineCatalog PRIMARY KEY,
    MachineName     nvarchar(200)   NOT NULL CONSTRAINT UQ_tMachineCatalog_Name UNIQUE,
    IsActive        bit             NOT NULL CONSTRAINT DF_tMachineCatalog_Active DEFAULT 1,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tMachineCatalog_CreatedAt DEFAULT SYSDATETIME()
);
GO


-- ============== B11: DefectLog ==============
IF OBJECT_ID('app.tDefectLog', 'U') IS NULL
CREATE TABLE app.tDefectLog (
    DefectLog_guid  uniqueidentifier NOT NULL CONSTRAINT PK_tDefectLog PRIMARY KEY
                                              CONSTRAINT DF_tDefectLog_guid DEFAULT NEWID(),
    PlanMaster_guid uniqueidentifier NOT NULL,
    ShtDate         date            NOT NULL,
    [LineNo]        tinyint         NOT NULL,
    Slot            tinyint         NOT NULL,             -- 1..5 mốc giờ
    DefectCode      nvarchar(10)    NOT NULL,
    StationGuid     uniqueidentifier NULL,                -- (lỏng) → dbo.tStation.guid
    StationLabel    nvarchar(150)   NOT NULL,             -- cache "St 30 — Tra tay"
    Qty             int             NOT NULL,
    LoggedAt        datetime2(0)    NOT NULL CONSTRAINT DF_tDefectLog_LoggedAt DEFAULT SYSDATETIME(),
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tDefectLog_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,                 -- employee_code
    CONSTRAINT FK_tDefectLog_PlanMaster FOREIGN KEY (PlanMaster_guid)
        REFERENCES app.tPlanMaster(PlanMaster_guid),
    CONSTRAINT FK_tDefectLog_Catalog FOREIGN KEY (DefectCode)
        REFERENCES app.tDefectCatalog(DefectCode),
    CONSTRAINT CK_tDefectLog_Slot CHECK (Slot BETWEEN 1 AND 5),
    CONSTRAINT CK_tDefectLog_Qty CHECK (Qty > 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tDefectLog_Date_Line')
    CREATE INDEX IX_tDefectLog_Date_Line ON app.tDefectLog(ShtDate, [LineNo]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tDefectLog_Plan_Slot')
    CREATE INDEX IX_tDefectLog_Plan_Slot ON app.tDefectLog(PlanMaster_guid, ShtDate, Slot);
GO


-- ============== B12: ReinspectDaily (Kiểm lại — số đã sửa / ngày / plan) ==============
IF OBJECT_ID('app.tReinspectDaily', 'U') IS NULL
CREATE TABLE app.tReinspectDaily (
    PlanMaster_guid uniqueidentifier NOT NULL,
    ShtDate         date            NOT NULL,
    FixedQty        int             NOT NULL CONSTRAINT DF_tReinspectDaily_FixedQty DEFAULT 0,
    UpdatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tReinspectDaily_UpdatedAt DEFAULT SYSDATETIME(),
    UpdatedBy       nvarchar(50)    NULL,
    CONSTRAINT PK_tReinspectDaily PRIMARY KEY (PlanMaster_guid, ShtDate),
    CONSTRAINT FK_tReinspectDaily_PlanMaster FOREIGN KEY (PlanMaster_guid)
        REFERENCES app.tPlanMaster(PlanMaster_guid),
    CONSTRAINT CK_tReinspectDaily_FixedQty CHECK (FixedQty >= 0)
);
GO


-- ============== B13: MachineBreakdown ==============
IF OBJECT_ID('app.tMachineBreakdown', 'U') IS NULL
CREATE TABLE app.tMachineBreakdown (
    Breakdown_guid  uniqueidentifier NOT NULL CONSTRAINT PK_tMachineBreakdown PRIMARY KEY
                                              CONSTRAINT DF_tBreakdown_guid DEFAULT NEWID(),
    PlanMaster_guid uniqueidentifier NULL,                -- nullable: máy gắn line, plan có thể đổi
    ShtDate         date            NOT NULL,
    [LineNo]        tinyint         NOT NULL,
    Slot            tinyint         NULL,                 -- 1..5 mốc giờ phát hiện
    MachineID       int             NOT NULL,
    DownMinutes     int             NOT NULL,             -- nhập tay
    Reason          nvarchar(500)   NULL,
    LoggedAt        datetime2(0)    NOT NULL CONSTRAINT DF_tBreakdown_LoggedAt DEFAULT SYSDATETIME(),
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tBreakdown_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    CONSTRAINT FK_tBreakdown_PlanMaster FOREIGN KEY (PlanMaster_guid)
        REFERENCES app.tPlanMaster(PlanMaster_guid),
    CONSTRAINT FK_tBreakdown_Machine FOREIGN KEY (MachineID)
        REFERENCES app.tMachineCatalog(MachineID),
    CONSTRAINT CK_tBreakdown_Slot CHECK (Slot IS NULL OR Slot BETWEEN 1 AND 5),
    CONSTRAINT CK_tBreakdown_Down CHECK (DownMinutes > 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tBreakdown_Date_Line')
    CREATE INDEX IX_tBreakdown_Date_Line ON app.tMachineBreakdown(ShtDate, [LineNo]);
GO


-- ============== SEED: DefectCatalog (63 mã) ==============
;WITH src(DefectCode, DefectName, DefectGroup, DisplayOrder) AS (
    SELECT v.* FROM (VALUES
        -- ====== Nhóm C (16) ======
        ('C1',  N'Sót chỉ / bụi bông',                                          'C',  101),
        ('C2',  N'Tẩy / bẩn, ố vàng / dính dầu, dính keo',                      'C',  102),
        ('C3',  N'Đường may rút chỉ, không ôm bờ',                              'C',  103),
        ('C4',  N'Thừa / thiếu bọ, đường may, chi tiết',                        'C',  104),
        ('C5',  N'Ủi không đạt',                                                'C',  105),
        ('C6',  N'Sai nguyên phụ liệu',                                         'C',  106),
        ('C7',  N'Tréo ống',                                                    'C',  107),
        ('C8',  N'Lộ chỉ, chỉ lược',                                            'C',  108),
        ('C9',  N'Bung xì / Kẹp / thấm thân',                                   'C',  109),
        ('C10', N'Thiếu mũi / quá mũi',                                         'C',  110),
        ('C11', N'Không lại mũi, lại mũi không trùng',                          'C',  111),
        ('C12', N'Cắt / may sai qui cách',                                      'C',  112),
        ('C13', N'Keo bị tràn, bị bong tróc',                                   'C',  113),
        ('C14', N'Nút chưa quấn chân / chồng hở / lỏng, chặt',                  'C',  114),
        ('C15', N'Sụp mí',                                                      'C',  115),
        ('C16', N'Cắt / may sai vị trí',                                        'C',  116),
        -- ====== Nhóm S (14) ======
        ('S1',  N'Đứt chỉ, hở',                                                 'S',  201),
        ('S2',  N'Le mép, nhốt vải',                                            'S',  202),
        ('S3',  N'Chúi / sole / lệch',                                          'S',  203),
        ('S4',  N'Can, diễu xấu',                                               'S',  204),
        ('S5',  N'Thụng, lún, móp',                                             'S',  205),
        ('S6',  N'Vặn, kẹp, nhíu',                                              'S',  206),
        ('S7',  N'Chồng, hở / gồng',                                            'S',  207),
        ('S8',  N'Xiên, nghiêng',                                               'S',  208),
        ('S9',  N'Tà bật, vểnh',                                                'S',  209),
        ('S10', N'Tù góc, đầu ruồi',                                            'S',  210),
        ('S11', N'Gãy, đá, ngữa, biến dạng',                                    'S',  211),
        ('S12', N'Nhăn đùn / căng / giựt',                                      'S',  212),
        ('S13', N'Thân bị đổ, chảy',                                            'S',  213),
        ('S14', N'Phồng, dộp',                                                  'S',  214),
        -- ====== Nhóm F (12) ======
        ('F1',  N'Lỗi vải / Lủng vải',                                          'F',  301),
        ('F2',  N'Vải loang màu / khác màu',                                    'F',  302),
        ('F3',  N'Lỗi do in / ép / thêu',                                       'F',  303),
        ('F4',  N'Lỗi do nguyên phụ liệu',                                      'F',  304),
        ('F5',  N'Nấm mốc / côn trùng',                                         'F',  305),
        ('F6',  N'Lỗi thông số',                                                'F',  306),
        ('F7',  N'Lỗi gấp xếp',                                                 'F',  307),
        ('F8',  N'Lỗi bao bì, đóng gói',                                        'F',  308),
        ('F9',  N'Lỗi do cắt',                                                  'F',  309),
        ('F10', N'Kim loại; Phụ liệu / Vật sắc bén',                            'F',  310),
        ('F11', N'Sai yêu cầu an toàn cho sản phẩm trẻ em (vd: dây luồn)',      'F',  311),
        ('F12', N'Có hóa chất cấm, chất gây dị ứng',                            'F',  312),
        -- ====== Nhóm M (7) ======
        ('M1',  N'Đường may cong gãy, nhăn',                                    'M',  401),
        ('M2',  N'Bỏ mũi',                                                      'M',  402),
        ('M3',  N'Mật độ chỉ không đều / Lỏng chỉ, chặt chỉ',                   'M',  403),
        ('M4',  N'Đường may cuốn bờ, tưa vải',                                  'M',  404),
        ('M5',  N'Khuy hoặc nút không đạt',                                     'M',  405),
        ('M6',  N'Gùi chỉ',                                                     'M',  406),
        ('M7',  N'Lỗ kim, bể vải',                                              'M',  407),
        -- ====== Nhóm T (14) ======
        ('T1',  N'Seam sót chỉ, tưa chỉ, xơ vải',                               'T',  501),
        ('T2',  N'Seam hụt',                                                    'T',  502),
        ('T3',  N'Seam lệch',                                                   'T',  503),
        ('T4',  N'Seam gấp nếp / xếp ly / kẹp vải',                             'T',  504),
        ('T5',  N'Bờ đường may xoắn vặn, tape ép ra mặt phải vải',              'T',  505),
        ('T6',  N'Seam co rút',                                                 'T',  506),
        ('T7',  N'Seam bong bóng / bọt khí',                                    'T',  507),
        ('T8',  N'Seam bong tróc',                                              'T',  508),
        ('T9',  N'Seam cháy / đứt đoạn',                                        'T',  509),
        ('T10', N'Keo tape lan ra ngoài, không đều hoặc lớn hơn 1 mm',          'T',  510),
        ('T11', N'Sau giặt lớp vải trên tape bị tưa sợi',                       'T',  511),
        ('T12', N'Ép 2 đường seam trên đường thẳng và đường cong',              'T',  512),
        ('T13', N'Seam xếp ly ở đầu và cuối tape',                              'T',  513),
        ('T14', N'Seam bị dấu do dừng trong quá trình tape',                    'T',  514)
    ) AS v(DefectCode, DefectName, DefectGroup, DisplayOrder)
)
MERGE app.tDefectCatalog AS tgt
USING src
   ON tgt.DefectCode = src.DefectCode
WHEN MATCHED THEN UPDATE
    SET tgt.DefectName   = src.DefectName,
        tgt.DefectGroup  = src.DefectGroup,
        tgt.DisplayOrder = src.DisplayOrder
WHEN NOT MATCHED THEN
    INSERT (DefectCode, DefectName, DefectGroup, DisplayOrder)
    VALUES (src.DefectCode, src.DefectName, src.DefectGroup, src.DisplayOrder);
GO


-- ============== SEED: MachineCatalog ==============
;WITH src(MachineName) AS (
    SELECT v.* FROM (VALUES
        (N'1 kim'), (N'1 kim trụ đứng'), (N'1 kim điện tử'), (N'1 kim cào trên'),
        (N'1 kim xén'), (N'1 kim móc xích'),
        (N'2 kim (cố định & di động)'), (N'2 kim móc xích'), (N'2 kim móc xích đuổi'),
        (N'2 kim cuốn ống'),
        (N'Vắt sổ'), (N'Đánh bọ'), (N'Thùa bằng'), (N'Thùa mắt phượng'),
        (N'Đính nút'), (N'Đính điểm'), (N'Đính nhãn'),
        (N'Kansai'), (N'Dập nút'), (N'Ép Seam'), (N'Ủi form'), (N'Ủi sườn quần'),
        (N'Ép nhãn Genki'), (N'Ép nhãn H&H CS-655'), (N'Ép nhiệt H&H CS-652'),
        (N'Test nước'), (N'Zíc zắc'),
        (N'May chương trình'), (N'Xén răng cưa'), (N'Vắt gấu'), (N'Mổ túi điện tử'),
        (N'Bàn hút ủi bắp tay'), (N'Ép lót tay áo'),
        (N'Máy may lược đế trụ'), (N'Máy may lược đế bằng'), (N'Máy tra tay'),
        (N'Máy may đột'), (N'Máy may đột ve'), (N'Máy ủi rẽ sườn'),
        (N'Dập mông'), (N'Dập ống'), (N'Dập lai'), (N'Dập nắp túi'),
        (N'Dập ve cổ'), (N'Dập ve bán thành phẩm'), (N'Dập ve thành phẩm'), (N'Dập ve áo'),
        (N'Dập sườn tay'), (N'Dập tay áo'), (N'Dập vai'), (N'Dập khuỷ tay áo'),
        (N'Dập seam đầu tay áo'),
        (N'Rẽ vai con'), (N'Máy thổi và xoa đầu tay'),
        (N'Dập vòng nách'), (N'Dập vòng nách + vai tay'),
        (N'Ủi dập thân'), (N'Dập định hình thân trước'), (N'Rẽ sườn và sóng lưng'),
        (N'Dập thân trước'), (N'Dập thân sau'), (N'Fom thổi tay áo')
    ) AS v(MachineName)
)
MERGE app.tMachineCatalog AS tgt
USING src
   ON tgt.MachineName = src.MachineName
WHEN NOT MATCHED THEN
    INSERT (MachineName) VALUES (src.MachineName);
GO


PRINT '✓ Migration 004 applied — tDefectCatalog (63), tMachineCatalog (~62), tDefectLog, tReinspectDaily, tMachineBreakdown; tUser+Unit+Dept.';
GO
