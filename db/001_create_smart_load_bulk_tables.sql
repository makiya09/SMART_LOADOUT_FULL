-- ============================================================
--  Smart Load Bulk — Database Creation Script
--  ออกแบบโดย: Shuri | วันที่: 2026-05-13 | Version: 1.0
--  Database  : SmartLoadBulkDB
--  Schema    : slb
--  SQL Server: 2019+
-- ============================================================
-- วิธีรัน:
--   1. เปิด SSMS แล้วเชื่อมกับ SQL Server
--   2. รัน Script นี้ทั้งหมด (F5)
--   3. ตรวจสอบว่า Messages ไม่มี Error
-- ============================================================
-- Rollback: ดูด้านล่างสุดของไฟล์นี้
-- ============================================================

USE master;
GO

-- สร้าง Database ถ้ายังไม่มี
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SmartLoadBulkDB')
BEGIN
    CREATE DATABASE SmartLoadBulkDB
    COLLATE Thai_CI_AS;
    PRINT 'Created database: SmartLoadBulkDB';
END
GO

USE SmartLoadBulkDB;
GO

-- ============================================================
-- SECTION 1: Schema
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'slb')
BEGIN
    EXEC('CREATE SCHEMA slb');
    PRINT 'Created schema: slb';
END
GO

-- ============================================================
-- SECTION 2: Tables (เรียงตาม Dependency)
-- ============================================================

PRINT '-- Creating Tables...';
GO

-- --------------------------------------------------------
-- 2.01 Users
-- --------------------------------------------------------
IF OBJECT_ID('slb.Users', 'U') IS NULL
CREATE TABLE slb.Users (
    UserId       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Username     VARCHAR(50)      NOT NULL,
    PasswordHash VARCHAR(256)     NOT NULL,
    FullName     NVARCHAR(100)    NOT NULL,
    Email        VARCHAR(150)     NULL,
    Role         VARCHAR(15)      NOT NULL CONSTRAINT CK_Users_Role
                                  CHECK (Role IN ('ADMIN','SUPERVISOR','OPERATOR','VIEWER')),
    IsActive     BIT              NOT NULL DEFAULT 1,
    LastLoginAt  DATETIME2        NULL,
    CreatedAt    DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt    DATETIME2        NULL,
    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT UQ_Users_Email    UNIQUE (Email)
);
GO

-- --------------------------------------------------------
-- 2.02 Customers
-- --------------------------------------------------------
IF OBJECT_ID('slb.Customers', 'U') IS NULL
CREATE TABLE slb.Customers (
    CustomerId    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    CustomerCode  VARCHAR(20)      NOT NULL,
    CustomerName  NVARCHAR(150)    NOT NULL,
    ContactPerson NVARCHAR(100)    NULL,
    Phone         VARCHAR(20)      NULL,
    IsActive      BIT              NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerId),
    CONSTRAINT UQ_Customers_Code UNIQUE (CustomerCode)
);
GO

-- --------------------------------------------------------
-- 2.03 Products
-- --------------------------------------------------------
IF OBJECT_ID('slb.Products', 'U') IS NULL
CREATE TABLE slb.Products (
    ProductId     UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ProductCode   VARCHAR(20)      NOT NULL,
    ProductName   NVARCHAR(150)    NOT NULL,
    Unit          NVARCHAR(10)     NOT NULL,
    MinStock      DECIMAL(12,3)    NOT NULL DEFAULT 0,
    CriticalStock DECIMAL(12,3)    NOT NULL DEFAULT 0,
    MaxStock      DECIMAL(12,3)    NOT NULL DEFAULT 0,
    IsActive      BIT              NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Products PRIMARY KEY (ProductId),
    CONSTRAINT UQ_Products_Code UNIQUE (ProductCode)
);
GO

-- --------------------------------------------------------
-- 2.04 Trucks
-- --------------------------------------------------------
IF OBJECT_ID('slb.Trucks', 'U') IS NULL
CREATE TABLE slb.Trucks (
    TruckId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    LicensePlate VARCHAR(20)      NOT NULL,
    TruckType    VARCHAR(10)      NOT NULL CONSTRAINT CK_Trucks_Type
                                  CHECK (TruckType IN ('TRAILER','TANKER','TIPPER','SILO','GENERAL')),
    MaxCapacity  DECIMAL(10,3)    NOT NULL,
    CompanyName  NVARCHAR(150)    NULL,
    IsActive     BIT              NOT NULL DEFAULT 1,
    CreatedAt    DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt    DATETIME2        NULL,
    CONSTRAINT PK_Trucks PRIMARY KEY (TruckId),
    CONSTRAINT UQ_Trucks_Plate UNIQUE (LicensePlate)
);
GO

-- --------------------------------------------------------
-- 2.05 Drivers
-- --------------------------------------------------------
IF OBJECT_ID('slb.Drivers', 'U') IS NULL
CREATE TABLE slb.Drivers (
    DriverId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    FullName      NVARCHAR(100)    NOT NULL,
    LicenseNo     VARCHAR(20)      NOT NULL,
    LicenseExpiry DATE             NOT NULL,
    Phone         VARCHAR(20)      NULL,
    IsActive      BIT              NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Drivers PRIMARY KEY (DriverId),
    CONSTRAINT UQ_Drivers_License UNIQUE (LicenseNo)
);
GO

-- --------------------------------------------------------
-- 2.06 Silos
-- --------------------------------------------------------
IF OBJECT_ID('slb.Silos', 'U') IS NULL
CREATE TABLE slb.Silos (
    SiloId    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    SiloCode  VARCHAR(10)      NOT NULL,
    SiloName  NVARCHAR(100)    NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    Capacity  DECIMAL(12,3)    NOT NULL,
    IsActive  BIT              NOT NULL DEFAULT 1,
    CONSTRAINT PK_Silos PRIMARY KEY (SiloId),
    CONSTRAINT UQ_Silos_Code UNIQUE (SiloCode)
);
GO

-- --------------------------------------------------------
-- 2.07 Inventory
-- --------------------------------------------------------
IF OBJECT_ID('slb.Inventory', 'U') IS NULL
CREATE TABLE slb.Inventory (
    InventoryId    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ProductId      UNIQUEIDENTIFIER NOT NULL,
    SiloId         UNIQUEIDENTIFIER NOT NULL,
    CurrentStock   DECIMAL(12,3)    NOT NULL DEFAULT 0,
    ReservedStock  DECIMAL(12,3)    NOT NULL DEFAULT 0,
    UpdatedAt      DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Inventory PRIMARY KEY (InventoryId),
    CONSTRAINT UQ_Inventory_Silo UNIQUE (SiloId)
);
GO

-- --------------------------------------------------------
-- 2.08 InventoryLogs
-- --------------------------------------------------------
IF OBJECT_ID('slb.InventoryLogs', 'U') IS NULL
CREATE TABLE slb.InventoryLogs (
    LogId       BIGINT           NOT NULL IDENTITY(1,1),
    ProductId   UNIQUEIDENTIFIER NOT NULL,
    SiloId      UNIQUEIDENTIFIER NOT NULL,
    ChangeType  VARCHAR(15)      NOT NULL CONSTRAINT CK_InvLogs_Type
                                 CHECK (ChangeType IN ('IN','OUT','ADJUST','RESERVE','UNRESERVE')),
    Qty         DECIMAL(12,3)    NOT NULL,
    BeforeStock DECIMAL(12,3)    NOT NULL,
    AfterStock  DECIMAL(12,3)    NOT NULL,
    RefType     VARCHAR(20)      NULL,
    RefId       UNIQUEIDENTIFIER NULL,
    Remark      NVARCHAR(500)    NULL,
    CreatedBy   UNIQUEIDENTIFIER NULL,
    CreatedAt   DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_InventoryLogs PRIMARY KEY (LogId)
);
GO

-- --------------------------------------------------------
-- 2.09 TruckDriverMap
-- --------------------------------------------------------
IF OBJECT_ID('slb.TruckDriverMap', 'U') IS NULL
CREATE TABLE slb.TruckDriverMap (
    MapId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    TruckId    UNIQUEIDENTIFIER NOT NULL,
    DriverId   UNIQUEIDENTIFIER NOT NULL,
    IsActive   BIT              NOT NULL DEFAULT 1,
    AssignedAt DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_TruckDriverMap PRIMARY KEY (MapId)
);
GO

-- --------------------------------------------------------
-- 2.10 Orders
-- --------------------------------------------------------
IF OBJECT_ID('slb.Orders', 'U') IS NULL
CREATE TABLE slb.Orders (
    OrderId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    OrderCode    VARCHAR(20)      NOT NULL,
    CustomerId   UNIQUEIDENTIFIER NOT NULL,
    OrderDate    DATE             NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    RequiredDate DATE             NOT NULL,
    Status       VARCHAR(12)      NOT NULL DEFAULT 'DRAFT'
                                  CONSTRAINT CK_Orders_Status
                                  CHECK (Status IN ('DRAFT','CONFIRMED','QUEUED','LOADING','COMPLETED','CANCELLED')),
    TotalWeight  DECIMAL(12,3)    NULL,
    Remark       NVARCHAR(500)    NULL,
    CreatedBy    UNIQUEIDENTIFIER NULL,
    CreatedAt    DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt    DATETIME2        NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderId),
    CONSTRAINT UQ_Orders_Code UNIQUE (OrderCode)
);
GO

-- --------------------------------------------------------
-- 2.11 OrderItems
-- --------------------------------------------------------
IF OBJECT_ID('slb.OrderItems', 'U') IS NULL
CREATE TABLE slb.OrderItems (
    ItemId       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    OrderId      UNIQUEIDENTIFIER NOT NULL,
    ProductId    UNIQUEIDENTIFIER NOT NULL,
    RequestedQty DECIMAL(12,3)    NOT NULL,
    ActualQty    DECIMAL(12,3)    NULL,
    Unit         NVARCHAR(10)     NOT NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY (ItemId)
);
GO

-- --------------------------------------------------------
-- 2.12 LoadQueues
-- --------------------------------------------------------
IF OBJECT_ID('slb.LoadQueues', 'U') IS NULL
CREATE TABLE slb.LoadQueues (
    QueueId     UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    OrderId     UNIQUEIDENTIFIER NOT NULL,
    TruckId     UNIQUEIDENTIFIER NOT NULL,
    DriverId    UNIQUEIDENTIFIER NOT NULL,
    Priority    TINYINT          NOT NULL DEFAULT 5,
    Status      VARCHAR(12)      NOT NULL DEFAULT 'WAITING'
                                 CONSTRAINT CK_Queue_Status
                                 CHECK (Status IN ('WAITING','CALLED','DOCKED','LOADING','DONE','CANCELLED')),
    EnqueuedAt  DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CalledAt    DATETIME2        NULL,
    DockedAt    DATETIME2        NULL,
    CompletedAt DATETIME2        NULL,
    Remark      NVARCHAR(300)    NULL,
    CONSTRAINT PK_LoadQueues PRIMARY KEY (QueueId)
);
GO

-- --------------------------------------------------------
-- 2.13 Bays (สร้างก่อน ยังไม่ใส่ FK CurrentQueueId)
-- --------------------------------------------------------
IF OBJECT_ID('slb.Bays', 'U') IS NULL
CREATE TABLE slb.Bays (
    BayId          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    BayCode        VARCHAR(10)      NOT NULL,
    BayName        NVARCHAR(100)    NOT NULL,
    BayType        VARCHAR(15)      NOT NULL CONSTRAINT CK_Bays_Type
                                    CHECK (BayType IN ('BULK_DRY','BULK_LIQUID','GENERAL')),
    MaxCapacity    DECIMAL(10,3)    NOT NULL,
    IsActive       BIT              NOT NULL DEFAULT 1,
    CurrentQueueId UNIQUEIDENTIFIER NULL,
    Status         VARCHAR(15)      NOT NULL DEFAULT 'AVAILABLE'
                                    CONSTRAINT CK_Bays_Status
                                    CHECK (Status IN ('AVAILABLE','CALLING','DOCKED','LOADING','CHECKING','ERROR','MAINTENANCE')),
    LastUpdatedAt  DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Bays PRIMARY KEY (BayId),
    CONSTRAINT UQ_Bays_Code UNIQUE (BayCode)
);
GO

-- --------------------------------------------------------
-- 2.14 BayLogs
-- --------------------------------------------------------
IF OBJECT_ID('slb.BayLogs', 'U') IS NULL
CREATE TABLE slb.BayLogs (
    LogId     BIGINT           NOT NULL IDENTITY(1,1),
    BayId     UNIQUEIDENTIFIER NOT NULL,
    QueueId   UNIQUEIDENTIFIER NULL,
    EventType VARCHAR(25)      NOT NULL CONSTRAINT CK_BayLogs_Type
                               CHECK (EventType IN ('STATUS_CHANGE','TRUCK_CALLED','TRUCK_DOCKED',
                                                    'LOAD_STARTED','LOAD_COMPLETED','EMERGENCY','RESET')),
    EventData NVARCHAR(1000)   NULL,
    CreatedBy UNIQUEIDENTIFIER NULL,
    CreatedAt DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_BayLogs PRIMARY KEY (LogId)
);
GO

-- --------------------------------------------------------
-- 2.15 HardwareDevices
-- --------------------------------------------------------
IF OBJECT_ID('slb.HardwareDevices', 'U') IS NULL
CREATE TABLE slb.HardwareDevices (
    DeviceId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    DeviceCode    VARCHAR(20)      NOT NULL,
    DeviceName    NVARCHAR(100)    NOT NULL,
    DeviceType    VARCHAR(20)      NOT NULL CONSTRAINT CK_HwDev_Type
                                   CHECK (DeviceType IN ('QR_SCANNER','RADAR','LOADING_PANEL','WEIGHT_SENSOR')),
    Location      NVARCHAR(100)    NULL,
    BayId         UNIQUEIDENTIFIER NULL,
    IpAddress     VARCHAR(15)      NULL,
    Port          INT              NULL,
    Protocol      VARCHAR(15)      NOT NULL CONSTRAINT CK_HwDev_Protocol
                                   CHECK (Protocol IN ('SERIAL','TCP','MODBUS_TCP','HID')),
    Status        VARCHAR(15)      NOT NULL DEFAULT 'OFFLINE'
                                   CONSTRAINT CK_HwDev_Status
                                   CHECK (Status IN ('ONLINE','OFFLINE','ERROR','MAINTENANCE')),
    LastHeartbeat DATETIME2        NULL,
    IsActive      BIT              NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt     DATETIME2        NULL,
    CONSTRAINT PK_HardwareDevices PRIMARY KEY (DeviceId),
    CONSTRAINT UQ_HwDev_Code UNIQUE (DeviceCode)
);
GO

-- --------------------------------------------------------
-- 2.16 LoadJobs
-- --------------------------------------------------------
IF OBJECT_ID('slb.LoadJobs', 'U') IS NULL
CREATE TABLE slb.LoadJobs (
    JobId        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    JobCode      VARCHAR(25)      NOT NULL,
    OrderId      UNIQUEIDENTIFIER NOT NULL,
    OrderItemId  UNIQUEIDENTIFIER NOT NULL,
    TruckId      UNIQUEIDENTIFIER NOT NULL,
    DriverId     UNIQUEIDENTIFIER NOT NULL,
    BayId        UNIQUEIDENTIFIER NOT NULL,
    ProductId    UNIQUEIDENTIFIER NOT NULL,
    SiloId       UNIQUEIDENTIFIER NULL,
    TargetWeight DECIMAL(10,3)    NOT NULL,
    ActualWeight DECIMAL(10,3)    NULL,
    TolerancePct DECIMAL(5,2)     NOT NULL DEFAULT 0.50,
    Status       VARCHAR(15)      NOT NULL DEFAULT 'CREATED'
                                  CONSTRAINT CK_Jobs_Status
                                  CHECK (Status IN ('CREATED','QR_ISSUED','QR_SCANNED',
                                                    'LOADING','PAUSED','COMPLETED','FAILED','CANCELLED')),
    StartedAt    DATETIME2        NULL,
    CompletedAt  DATETIME2        NULL,
    FailReason   NVARCHAR(300)    NULL,
    CreatedBy    UNIQUEIDENTIFIER NULL,
    CreatedAt    DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt    DATETIME2        NULL,
    CONSTRAINT PK_LoadJobs PRIMARY KEY (JobId),
    CONSTRAINT UQ_Jobs_Code UNIQUE (JobCode)
);
GO

-- --------------------------------------------------------
-- 2.17 LoadJobLogs
-- --------------------------------------------------------
IF OBJECT_ID('slb.LoadJobLogs', 'U') IS NULL
CREATE TABLE slb.LoadJobLogs (
    LogId         BIGINT           NOT NULL IDENTITY(1,1),
    JobId         UNIQUEIDENTIFIER NOT NULL,
    EventType     VARCHAR(20)      NOT NULL CONSTRAINT CK_JobLogs_Type
                                   CHECK (EventType IN ('WEIGHT_UPDATE','LOAD_START','LOAD_PAUSE',
                                                        'LOAD_RESUME','EMERGENCY_STOP','LOAD_COMPLETE')),
    CurrentWeight DECIMAL(10,3)    NULL,
    CreatedAt     DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_LoadJobLogs PRIMARY KEY (LogId)
);
GO

-- --------------------------------------------------------
-- 2.18 QrTokens
-- --------------------------------------------------------
IF OBJECT_ID('slb.QrTokens', 'U') IS NULL
CREATE TABLE slb.QrTokens (
    TokenId          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    JobId            UNIQUEIDENTIFIER NOT NULL,
    Token            VARCHAR(500)     NOT NULL,
    TokenHash        VARCHAR(64)      NOT NULL,
    IsUsed           BIT              NOT NULL DEFAULT 0,
    IsRevoked        BIT              NOT NULL DEFAULT 0,
    RevokeReason     NVARCHAR(200)    NULL,
    IssuedAt         DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    ExpiredAt        DATETIME2        NOT NULL,
    ScannedAt        DATETIME2        NULL,
    ScannedByDeviceId UNIQUEIDENTIFIER NULL,
    CONSTRAINT PK_QrTokens PRIMARY KEY (TokenId),
    CONSTRAINT UQ_QrTokens_Hash UNIQUE (TokenHash)
);
GO

-- --------------------------------------------------------
-- 2.19 LoadChecklists
-- --------------------------------------------------------
IF OBJECT_ID('slb.LoadChecklists', 'U') IS NULL
CREATE TABLE slb.LoadChecklists (
    ChecklistId       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    JobId             UNIQUEIDENTIFIER NOT NULL,
    WeightVerified    BIT              NOT NULL DEFAULT 0,
    ActualWeight      DECIMAL(10,3)    NULL,
    WeightDiff        DECIMAL(10,3)    NULL,
    QrVerified        BIT              NOT NULL DEFAULT 0,
    DocumentsVerified BIT              NOT NULL DEFAULT 0,
    SealVerified      BIT              NOT NULL DEFAULT 0,
    DriverVerified    BIT              NOT NULL DEFAULT 0,
    VerifiedBy        UNIQUEIDENTIFIER NULL,
    VerifiedAt        DATETIME2        NULL,
    ReleasedBy        UNIQUEIDENTIFIER NULL,
    ReleasedAt        DATETIME2        NULL,
    Remark            NVARCHAR(500)    NULL,
    CONSTRAINT PK_LoadChecklists PRIMARY KEY (ChecklistId),
    CONSTRAINT UQ_Checklist_Job UNIQUE (JobId)
);
GO

-- --------------------------------------------------------
-- 2.20 ChecklistItems
-- --------------------------------------------------------
IF OBJECT_ID('slb.ChecklistItems', 'U') IS NULL
CREATE TABLE slb.ChecklistItems (
    ItemId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    ChecklistId UNIQUEIDENTIFIER NOT NULL,
    ItemCode    VARCHAR(20)      NOT NULL,
    ItemName    NVARCHAR(100)    NOT NULL,
    IsRequired  BIT              NOT NULL DEFAULT 1,
    IsChecked   BIT              NOT NULL DEFAULT 0,
    CheckedBy   UNIQUEIDENTIFIER NULL,
    CheckedAt   DATETIME2        NULL,
    Remark      NVARCHAR(200)    NULL,
    CONSTRAINT PK_ChecklistItems PRIMARY KEY (ItemId)
);
GO

-- --------------------------------------------------------
-- 2.21 HardwareEvents
-- --------------------------------------------------------
IF OBJECT_ID('slb.HardwareEvents', 'U') IS NULL
CREATE TABLE slb.HardwareEvents (
    EventId      BIGINT           NOT NULL IDENTITY(1,1),
    DeviceId     UNIQUEIDENTIFIER NOT NULL,
    EventType    VARCHAR(20)      NOT NULL CONSTRAINT CK_HwEv_Type
                                  CHECK (EventType IN ('QR_SCANNED','VEHICLE_DETECTED','WEIGHT_UPDATE',
                                                       'PANEL_STATE','HEARTBEAT','ERROR')),
    Payload      NVARCHAR(2000)   NULL,
    IsProcessed  BIT              NOT NULL DEFAULT 0,
    ProcessedAt  DATETIME2        NULL,
    ErrorMessage NVARCHAR(500)    NULL,
    CreatedAt    DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_HardwareEvents PRIMARY KEY (EventId)
);
GO

-- --------------------------------------------------------
-- 2.22 NotificationLogs
-- --------------------------------------------------------
IF OBJECT_ID('slb.NotificationLogs', 'U') IS NULL
CREATE TABLE slb.NotificationLogs (
    NotifId       BIGINT        NOT NULL IDENTITY(1,1),
    NotifType     VARCHAR(30)   NOT NULL,
    Severity      VARCHAR(10)   NOT NULL CONSTRAINT CK_Notif_Severity
                                CHECK (Severity IN ('INFO','WARNING','ERROR','CRITICAL')),
    Title         NVARCHAR(200) NOT NULL,
    Message       NVARCHAR(1000) NOT NULL,
    RefType       VARCHAR(20)   NULL,
    RefId         UNIQUEIDENTIFIER NULL,
    Channel       VARCHAR(15)   NOT NULL CONSTRAINT CK_Notif_Channel
                                CHECK (Channel IN ('SIGNALR','EMAIL','LINE','ALL')),
    RecipientRole VARCHAR(20)   NULL,
    IsSent        BIT           NOT NULL DEFAULT 0,
    SentAt        DATETIME2     NULL,
    ErrorMessage  NVARCHAR(500) NULL,
    CreatedAt     DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_NotificationLogs PRIMARY KEY (NotifId)
);
GO

-- --------------------------------------------------------
-- 2.23 AuditLogs
-- --------------------------------------------------------
IF OBJECT_ID('slb.AuditLogs', 'U') IS NULL
CREATE TABLE slb.AuditLogs (
    AuditId   BIGINT           NOT NULL IDENTITY(1,1),
    TableName VARCHAR(50)      NOT NULL,
    RecordId  NVARCHAR(50)     NOT NULL,
    Action    VARCHAR(10)      NOT NULL CONSTRAINT CK_Audit_Action
                               CHECK (Action IN ('INSERT','UPDATE','DELETE')),
    OldValues NVARCHAR(MAX)    NULL,
    NewValues NVARCHAR(MAX)    NULL,
    ChangedBy UNIQUEIDENTIFIER NULL,
    ChangedAt DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    IpAddress VARCHAR(45)      NULL,
    CONSTRAINT PK_AuditLogs PRIMARY KEY (AuditId)
);
GO

PRINT '  Tables created.';
GO

-- ============================================================
-- SECTION 3: Foreign Keys
-- ============================================================

PRINT '-- Adding Foreign Keys...';
GO

-- Silos
ALTER TABLE slb.Silos      ADD CONSTRAINT FK_Silos_Products    FOREIGN KEY (ProductId)   REFERENCES slb.Products(ProductId);

-- Inventory
ALTER TABLE slb.Inventory  ADD CONSTRAINT FK_Inv_Products      FOREIGN KEY (ProductId)   REFERENCES slb.Products(ProductId);
ALTER TABLE slb.Inventory  ADD CONSTRAINT FK_Inv_Silos         FOREIGN KEY (SiloId)      REFERENCES slb.Silos(SiloId);

-- InventoryLogs
ALTER TABLE slb.InventoryLogs ADD CONSTRAINT FK_InvLog_Products FOREIGN KEY (ProductId)  REFERENCES slb.Products(ProductId);
ALTER TABLE slb.InventoryLogs ADD CONSTRAINT FK_InvLog_Silos    FOREIGN KEY (SiloId)     REFERENCES slb.Silos(SiloId);
ALTER TABLE slb.InventoryLogs ADD CONSTRAINT FK_InvLog_Users    FOREIGN KEY (CreatedBy)  REFERENCES slb.Users(UserId);

-- TruckDriverMap
ALTER TABLE slb.TruckDriverMap ADD CONSTRAINT FK_TDMap_Trucks  FOREIGN KEY (TruckId)    REFERENCES slb.Trucks(TruckId);
ALTER TABLE slb.TruckDriverMap ADD CONSTRAINT FK_TDMap_Drivers FOREIGN KEY (DriverId)   REFERENCES slb.Drivers(DriverId);

-- Orders
ALTER TABLE slb.Orders     ADD CONSTRAINT FK_Orders_Customers  FOREIGN KEY (CustomerId) REFERENCES slb.Customers(CustomerId);
ALTER TABLE slb.Orders     ADD CONSTRAINT FK_Orders_Users      FOREIGN KEY (CreatedBy)  REFERENCES slb.Users(UserId);

-- OrderItems
ALTER TABLE slb.OrderItems ADD CONSTRAINT FK_OrdItems_Orders   FOREIGN KEY (OrderId)    REFERENCES slb.Orders(OrderId);
ALTER TABLE slb.OrderItems ADD CONSTRAINT FK_OrdItems_Products FOREIGN KEY (ProductId)  REFERENCES slb.Products(ProductId);

-- LoadQueues
ALTER TABLE slb.LoadQueues ADD CONSTRAINT FK_Queue_Orders      FOREIGN KEY (OrderId)    REFERENCES slb.Orders(OrderId);
ALTER TABLE slb.LoadQueues ADD CONSTRAINT FK_Queue_Trucks      FOREIGN KEY (TruckId)    REFERENCES slb.Trucks(TruckId);
ALTER TABLE slb.LoadQueues ADD CONSTRAINT FK_Queue_Drivers     FOREIGN KEY (DriverId)   REFERENCES slb.Drivers(DriverId);

-- Bays (FK CurrentQueueId → LoadQueues เพิ่มหลัง)
ALTER TABLE slb.Bays       ADD CONSTRAINT FK_Bays_Queues       FOREIGN KEY (CurrentQueueId) REFERENCES slb.LoadQueues(QueueId);

-- BayLogs
ALTER TABLE slb.BayLogs    ADD CONSTRAINT FK_BayLogs_Bays      FOREIGN KEY (BayId)      REFERENCES slb.Bays(BayId);
ALTER TABLE slb.BayLogs    ADD CONSTRAINT FK_BayLogs_Queues    FOREIGN KEY (QueueId)    REFERENCES slb.LoadQueues(QueueId);
ALTER TABLE slb.BayLogs    ADD CONSTRAINT FK_BayLogs_Users     FOREIGN KEY (CreatedBy)  REFERENCES slb.Users(UserId);

-- HardwareDevices
ALTER TABLE slb.HardwareDevices ADD CONSTRAINT FK_HwDev_Bays   FOREIGN KEY (BayId)      REFERENCES slb.Bays(BayId);

-- LoadJobs
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Orders       FOREIGN KEY (OrderId)    REFERENCES slb.Orders(OrderId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_OrdItems     FOREIGN KEY (OrderItemId)REFERENCES slb.OrderItems(ItemId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Trucks       FOREIGN KEY (TruckId)    REFERENCES slb.Trucks(TruckId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Drivers      FOREIGN KEY (DriverId)   REFERENCES slb.Drivers(DriverId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Bays         FOREIGN KEY (BayId)      REFERENCES slb.Bays(BayId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Products     FOREIGN KEY (ProductId)  REFERENCES slb.Products(ProductId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Silos        FOREIGN KEY (SiloId)     REFERENCES slb.Silos(SiloId);
ALTER TABLE slb.LoadJobs   ADD CONSTRAINT FK_Jobs_Users        FOREIGN KEY (CreatedBy)  REFERENCES slb.Users(UserId);

-- LoadJobLogs
ALTER TABLE slb.LoadJobLogs ADD CONSTRAINT FK_JobLogs_Jobs     FOREIGN KEY (JobId)      REFERENCES slb.LoadJobs(JobId);

-- QrTokens
ALTER TABLE slb.QrTokens   ADD CONSTRAINT FK_QR_Jobs          FOREIGN KEY (JobId)      REFERENCES slb.LoadJobs(JobId);
ALTER TABLE slb.QrTokens   ADD CONSTRAINT FK_QR_Devices       FOREIGN KEY (ScannedByDeviceId) REFERENCES slb.HardwareDevices(DeviceId);

-- LoadChecklists
ALTER TABLE slb.LoadChecklists ADD CONSTRAINT FK_CL_Jobs       FOREIGN KEY (JobId)      REFERENCES slb.LoadJobs(JobId);
ALTER TABLE slb.LoadChecklists ADD CONSTRAINT FK_CL_VerifiedBy FOREIGN KEY (VerifiedBy) REFERENCES slb.Users(UserId);
ALTER TABLE slb.LoadChecklists ADD CONSTRAINT FK_CL_ReleasedBy FOREIGN KEY (ReleasedBy) REFERENCES slb.Users(UserId);

-- ChecklistItems
ALTER TABLE slb.ChecklistItems ADD CONSTRAINT FK_CI_Checklists FOREIGN KEY (ChecklistId) REFERENCES slb.LoadChecklists(ChecklistId);
ALTER TABLE slb.ChecklistItems ADD CONSTRAINT FK_CI_Users      FOREIGN KEY (CheckedBy)   REFERENCES slb.Users(UserId);

-- HardwareEvents
ALTER TABLE slb.HardwareEvents ADD CONSTRAINT FK_HwEv_Devices  FOREIGN KEY (DeviceId)   REFERENCES slb.HardwareDevices(DeviceId);

PRINT '  Foreign Keys added.';
GO

-- ============================================================
-- SECTION 4: Indexes
-- ============================================================

PRINT '-- Creating Indexes...';
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE INDEX IX_Orders_Status       ON slb.Orders(Status, CreatedAt DESC);
CREATE INDEX IX_Orders_CustomerId   ON slb.Orders(CustomerId);
CREATE INDEX IX_Orders_RequiredDate ON slb.Orders(RequiredDate);

CREATE INDEX IX_Queue_Status        ON slb.LoadQueues(Status, Priority, EnqueuedAt);
CREATE INDEX IX_Queue_TruckId       ON slb.LoadQueues(TruckId);
CREATE INDEX IX_Queue_OrderId       ON slb.LoadQueues(OrderId);

CREATE INDEX IX_Jobs_Status         ON slb.LoadJobs(Status, CreatedAt DESC);
CREATE INDEX IX_Jobs_BayId          ON slb.LoadJobs(BayId);
CREATE INDEX IX_Jobs_OrderId        ON slb.LoadJobs(OrderId);

CREATE INDEX IX_JobLogs_JobId       ON slb.LoadJobLogs(JobId, CreatedAt DESC);

CREATE INDEX IX_Inv_ProductId       ON slb.Inventory(ProductId);
CREATE INDEX IX_InvLog_ProductId    ON slb.InventoryLogs(ProductId, CreatedAt DESC);
CREATE INDEX IX_InvLog_SiloId       ON slb.InventoryLogs(SiloId, CreatedAt DESC);

CREATE INDEX IX_QR_TokenHash        ON slb.QrTokens(TokenHash);
CREATE INDEX IX_QR_JobId            ON slb.QrTokens(JobId);

CREATE INDEX IX_HwEv_DeviceId       ON slb.HardwareEvents(DeviceId, CreatedAt DESC);
CREATE INDEX IX_HwEv_Unprocessed    ON slb.HardwareEvents(IsProcessed, CreatedAt) WHERE IsProcessed = 0;

CREATE INDEX IX_Notif_Unsent        ON slb.NotificationLogs(IsSent, CreatedAt) WHERE IsSent = 0;
CREATE INDEX IX_Audit_TableName     ON slb.AuditLogs(TableName, ChangedAt DESC);

PRINT '  Indexes created.';
GO

-- ============================================================
-- SECTION 5: Views
-- ============================================================

PRINT '-- Creating Views...';
GO

-- --------------------------------------------------------
-- vw_InventoryDashboard — Stock รวมต่อ Product
-- --------------------------------------------------------
IF OBJECT_ID('slb.vw_InventoryDashboard', 'V') IS NOT NULL DROP VIEW slb.vw_InventoryDashboard;
GO
CREATE VIEW slb.vw_InventoryDashboard AS
SELECT
    p.ProductId,
    p.ProductCode,
    p.ProductName,
    p.Unit,
    p.MinStock,
    p.CriticalStock,
    p.MaxStock,
    SUM(i.CurrentStock)   AS TotalStock,
    SUM(i.ReservedStock)  AS TotalReserved,
    SUM(i.CurrentStock - i.ReservedStock) AS AvailableStock,
    CASE
        WHEN SUM(i.CurrentStock) <= p.CriticalStock THEN 'CRITICAL'
        WHEN SUM(i.CurrentStock) <= p.MinStock      THEN 'LOW'
        WHEN SUM(i.CurrentStock) >= p.MaxStock      THEN 'FULL'
        ELSE 'NORMAL'
    END AS StockAlert,
    COUNT(s.SiloId) AS SiloCount
FROM slb.Products p
LEFT JOIN slb.Silos s     ON s.ProductId = p.ProductId AND s.IsActive = 1
LEFT JOIN slb.Inventory i ON i.SiloId = s.SiloId
WHERE p.IsActive = 1
GROUP BY p.ProductId, p.ProductCode, p.ProductName, p.Unit,
         p.MinStock, p.CriticalStock, p.MaxStock;
GO

-- --------------------------------------------------------
-- vw_QueueBoard — Queue Board ปัจจุบัน
-- --------------------------------------------------------
IF OBJECT_ID('slb.vw_QueueBoard', 'V') IS NOT NULL DROP VIEW slb.vw_QueueBoard;
GO
CREATE VIEW slb.vw_QueueBoard AS
SELECT
    q.QueueId,
    q.Status,
    q.Priority,
    q.EnqueuedAt,
    q.CalledAt,
    q.DockedAt,
    o.OrderId,
    o.OrderCode,
    c.CustomerName,
    t.LicensePlate,
    t.TruckType,
    t.MaxCapacity,
    d.FullName     AS DriverName,
    d.Phone        AS DriverPhone,
    b.BayCode,
    b.BayName,
    DATEDIFF(MINUTE, q.EnqueuedAt, SYSDATETIME()) AS WaitingMinutes
FROM slb.LoadQueues q
JOIN slb.Orders   o ON o.OrderId   = q.OrderId
JOIN slb.Customers c ON c.CustomerId = o.CustomerId
JOIN slb.Trucks   t ON t.TruckId   = q.TruckId
JOIN slb.Drivers  d ON d.DriverId  = q.DriverId
LEFT JOIN slb.Bays b ON b.CurrentQueueId = q.QueueId
WHERE q.Status NOT IN ('DONE','CANCELLED');
GO

-- --------------------------------------------------------
-- vw_BayMonitor — สถานะ Bay + Job ปัจจุบัน
-- --------------------------------------------------------
IF OBJECT_ID('slb.vw_BayMonitor', 'V') IS NOT NULL DROP VIEW slb.vw_BayMonitor;
GO
CREATE VIEW slb.vw_BayMonitor AS
SELECT
    b.BayId,
    b.BayCode,
    b.BayName,
    b.BayType,
    b.MaxCapacity,
    b.Status       AS BayStatus,
    b.LastUpdatedAt,
    q.QueueId,
    t.LicensePlate,
    d.FullName     AS DriverName,
    o.OrderCode,
    c.CustomerName,
    j.JobId,
    j.JobCode,
    j.TargetWeight,
    j.ActualWeight,
    j.Status       AS JobStatus,
    j.StartedAt,
    ISNULL(j.ActualWeight / NULLIF(j.TargetWeight, 0) * 100, 0) AS LoadPercent
FROM slb.Bays b
LEFT JOIN slb.LoadQueues q  ON q.QueueId   = b.CurrentQueueId
LEFT JOIN slb.Trucks   t    ON t.TruckId   = q.TruckId
LEFT JOIN slb.Drivers  d    ON d.DriverId  = q.DriverId
LEFT JOIN slb.Orders   o    ON o.OrderId   = q.OrderId
LEFT JOIN slb.Customers c   ON c.CustomerId = o.CustomerId
LEFT JOIN slb.LoadJobs j    ON j.BayId     = b.BayId
                            AND j.Status   IN ('QR_ISSUED','QR_SCANNED','LOADING','PAUSED')
WHERE b.IsActive = 1;
GO

-- --------------------------------------------------------
-- vw_ActiveLoadJobs — Jobs ที่กำลัง Active
-- --------------------------------------------------------
IF OBJECT_ID('slb.vw_ActiveLoadJobs', 'V') IS NOT NULL DROP VIEW slb.vw_ActiveLoadJobs;
GO
CREATE VIEW slb.vw_ActiveLoadJobs AS
SELECT
    j.JobId,
    j.JobCode,
    j.Status,
    j.TargetWeight,
    j.ActualWeight,
    j.TolerancePct,
    j.StartedAt,
    b.BayCode,
    b.BayName,
    t.LicensePlate,
    p.ProductName,
    p.Unit,
    ISNULL(j.ActualWeight / NULLIF(j.TargetWeight, 0) * 100, 0) AS LoadPercent,
    DATEDIFF(MINUTE, j.StartedAt, SYSDATETIME()) AS LoadingMinutes
FROM slb.LoadJobs j
JOIN slb.Bays     b ON b.BayId     = j.BayId
JOIN slb.Trucks   t ON t.TruckId   = j.TruckId
JOIN slb.Products p ON p.ProductId = j.ProductId
WHERE j.Status IN ('QR_ISSUED','QR_SCANNED','LOADING','PAUSED');
GO

-- --------------------------------------------------------
-- vw_DailySummary — สรุปประจำวัน
-- --------------------------------------------------------
IF OBJECT_ID('slb.vw_DailySummary', 'V') IS NOT NULL DROP VIEW slb.vw_DailySummary;
GO
CREATE VIEW slb.vw_DailySummary AS
SELECT
    CAST(j.CompletedAt AS DATE) AS LoadDate,
    p.ProductCode,
    p.ProductName,
    COUNT(j.JobId)              AS TotalJobs,
    SUM(j.ActualWeight)         AS TotalActualWeight,
    SUM(j.TargetWeight)         AS TotalTargetWeight,
    p.Unit
FROM slb.LoadJobs j
JOIN slb.Products p ON p.ProductId = j.ProductId
WHERE j.Status = 'COMPLETED'
  AND j.CompletedAt IS NOT NULL
GROUP BY CAST(j.CompletedAt AS DATE), p.ProductCode, p.ProductName, p.Unit;
GO

PRINT '  Views created.';
GO

-- ============================================================
-- SECTION 6: Stored Procedures
-- ============================================================

PRINT '-- Creating Stored Procedures...';
GO

-- --------------------------------------------------------
-- sp_GetInventoryDashboard
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_GetInventoryDashboard', 'P') IS NOT NULL DROP PROCEDURE slb.sp_GetInventoryDashboard;
GO
CREATE PROCEDURE slb.sp_GetInventoryDashboard
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM slb.vw_InventoryDashboard
    ORDER BY StockAlert DESC, ProductCode;
END
GO

-- --------------------------------------------------------
-- sp_GetQueueBoard
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_GetQueueBoard', 'P') IS NOT NULL DROP PROCEDURE slb.sp_GetQueueBoard;
GO
CREATE PROCEDURE slb.sp_GetQueueBoard
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM slb.vw_QueueBoard
    ORDER BY Priority ASC, EnqueuedAt ASC;
END
GO

-- --------------------------------------------------------
-- sp_GetBayStatus
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_GetBayStatus', 'P') IS NOT NULL DROP PROCEDURE slb.sp_GetBayStatus;
GO
CREATE PROCEDURE slb.sp_GetBayStatus
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM slb.vw_BayMonitor
    ORDER BY BayCode;
END
GO

-- --------------------------------------------------------
-- sp_EnqueueTruck — เพิ่มรถเข้าคิว + Reserve Stock
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_EnqueueTruck', 'P') IS NOT NULL DROP PROCEDURE slb.sp_EnqueueTruck;
GO
CREATE PROCEDURE slb.sp_EnqueueTruck
    @OrderId   UNIQUEIDENTIFIER,
    @TruckId   UNIQUEIDENTIFIER,
    @DriverId  UNIQUEIDENTIFIER,
    @Priority  TINYINT = 5,
    @CreatedBy UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- ตรวจสอบ Order
        IF NOT EXISTS (SELECT 1 FROM slb.Orders WHERE OrderId = @OrderId AND Status = 'CONFIRMED')
        BEGIN
            RAISERROR('Order ไม่พบ หรือสถานะไม่ใช่ CONFIRMED', 16, 1);
            RETURN;
        END

        -- ตรวจสอบรถและคนขับ
        IF NOT EXISTS (SELECT 1 FROM slb.Trucks  WHERE TruckId  = @TruckId  AND IsActive = 1)
            RAISERROR('ไม่พบรถ หรือรถไม่ Active', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM slb.Drivers WHERE DriverId = @DriverId AND IsActive = 1)
            RAISERROR('ไม่พบคนขับ หรือคนขับไม่ Active', 16, 1);

        -- Reserve Stock สำหรับทุก Item ใน Order
        UPDATE inv
        SET inv.ReservedStock = inv.ReservedStock + oi.RequestedQty,
            inv.UpdatedAt     = SYSDATETIME()
        FROM slb.Inventory inv
        JOIN slb.Silos     s   ON s.SiloId    = inv.SiloId
        JOIN slb.OrderItems oi ON oi.ProductId = s.ProductId
        WHERE oi.OrderId = @OrderId
          AND (inv.CurrentStock - inv.ReservedStock) >= oi.RequestedQty;

        -- บันทึก InventoryLog
        INSERT INTO slb.InventoryLogs (ProductId, SiloId, ChangeType, Qty, BeforeStock, AfterStock, RefType, RefId, Remark, CreatedBy)
        SELECT
            s.ProductId,
            inv.SiloId,
            'RESERVE',
            oi.RequestedQty,
            inv.CurrentStock,
            inv.CurrentStock,
            'ORDER',
            @OrderId,
            N'Reserve สำหรับ Order',
            @CreatedBy
        FROM slb.Inventory inv
        JOIN slb.Silos     s   ON s.SiloId    = inv.SiloId
        JOIN slb.OrderItems oi ON oi.ProductId = s.ProductId
        WHERE oi.OrderId = @OrderId;

        -- สร้าง Queue
        DECLARE @QueueId UNIQUEIDENTIFIER = NEWID();
        INSERT INTO slb.LoadQueues (QueueId, OrderId, TruckId, DriverId, Priority)
        VALUES (@QueueId, @OrderId, @TruckId, @DriverId, @Priority);

        -- อัปเดต Order Status
        UPDATE slb.Orders SET Status = 'QUEUED', UpdatedAt = SYSDATETIME()
        WHERE OrderId = @OrderId;

        COMMIT TRANSACTION;
        SELECT @QueueId AS QueueId, 'SUCCESS' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(500) = ERROR_MESSAGE();
        SELECT NULL AS QueueId, 'ERROR' AS Result, @ErrMsg AS ErrorMessage;
    END CATCH
END
GO

-- --------------------------------------------------------
-- sp_CallTruckToBay — เรียกรถเข้า Bay
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_CallTruckToBay', 'P') IS NOT NULL DROP PROCEDURE slb.sp_CallTruckToBay;
GO
CREATE PROCEDURE slb.sp_CallTruckToBay
    @QueueId   UNIQUEIDENTIFIER,
    @BayId     UNIQUEIDENTIFIER,
    @CalledBy  UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM slb.LoadQueues WHERE QueueId = @QueueId AND Status = 'WAITING')
            RAISERROR('Queue ไม่พบ หรือสถานะไม่ใช่ WAITING', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM slb.Bays WHERE BayId = @BayId AND Status = 'AVAILABLE' AND IsActive = 1)
            RAISERROR('Bay ไม่พบ หรือสถานะไม่ใช่ AVAILABLE', 16, 1);

        DECLARE @Now DATETIME2 = SYSDATETIME();

        UPDATE slb.LoadQueues SET Status = 'CALLED', CalledAt = @Now WHERE QueueId = @QueueId;
        UPDATE slb.Bays SET Status = 'CALLING', CurrentQueueId = @QueueId, LastUpdatedAt = @Now WHERE BayId = @BayId;

        INSERT INTO slb.BayLogs (BayId, QueueId, EventType, EventData, CreatedBy)
        VALUES (@BayId, @QueueId, 'TRUCK_CALLED',
                '{"action":"TRUCK_CALLED","queueId":"' + CAST(@QueueId AS VARCHAR(36)) + '"}',
                @CalledBy);

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'ERROR' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- --------------------------------------------------------
-- sp_CreateLoadJob — สร้าง LoadJob + ออก QR Token Placeholder
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_CreateLoadJob', 'P') IS NOT NULL DROP PROCEDURE slb.sp_CreateLoadJob;
GO
CREATE PROCEDURE slb.sp_CreateLoadJob
    @QueueId     UNIQUEIDENTIFIER,
    @SiloId      UNIQUEIDENTIFIER = NULL,
    @TolerancePct DECIMAL(5,2)   = 0.50,
    @CreatedBy   UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- ดึงข้อมูลจาก Queue + Order
        DECLARE @OrderId     UNIQUEIDENTIFIER,
                @OrderItemId UNIQUEIDENTIFIER,
                @TruckId     UNIQUEIDENTIFIER,
                @DriverId    UNIQUEIDENTIFIER,
                @BayId       UNIQUEIDENTIFIER,
                @ProductId   UNIQUEIDENTIFIER,
                @TargetWeight DECIMAL(10,3);

        SELECT
            @OrderId     = q.OrderId,
            @TruckId     = q.TruckId,
            @DriverId    = q.DriverId,
            @BayId       = b.BayId,
            @OrderItemId = oi.ItemId,
            @ProductId   = oi.ProductId,
            @TargetWeight = oi.RequestedQty
        FROM slb.LoadQueues q
        JOIN slb.Bays       b  ON b.CurrentQueueId = q.QueueId
        JOIN slb.OrderItems oi ON oi.OrderId        = q.OrderId
        WHERE q.QueueId = @QueueId
          AND q.Status  = 'DOCKED';

        IF @OrderId IS NULL
            RAISERROR('Queue ไม่พบ หรือรถยังไม่ได้เข้า Bay (DOCKED)', 16, 1);

        -- สร้าง JobCode
        DECLARE @JobSeq INT;
        SELECT @JobSeq = ISNULL(COUNT(*), 0) + 1 FROM slb.LoadJobs WHERE CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE);
        DECLARE @JobCode VARCHAR(25);
        SET @JobCode = 'JOB-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' + RIGHT('000000' + CAST(@JobSeq AS VARCHAR(6)), 6);

        -- สร้าง LoadJob
        DECLARE @JobId UNIQUEIDENTIFIER;
        SET @JobId = NEWID();
        INSERT INTO slb.LoadJobs (JobId, JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId,
                                   ProductId, SiloId, TargetWeight, TolerancePct, Status, CreatedBy)
        VALUES (@JobId, @JobCode, @OrderId, @OrderItemId, @TruckId, @DriverId, @BayId,
                @ProductId, @SiloId, @TargetWeight, @TolerancePct, 'QR_ISSUED', @CreatedBy);

        -- สร้าง QR Token Placeholder (JWT จริงจะถูก Update โดย API)
        DECLARE @TokenId UNIQUEIDENTIFIER;
        SET @TokenId = NEWID();
        DECLARE @PlaceholderToken VARCHAR(500);
        SET @PlaceholderToken = 'PENDING-' + CAST(@TokenId AS VARCHAR(36));
        DECLARE @TokenHash VARCHAR(64);
        SET @TokenHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @PlaceholderToken), 2);

        INSERT INTO slb.QrTokens (TokenId, JobId, Token, TokenHash, IssuedAt, ExpiredAt)
        VALUES (@TokenId, @JobId, @PlaceholderToken, @TokenHash,
                SYSDATETIME(), DATEADD(HOUR, 8, SYSDATETIME()));

        -- อัปเดต Order + Queue Status
        UPDATE slb.Orders     SET Status = 'LOADING', UpdatedAt = SYSDATETIME() WHERE OrderId  = @OrderId;
        UPDATE slb.LoadQueues SET Status = 'LOADING'                             WHERE QueueId  = @QueueId;

        INSERT INTO slb.BayLogs (BayId, QueueId, EventType, EventData, CreatedBy)
        VALUES (@BayId, @QueueId, 'LOAD_STARTED',
                '{"jobId":"' + CAST(@JobId AS VARCHAR(36)) + '","jobCode":"' + @JobCode + '"}',
                @CreatedBy);

        COMMIT TRANSACTION;
        SELECT @JobId AS JobId, @JobCode AS JobCode, @TokenId AS TokenId, 'SUCCESS' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT NULL AS JobId, NULL AS JobCode, NULL AS TokenId, 'ERROR' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- --------------------------------------------------------
-- sp_ValidateQrToken — ตรวจสอบ QR + Mark Used
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_ValidateQrToken', 'P') IS NOT NULL DROP PROCEDURE slb.sp_ValidateQrToken;
GO
CREATE PROCEDURE slb.sp_ValidateQrToken
    @TokenHash  VARCHAR(64),
    @BayId      UNIQUEIDENTIFIER,
    @DeviceId   UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsValid  BIT = 0,
            @JobId    UNIQUEIDENTIFIER,
            @ErrorMsg NVARCHAR(300);

    SELECT
        @JobId    = qt.JobId,
        @IsValid  = CASE
            WHEN qt.IsUsed    = 1                         THEN 0
            WHEN qt.IsRevoked = 1                         THEN 0
            WHEN qt.ExpiredAt < SYSDATETIME()             THEN 0
            WHEN j.BayId      <> @BayId                   THEN 0
            WHEN j.Status NOT IN ('QR_ISSUED','QR_SCANNED') THEN 0
            ELSE 1 END,
        @ErrorMsg = CASE
            WHEN qt.IsUsed    = 1                         THEN N'QR นี้ถูกใช้ไปแล้ว'
            WHEN qt.IsRevoked = 1                         THEN N'QR นี้ถูกยกเลิก'
            WHEN qt.ExpiredAt < SYSDATETIME()             THEN N'QR หมดอายุแล้ว'
            WHEN j.BayId      <> @BayId                   THEN N'QR ไม่ตรงกับ Bay นี้'
            WHEN j.Status NOT IN ('QR_ISSUED','QR_SCANNED') THEN N'Job ไม่อยู่ในสถานะที่รับ QR ได้'
            ELSE NULL END
    FROM slb.QrTokens qt
    JOIN slb.LoadJobs j ON j.JobId = qt.JobId
    WHERE qt.TokenHash = @TokenHash;

    IF @JobId IS NULL
    BEGIN
        SELECT 0 AS IsValid, NULL AS JobId, N'ไม่พบ QR Token' AS ErrorMessage;
        RETURN;
    END

    IF @IsValid = 1
    BEGIN
        UPDATE slb.QrTokens
        SET IsUsed = 1, ScannedAt = SYSDATETIME(), ScannedByDeviceId = @DeviceId
        WHERE TokenHash = @TokenHash;

        UPDATE slb.LoadJobs
        SET Status = 'QR_SCANNED', UpdatedAt = SYSDATETIME()
        WHERE JobId = @JobId AND Status = 'QR_ISSUED';
    END

    SELECT @IsValid AS IsValid, @JobId AS JobId, @ErrorMsg AS ErrorMessage;
END
GO

-- --------------------------------------------------------
-- sp_UpdateLoadProgress — บันทึกน้ำหนักระหว่างโหลด
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_UpdateLoadProgress', 'P') IS NOT NULL DROP PROCEDURE slb.sp_UpdateLoadProgress;
GO
CREATE PROCEDURE slb.sp_UpdateLoadProgress
    @JobId         UNIQUEIDENTIFIER,
    @CurrentWeight DECIMAL(10,3)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobId = @JobId AND Status IN ('QR_SCANNED','LOADING','PAUSED'))
    BEGIN
        SELECT 'ERROR' AS Result, N'Job ไม่พบ หรือสถานะไม่ถูกต้อง' AS ErrorMessage;
        RETURN;
    END

    UPDATE slb.LoadJobs
    SET Status = 'LOADING', ActualWeight = @CurrentWeight, UpdatedAt = SYSDATETIME()
    WHERE JobId = @JobId AND Status IN ('QR_SCANNED','PAUSED');

    INSERT INTO slb.LoadJobLogs (JobId, EventType, CurrentWeight)
    VALUES (@JobId, 'WEIGHT_UPDATE', @CurrentWeight);

    SELECT 'SUCCESS' AS Result;
END
GO

-- --------------------------------------------------------
-- sp_CompleteLoading — โหลดเสร็จ + สร้าง Checklist
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_CompleteLoading', 'P') IS NOT NULL DROP PROCEDURE slb.sp_CompleteLoading;
GO
CREATE PROCEDURE slb.sp_CompleteLoading
    @JobId        UNIQUEIDENTIFIER,
    @ActualWeight DECIMAL(10,3),
    @CompletedBy  UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobId = @JobId AND Status = 'LOADING')
            RAISERROR('Job ไม่พบ หรือสถานะไม่ใช่ LOADING', 16, 1);

        DECLARE @TargetWeight DECIMAL(10,3), @BayId UNIQUEIDENTIFIER, @QueueId UNIQUEIDENTIFIER;
        SELECT @TargetWeight = TargetWeight, @BayId = BayId
        FROM slb.LoadJobs WHERE JobId = @JobId;
        SELECT @QueueId = CurrentQueueId FROM slb.Bays WHERE BayId = @BayId;

        DECLARE @WeightDiff DECIMAL(10,3) = @ActualWeight - @TargetWeight;

        UPDATE slb.LoadJobs
        SET Status = 'COMPLETED', ActualWeight = @ActualWeight,
            CompletedAt = SYSDATETIME(), UpdatedAt = SYSDATETIME()
        WHERE JobId = @JobId;

        UPDATE slb.Bays SET Status = 'CHECKING', LastUpdatedAt = SYSDATETIME() WHERE BayId = @BayId;

        INSERT INTO slb.LoadJobLogs (JobId, EventType, CurrentWeight)
        VALUES (@JobId, 'LOAD_COMPLETE', @ActualWeight);

        -- สร้าง Checklist
        DECLARE @ChecklistId UNIQUEIDENTIFIER = NEWID();
        INSERT INTO slb.LoadChecklists (ChecklistId, JobId, ActualWeight, WeightDiff,
                                         WeightVerified, QrVerified)
        VALUES (@ChecklistId, @JobId, @ActualWeight, @WeightDiff,
                CASE WHEN ABS(@WeightDiff) <= (@TargetWeight * 0.005) THEN 1 ELSE 0 END,
                1);

        -- สร้าง ChecklistItems มาตรฐาน
        INSERT INTO slb.ChecklistItems (ChecklistId, ItemCode, ItemName, IsRequired)
        VALUES
            (@ChecklistId, 'WEIGHT',  N'ตรวจสอบน้ำหนักตรงกับ Order ± 0.5%', 1),
            (@ChecklistId, 'QR',      N'QR Code ผ่านการตรวจสอบ',             1),
            (@ChecklistId, 'SEAL',    N'ปิด Seal ถัง/ช่องโหลดเรียบร้อย',     1),
            (@ChecklistId, 'DOC',     N'เอกสารใบขนครบถ้วน',                  1),
            (@ChecklistId, 'DRIVER',  N'ตรวจสอบตัวตนคนขับ',                  1);

        INSERT INTO slb.BayLogs (BayId, QueueId, EventType, EventData, CreatedBy)
        VALUES (@BayId, @QueueId, 'LOAD_COMPLETED',
                '{"jobId":"' + CAST(@JobId AS VARCHAR(36)) + '","actualWeight":' + CAST(@ActualWeight AS VARCHAR(20)) + '}',
                @CompletedBy);

        COMMIT TRANSACTION;
        SELECT @ChecklistId AS ChecklistId, 'SUCCESS' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT NULL AS ChecklistId, 'ERROR' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- --------------------------------------------------------
-- sp_ReleaseGate — อนุมัติปล่อยรถ + ลด Stock จริง
-- --------------------------------------------------------
IF OBJECT_ID('slb.sp_ReleaseGate', 'P') IS NOT NULL DROP PROCEDURE slb.sp_ReleaseGate;
GO
CREATE PROCEDURE slb.sp_ReleaseGate
    @ChecklistId UNIQUEIDENTIFIER,
    @ReleasedBy  UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- ตรวจสอบ Checklist ทุกรายการผ่าน
        IF EXISTS (SELECT 1 FROM slb.ChecklistItems
                   WHERE ChecklistId = @ChecklistId AND IsRequired = 1 AND IsChecked = 0)
        BEGIN
            RAISERROR(N'Checklist ยังมีรายการที่ยังไม่ผ่าน', 16, 1);
            RETURN;
        END

        DECLARE @JobId    UNIQUEIDENTIFIER,
                @Actual   DECIMAL(10,3),
                @Target   DECIMAL(10,3),
                @OrderId  UNIQUEIDENTIFIER,
                @BayId    UNIQUEIDENTIFIER,
                @QueueId  UNIQUEIDENTIFIER,
                @ProductId UNIQUEIDENTIFIER,
                @SiloId   UNIQUEIDENTIFIER;

        SELECT @JobId = cl.JobId, @Actual = cl.ActualWeight
        FROM slb.LoadChecklists cl WHERE cl.ChecklistId = @ChecklistId;

        SELECT @Target = TargetWeight, @OrderId = OrderId, @BayId = BayId,
               @ProductId = ProductId, @SiloId = SiloId
        FROM slb.LoadJobs WHERE JobId = @JobId;

        SELECT @QueueId = CurrentQueueId FROM slb.Bays WHERE BayId = @BayId;

        -- ลด Stock จริง + คืน Reserved
        UPDATE inv
        SET inv.CurrentStock  = inv.CurrentStock  - @Actual,
            inv.ReservedStock = inv.ReservedStock - @Target,
            inv.UpdatedAt     = SYSDATETIME()
        FROM slb.Inventory inv
        WHERE inv.SiloId = @SiloId;

        -- บันทึก InventoryLog (OUT)
        DECLARE @BeforeStock DECIMAL(12,3);
        SELECT @BeforeStock = CurrentStock + @Actual FROM slb.Inventory WHERE SiloId = @SiloId;

        INSERT INTO slb.InventoryLogs (ProductId, SiloId, ChangeType, Qty, BeforeStock, AfterStock,
                                        RefType, RefId, Remark, CreatedBy)
        VALUES (@ProductId, @SiloId, 'OUT', @Actual, @BeforeStock, @BeforeStock - @Actual,
                'LOADING', @JobId, N'โหลดสินค้า - Release Gate', @ReleasedBy);

        -- อัปเดต Checklist
        UPDATE slb.LoadChecklists
        SET ReleasedBy = @ReleasedBy, ReleasedAt = SYSDATETIME()
        WHERE ChecklistId = @ChecklistId;

        -- อัปเดต Order Status
        UPDATE slb.Orders     SET Status = 'COMPLETED', UpdatedAt = SYSDATETIME() WHERE OrderId  = @OrderId;
        UPDATE slb.LoadQueues SET Status = 'DONE', CompletedAt = SYSDATETIME()     WHERE QueueId  = @QueueId;
        UPDATE slb.Bays       SET Status = 'AVAILABLE', CurrentQueueId = NULL,
                                   LastUpdatedAt = SYSDATETIME()                   WHERE BayId    = @BayId;

        INSERT INTO slb.BayLogs (BayId, QueueId, EventType, EventData, CreatedBy)
        VALUES (@BayId, @QueueId, 'STATUS_CHANGE',
                '{"from":"CHECKING","to":"AVAILABLE","releasedBy":"' + CAST(@ReleasedBy AS VARCHAR(36)) + '"}',
                @ReleasedBy);

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'ERROR' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

PRINT '  Stored Procedures created.';
GO

-- ============================================================
-- SECTION 7: Test Data (สำหรับ Dev/Test เท่านั้น)
-- ============================================================

PRINT '-- Inserting Test Data...';
GO

-- ใช้ GUID คงที่เพื่อให้ Relationship ถูกต้อง
DECLARE
    -- Users
    @AdminId      UNIQUEIDENTIFIER = 'A0000001-0000-0000-0000-000000000001',
    @SuperId      UNIQUEIDENTIFIER = 'A0000001-0000-0000-0000-000000000002',
    @OpId         UNIQUEIDENTIFIER = 'A0000001-0000-0000-0000-000000000003',
    -- Customers
    @Cust01       UNIQUEIDENTIFIER = 'C0000001-0000-0000-0000-000000000001',
    @Cust02       UNIQUEIDENTIFIER = 'C0000001-0000-0000-0000-000000000002',
    -- Products
    @ProdRice     UNIQUEIDENTIFIER = 'E0000001-0000-0000-0000-000000000001',
    @ProdSugar    UNIQUEIDENTIFIER = 'E0000001-0000-0000-0000-000000000002',
    @ProdSalt     UNIQUEIDENTIFIER = 'E0000001-0000-0000-0000-000000000003',
    @ProdCorn     UNIQUEIDENTIFIER = 'E0000001-0000-0000-0000-000000000004',
    -- Silos
    @SiloR01      UNIQUEIDENTIFIER = 'FA000001-0000-0000-0000-000000000001',
    @SiloR02      UNIQUEIDENTIFIER = 'FA000001-0000-0000-0000-000000000002',
    @SiloSu01     UNIQUEIDENTIFIER = 'FA000001-0000-0000-0000-000000000003',
    @SiloSa01     UNIQUEIDENTIFIER = 'FA000001-0000-0000-0000-000000000004',
    @SiloCorn01   UNIQUEIDENTIFIER = 'FA000001-0000-0000-0000-000000000005',
    -- Trucks
    @Trk01        UNIQUEIDENTIFIER = '1B000001-0000-0000-0000-000000000001',
    @Trk02        UNIQUEIDENTIFIER = '1B000001-0000-0000-0000-000000000002',
    @Trk03        UNIQUEIDENTIFIER = '1B000001-0000-0000-0000-000000000003',
    @Trk04        UNIQUEIDENTIFIER = '1B000001-0000-0000-0000-000000000004',
    @Trk05        UNIQUEIDENTIFIER = '1B000001-0000-0000-0000-000000000005',
    -- Drivers
    @Drv01        UNIQUEIDENTIFIER = 'D0000001-0000-0000-0000-000000000001',
    @Drv02        UNIQUEIDENTIFIER = 'D0000001-0000-0000-0000-000000000002',
    @Drv03        UNIQUEIDENTIFIER = 'D0000001-0000-0000-0000-000000000003',
    @Drv04        UNIQUEIDENTIFIER = 'D0000001-0000-0000-0000-000000000004',
    @Drv05        UNIQUEIDENTIFIER = 'D0000001-0000-0000-0000-000000000005',
    -- Bays
    @Bay01        UNIQUEIDENTIFIER = 'B0000001-0000-0000-0000-000000000001',
    @Bay02        UNIQUEIDENTIFIER = 'B0000001-0000-0000-0000-000000000002',
    @Bay03        UNIQUEIDENTIFIER = 'B0000001-0000-0000-0000-000000000003',
    @Bay04        UNIQUEIDENTIFIER = 'B0000001-0000-0000-0000-000000000004',
    -- Hardware
    @HwQRS01      UNIQUEIDENTIFIER = '2C000001-0000-0000-0000-000000000001',
    @HwRDR01      UNIQUEIDENTIFIER = '2C000001-0000-0000-0000-000000000002',
    @HwPNL01      UNIQUEIDENTIFIER = '2C000001-0000-0000-0000-000000000003';

-- Users (Password = "Admin@1234" — BCrypt Hash จริง cost=11)
INSERT INTO slb.Users (UserId, Username, PasswordHash, FullName, Email, Role) VALUES
(@AdminId, 'admin',     '$2a$11$FewqZfSrg0jHn4bAfYx6fOGBHs/CaFWruhiiYgOFbTyV9pF3Vn53i', N'ผู้ดูแลระบบ',         'admin@factory.local',    'ADMIN'),
(@SuperId, 'supervisor','$2a$11$FewqZfSrg0jHn4bAfYx6fOGBHs/CaFWruhiiYgOFbTyV9pF3Vn53i', N'สุพรรณ วงษ์เจริญ',   'supervisor@factory.local','SUPERVISOR'),
(@OpId,    'operator1', '$2a$11$FewqZfSrg0jHn4bAfYx6fOGBHs/CaFWruhiiYgOFbTyV9pF3Vn53i', N'สมชาย ใจดี',          'operator1@factory.local', 'OPERATOR');

-- Customers
INSERT INTO slb.Customers (CustomerId, CustomerCode, CustomerName, ContactPerson, Phone) VALUES
(@Cust01, 'CUST-001', N'บริษัท ข้าวสยาม จำกัด',        N'คุณมานพ',  '02-111-2222'),
(@Cust02, 'CUST-002', N'ห้างหุ้นส่วน น้ำตาลทอง',       N'คุณสุดา',  '02-333-4444');

-- Products
INSERT INTO slb.Products (ProductId, ProductCode, ProductName, Unit, MinStock, CriticalStock, MaxStock) VALUES
(@ProdRice,  'RICE-01',   N'ข้าวเปลือก',   N'ตัน',   500,  200, 5000),
(@ProdSugar, 'SUGAR-01',  N'น้ำตาลทราย',   N'ตัน',   300,  100, 3000),
(@ProdSalt,  'SALT-01',   N'เกลือสมุทร',   N'ตัน',   200,   50, 2000),
(@ProdCorn,  'CORN-01',   N'ข้าวโพดเมล็ด', N'ตัน',   400,  150, 4000);

-- Silos
INSERT INTO slb.Silos (SiloId, SiloCode, SiloName, ProductId, Capacity) VALUES
(@SiloR01,   'S01', N'ไซโลข้าว A',        @ProdRice,  2000),
(@SiloR02,   'S02', N'ไซโลข้าว B',        @ProdRice,  2000),
(@SiloSu01,  'S03', N'ไซโลน้ำตาล',        @ProdSugar, 1500),
(@SiloSa01,  'S04', N'ถังเกลือ',           @ProdSalt,  1000),
(@SiloCorn01,'S05', N'ไซโลข้าวโพด',        @ProdCorn,  2000);

-- Inventory (Stock เริ่มต้น)
INSERT INTO slb.Inventory (ProductId, SiloId, CurrentStock, ReservedStock) VALUES
(@ProdRice,  @SiloR01,    1800.000, 0),
(@ProdRice,  @SiloR02,    1200.000, 0),
(@ProdSugar, @SiloSu01,    650.000, 0),
(@ProdSalt,  @SiloSa01,    120.000, 0),  -- ต่ำกว่า MinStock = 200 (จะ Alert)
(@ProdCorn,  @SiloCorn01,  980.000, 0);

-- Trucks
INSERT INTO slb.Trucks (TruckId, LicensePlate, TruckType, MaxCapacity, CompanyName) VALUES
(@Trk01, '80-1234 กก', 'TRAILER', 25.000, N'ขนส่งสยาม'),
(@Trk02, '80-5678 กก', 'TRAILER', 30.000, N'ขนส่งสยาม'),
(@Trk03, '71-1111 กข', 'TANKER',  20.000, N'โลจิสติกส์ไทย'),
(@Trk04, '71-2222 กข', 'TIPPER',  18.000, N'โลจิสติกส์ไทย'),
(@Trk05, '70-9999 กค', 'SILO',    22.000, N'ขนส่งทองคำ');

-- Drivers
INSERT INTO slb.Drivers (DriverId, FullName, LicenseNo, LicenseExpiry, Phone) VALUES
(@Drv01, N'สมชาย รักดี',     'DL-1234567', '2027-12-31', '081-111-1111'),
(@Drv02, N'วิชัย เก่งมาก',   'DL-2345678', '2028-06-30', '081-222-2222'),
(@Drv03, N'ประสิทธิ์ ขยัน',  'DL-3456789', '2026-09-30', '081-333-3333'),
(@Drv04, N'สุรชัย ซื่อตรง',  'DL-4567890', '2027-03-31', '081-444-4444'),
(@Drv05, N'มานพ ดีใจ',       'DL-5678901', '2028-12-31', '081-555-5555');

-- Bays
INSERT INTO slb.Bays (BayId, BayCode, BayName, BayType, MaxCapacity) VALUES
(@Bay01, 'BAY-01', N'Bay 1 — ข้าว',       'BULK_DRY',   30.000),
(@Bay02, 'BAY-02', N'Bay 2 — น้ำตาล',     'BULK_DRY',   25.000),
(@Bay03, 'BAY-03', N'Bay 3 — เกลือ',      'BULK_DRY',   20.000),
(@Bay04, 'BAY-04', N'Bay 4 — General',    'GENERAL',     30.000);

-- Hardware Devices
INSERT INTO slb.HardwareDevices (DeviceId, DeviceCode, DeviceName, DeviceType, Location, BayId, IpAddress, Port, Protocol) VALUES
(@HwQRS01, 'QRS-BAY01', N'QR Scanner Bay 1',    'QR_SCANNER',   N'Bay 1 Entry', @Bay01, '192.168.1.101', 9001, 'TCP'),
(@HwRDR01, 'RDR-BAY01', N'Radar Sensor Bay 1',  'RADAR',        N'Bay 1 Gate',  @Bay01, '192.168.1.102', 502,  'MODBUS_TCP'),
(@HwPNL01, 'PNL-BAY01', N'Loading Panel Bay 1', 'LOADING_PANEL',N'Bay 1 Panel', @Bay01, '192.168.1.103', 502,  'MODBUS_TCP');

PRINT '  Test Data inserted.';
PRINT '';
PRINT '=== SmartLoadBulkDB Setup Complete ===';
GO

-- ============================================================
-- SECTION 8: Quick Verify
-- ============================================================
SELECT 'Tables'  AS ObjectType, COUNT(*) AS Count FROM INFORMATION_SCHEMA.TABLES     WHERE TABLE_SCHEMA = 'slb' AND TABLE_TYPE = 'BASE TABLE'
UNION ALL
SELECT 'Views',                  COUNT(*)           FROM INFORMATION_SCHEMA.VIEWS      WHERE TABLE_SCHEMA = 'slb'
UNION ALL
SELECT 'Stored Procedures',      COUNT(*)           FROM INFORMATION_SCHEMA.ROUTINES   WHERE ROUTINE_SCHEMA = 'slb' AND ROUTINE_TYPE = 'PROCEDURE'
UNION ALL
SELECT 'Indexes',                COUNT(*)           FROM sys.indexes i
                                                    JOIN sys.tables  t ON t.object_id = i.object_id
                                                    JOIN sys.schemas s ON s.schema_id = t.schema_id
                                                    WHERE s.name = 'slb' AND i.is_primary_key = 0 AND i.type > 0;
GO

-- Test Inventory Dashboard
SELECT ProductCode, ProductName, TotalStock, AvailableStock, StockAlert FROM slb.vw_InventoryDashboard;
GO

-- ============================================================
-- ROLLBACK SCRIPT
-- คัดลอก Section นี้แยก แล้วรันถ้าต้องการลบทั้งหมด
-- ============================================================
/*
USE SmartLoadBulkDB;
GO

-- Drop Stored Procedures
DROP PROCEDURE IF EXISTS slb.sp_ReleaseGate;
DROP PROCEDURE IF EXISTS slb.sp_CompleteLoading;
DROP PROCEDURE IF EXISTS slb.sp_UpdateLoadProgress;
DROP PROCEDURE IF EXISTS slb.sp_ValidateQrToken;
DROP PROCEDURE IF EXISTS slb.sp_CreateLoadJob;
DROP PROCEDURE IF EXISTS slb.sp_CallTruckToBay;
DROP PROCEDURE IF EXISTS slb.sp_EnqueueTruck;
DROP PROCEDURE IF EXISTS slb.sp_GetBayStatus;
DROP PROCEDURE IF EXISTS slb.sp_GetQueueBoard;
DROP PROCEDURE IF EXISTS slb.sp_GetInventoryDashboard;

-- Drop Views
DROP VIEW IF EXISTS slb.vw_DailySummary;
DROP VIEW IF EXISTS slb.vw_ActiveLoadJobs;
DROP VIEW IF EXISTS slb.vw_BayMonitor;
DROP VIEW IF EXISTS slb.vw_QueueBoard;
DROP VIEW IF EXISTS slb.vw_InventoryDashboard;

-- Drop Tables (reverse dependency order)
DROP TABLE IF EXISTS slb.AuditLogs;
DROP TABLE IF EXISTS slb.NotificationLogs;
DROP TABLE IF EXISTS slb.HardwareEvents;
DROP TABLE IF EXISTS slb.ChecklistItems;
DROP TABLE IF EXISTS slb.LoadChecklists;
DROP TABLE IF EXISTS slb.QrTokens;
DROP TABLE IF EXISTS slb.LoadJobLogs;
DROP TABLE IF EXISTS slb.LoadJobs;
DROP TABLE IF EXISTS slb.HardwareDevices;
DROP TABLE IF EXISTS slb.BayLogs;
DROP TABLE IF EXISTS slb.Bays;
DROP TABLE IF EXISTS slb.LoadQueues;
DROP TABLE IF EXISTS slb.OrderItems;
DROP TABLE IF EXISTS slb.Orders;
DROP TABLE IF EXISTS slb.TruckDriverMap;
DROP TABLE IF EXISTS slb.InventoryLogs;
DROP TABLE IF EXISTS slb.Inventory;
DROP TABLE IF EXISTS slb.Silos;
DROP TABLE IF EXISTS slb.Drivers;
DROP TABLE IF EXISTS slb.Trucks;
DROP TABLE IF EXISTS slb.Products;
DROP TABLE IF EXISTS slb.Customers;
DROP TABLE IF EXISTS slb.Users;

-- Drop Schema
DROP SCHEMA IF EXISTS slb;

-- ถ้าต้องการลบ Database ทั้งหมด:
-- USE master; DROP DATABASE IF EXISTS SmartLoadBulkDB;
*/
