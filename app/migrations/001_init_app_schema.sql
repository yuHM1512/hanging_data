-- =============================================================
-- Migration 001 — Initial app schema for hanging-line dashboard
-- Target DB: hanging_data_new (SQL Server, Windows Auth)
-- Idempotent: safe to re-run; uses IF NOT EXISTS guards.
-- =============================================================

-- Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'app')
    EXEC('CREATE SCHEMA app');
GO

-- ============== MASTER DATA ==============

-- B1: Lịch nghỉ (Chủ nhật + lễ + nghỉ riêng)
IF OBJECT_ID('app.tHoliday', 'U') IS NULL
CREATE TABLE app.tHoliday (
    HolidayDate     date            NOT NULL CONSTRAINT PK_tHoliday PRIMARY KEY,
    Description     nvarchar(200)   NULL,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tHoliday_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL
);
GO

-- B2: Lộ trình giao năng suất (Hiệu suất RC theo Phân loại × Cấp NĐSX × Ngày)
-- Vest: NDSXLevel = 0 (sentinel — không phân cấp)
IF OBJECT_ID('app.tProductionCurve', 'U') IS NULL
CREATE TABLE app.tProductionCurve (
    Category        nvarchar(30)    NOT NULL,
    NDSXLevel       tinyint         NOT NULL,
    DayN            smallint        NOT NULL,
    Ratio           decimal(10,5)   NOT NULL,
    CONSTRAINT PK_tProductionCurve PRIMARY KEY (Category, NDSXLevel, DayN),
    CONSTRAINT CK_tProductionCurve_Category CHECK (Category IN (N'Đặc biệt', N'Mới', N'Lặp lại', N'Vest')),
    CONSTRAINT CK_tProductionCurve_NDSX CHECK (NDSXLevel BETWEEN 0 AND 3),
    CONSTRAINT CK_tProductionCurve_Day CHECK (DayN BETWEEN 1 AND 200)
);
GO

-- B3: SAM theo Mã hàng (cho OWE)
IF OBJECT_ID('app.tSAM', 'U') IS NULL
CREATE TABLE app.tSAM (
    StyleNo         nvarchar(50)    NOT NULL CONSTRAINT PK_tSAM PRIMARY KEY,
    SAM             decimal(10,3)   NOT NULL,
    Source          nvarchar(300)   NULL,
    UpdatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tSAM_UpdatedAt DEFAULT SYSDATETIME(),
    UpdatedBy       nvarchar(50)    NULL
);
GO

-- B4: Nhu cầu mẹ (setup theo Mã hàng / NhuCauMe)
IF OBJECT_ID('app.tDemandRoot', 'U') IS NULL
CREATE TABLE app.tDemandRoot (
    NhuCauMe        nvarchar(100)   NOT NULL CONSTRAINT PK_tDemandRoot PRIMARY KEY,
    StyleNo         nvarchar(50)    NOT NULL,
    SLKH            int             NOT NULL,
    DMKT            decimal(10,3)   NOT NULL,
    PhanLoaiDH      nvarchar(20)    NOT NULL,
    [LineNo]        tinyint         NOT NULL,
    LDBienChe       smallint        NOT NULL,
    Notes           nvarchar(500)   NULL,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tDemandRoot_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    UpdatedAt       datetime2(0)    NULL,
    UpdatedBy       nvarchar(50)    NULL,
    CONSTRAINT CK_tDemandRoot_PhanLoai CHECK (PhanLoaiDH IN (N'Đặc biệt', N'Mới', N'Lặp lại', N'Vest')),
    CONSTRAINT CK_tDemandRoot_LineNo CHECK ([LineNo] BETWEEN 1 AND 10),
    CONSTRAINT CK_tDemandRoot_SLKH CHECK (SLKH > 0),
    CONSTRAINT CK_tDemandRoot_DMKT CHECK (DMKT > 0),
    CONSTRAINT CK_tDemandRoot_LDBienChe CHECK (LDBienChe > 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tDemandRoot_StyleNo' AND object_id = OBJECT_ID('app.tDemandRoot'))
    CREATE INDEX IX_tDemandRoot_StyleNo ON app.tDemandRoot(StyleNo);
GO

-- ============== PER-PLAN SETUP ==============

-- B5: Kế hoạch ngày — 1 dòng / số đơn hàng con (MONo)
IF OBJECT_ID('app.tPlanMaster', 'U') IS NULL
CREATE TABLE app.tPlanMaster (
    PlanMaster_guid uniqueidentifier NOT NULL CONSTRAINT PK_tPlanMaster PRIMARY KEY
                                              CONSTRAINT DF_tPlanMaster_guid DEFAULT NEWID(),
    MONo            nvarchar(100)   NOT NULL CONSTRAINT UQ_tPlanMaster_MONo UNIQUE,
    SoDonHang       nvarchar(100)   NOT NULL,      -- phần "#xxxx" tách từ MONo
    StyleNo         nvarchar(50)    NOT NULL,
    NhuCauMe        nvarchar(100)   NOT NULL,
    [LineNo]        tinyint         NOT NULL,
    FirstHangDate   date            NOT NULL,
    DailyAim        int             NULL,
    Customer        nvarchar(200)   NULL,
    EndDateExpected date            NULL,
    Notes           nvarchar(500)   NULL,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tPlanMaster_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    UpdatedAt       datetime2(0)    NULL,
    UpdatedBy       nvarchar(50)    NULL,
    CONSTRAINT FK_tPlanMaster_DemandRoot FOREIGN KEY (NhuCauMe)
        REFERENCES app.tDemandRoot(NhuCauMe)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tPlanMaster_NhuCauMe' AND object_id = OBJECT_ID('app.tPlanMaster'))
    CREATE INDEX IX_tPlanMaster_NhuCauMe ON app.tPlanMaster(NhuCauMe);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tPlanMaster_StyleNo' AND object_id = OBJECT_ID('app.tPlanMaster'))
    CREATE INDEX IX_tPlanMaster_StyleNo  ON app.tPlanMaster(StyleNo);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tPlanMaster_LineNo' AND object_id = OBJECT_ID('app.tPlanMaster'))
    CREATE INDEX IX_tPlanMaster_LineNo   ON app.tPlanMaster([LineNo]);
GO

-- B5b: PO sub-table (1 plan → N PO)
IF OBJECT_ID('app.tPlanPO', 'U') IS NULL
CREATE TABLE app.tPlanPO (
    PlanPO_guid     uniqueidentifier NOT NULL CONSTRAINT PK_tPlanPO PRIMARY KEY
                                              CONSTRAINT DF_tPlanPO_guid DEFAULT NEWID(),
    PlanMaster_guid uniqueidentifier NOT NULL,
    PONo            nvarchar(100)   NOT NULL,
    Qty             int             NOT NULL,
    ShipDate        date            NOT NULL,
    Notes           nvarchar(300)   NULL,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tPlanPO_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    CONSTRAINT FK_tPlanPO_PlanMaster FOREIGN KEY (PlanMaster_guid)
        REFERENCES app.tPlanMaster(PlanMaster_guid) ON DELETE CASCADE,
    CONSTRAINT CK_tPlanPO_Qty CHECK (Qty > 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tPlanPO_PlanMaster' AND object_id = OBJECT_ID('app.tPlanPO'))
    CREATE INDEX IX_tPlanPO_PlanMaster ON app.tPlanPO(PlanMaster_guid);
GO

-- B6: 6 trạm theo dõi của plan (gắn theo NhuCauMe → dùng chung mọi plan con)
IF OBJECT_ID('app.tClusterStationConfig', 'U') IS NULL
CREATE TABLE app.tClusterStationConfig (
    Cluster_guid    uniqueidentifier NOT NULL CONSTRAINT PK_tClusterStationConfig PRIMARY KEY
                                              CONSTRAINT DF_tCluster_guid DEFAULT NEWID(),
    NhuCauMe        nvarchar(100)   NOT NULL,
    ClusterOrder    tinyint         NOT NULL,           -- 1..6, thứ tự cột trên TV-2
    RouteStepOdr    int             NOT NULL,           -- = tRouteDS.Odr (group key đầu)
    GroupLabel      nvarchar(500)   NULL,               -- cache "Vs4c Tra lưng + Gắn nhãn vô lưng"
    Role            nvarchar(10)    NULL,               -- 'first' | 'last' | NULL
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tCluster_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    CONSTRAINT FK_tCluster_DemandRoot FOREIGN KEY (NhuCauMe)
        REFERENCES app.tDemandRoot(NhuCauMe) ON DELETE CASCADE,
    CONSTRAINT UQ_tCluster_Order UNIQUE (NhuCauMe, ClusterOrder),
    CONSTRAINT CK_tCluster_Order CHECK (ClusterOrder BETWEEN 1 AND 6),
    CONSTRAINT CK_tCluster_Role CHECK (Role IS NULL OR Role IN ('first', 'last'))
);
GO

-- ============== DAILY OPS ==============

-- B7: LĐ đầu ngày (1 dòng / ngày / tổ)
IF OBJECT_ID('app.tDailyHeadcount', 'U') IS NULL
CREATE TABLE app.tDailyHeadcount (
    ShtDate         date            NOT NULL,
    [LineNo]        tinyint         NOT NULL,
    Headcount       smallint        NOT NULL,
    Notes           nvarchar(200)   NULL,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tDailyHeadcount_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    CONSTRAINT PK_tDailyHeadcount PRIMARY KEY (ShtDate, [LineNo]),
    CONSTRAINT CK_tDailyHeadcount_Headcount CHECK (Headcount > 0)
);
GO

-- B8: Nguyên nhân & HĐKP theo mốc giờ
IF OBJECT_ID('app.tHourlyAction', 'U') IS NULL
CREATE TABLE app.tHourlyAction (
    HourlyAction_guid uniqueidentifier NOT NULL CONSTRAINT PK_tHourlyAction PRIMARY KEY
                                                CONSTRAINT DF_tHourlyAction_guid DEFAULT NEWID(),
    ShtDate         date            NOT NULL,
    [LineNo]        tinyint         NOT NULL,
    PlanMaster_guid uniqueidentifier NOT NULL,
    Slot            tinyint         NOT NULL,           -- 1..5 theo SHIFT_SLOTS
    RootCause       nvarchar(500)   NOT NULL,
    CAPAction       nvarchar(500)   NULL,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tHourlyAction_CreatedAt DEFAULT SYSDATETIME(),
    CreatedBy       nvarchar(50)    NULL,
    CONSTRAINT FK_tHourlyAction_PlanMaster FOREIGN KEY (PlanMaster_guid)
        REFERENCES app.tPlanMaster(PlanMaster_guid),
    CONSTRAINT CK_tHourlyAction_Slot CHECK (Slot BETWEEN 1 AND 5)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tHourlyAction_Date_Line' AND object_id = OBJECT_ID('app.tHourlyAction'))
    CREATE INDEX IX_tHourlyAction_Date_Line ON app.tHourlyAction(ShtDate, [LineNo]);
GO

-- ============== USERS ==============

IF OBJECT_ID('app.tUser', 'U') IS NULL
CREATE TABLE app.tUser (
    UserID          nvarchar(50)    NOT NULL CONSTRAINT PK_tUser PRIMARY KEY,
    DisplayName     nvarchar(100)   NULL,
    PasswordHash    nvarchar(200)   NULL,
    Role            nvarchar(30)    NOT NULL CONSTRAINT DF_tUser_Role DEFAULT 'admin',
    IsActive        bit             NOT NULL CONSTRAINT DF_tUser_IsActive DEFAULT 1,
    CreatedAt       datetime2(0)    NOT NULL CONSTRAINT DF_tUser_CreatedAt DEFAULT SYSDATETIME()
);
GO

-- Seed admin (idempotent)
IF NOT EXISTS (SELECT 1 FROM app.tUser WHERE UserID = 'admin')
    INSERT INTO app.tUser (UserID, DisplayName, Role) VALUES ('admin', N'Administrator', 'admin');
GO

PRINT '✓ Migration 001 applied.';
GO
