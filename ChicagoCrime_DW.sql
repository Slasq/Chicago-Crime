-- ============================================
-- CHICAGO CRIME DATA WAREHOUSE
-- Skrypt tworzący hurtownię danych
-- Schemat gwiazdy (Star Schema)
-- ============================================

-- 1. TWORZENIE BAZY DANYCH
-- ============================================
CREATE DATABASE ChicagoCrime_DW;
GO

USE ChicagoCrime_DW;
GO

-- ============================================
-- 2. TABELE WYMIARÓW (DIMENSIONS)
-- ============================================

-- DimDate
CREATE TABLE DimDate (
    DateKey        INT PRIMARY KEY,
    FullDate       DATE NOT NULL,
    Year           INT NOT NULL,
    Quarter        INT NOT NULL,
    QuarterName    VARCHAR(10)  NOT NULL,
    Month          INT NOT NULL,
    MonthName      VARCHAR(20)  NOT NULL,
    Day            INT NOT NULL,
    DayOfWeek      INT NOT NULL,
    DayName        VARCHAR(20)  NOT NULL,
    IsWeekend      BIT NOT NULL,
    Hour           INT NOT NULL
);
GO

-- DimCrimeType
CREATE TABLE DimCrimeType (
    CrimeTypeKey   INT IDENTITY(1,1) PRIMARY KEY,
    IUCR           VARCHAR(10)  NOT NULL,
    PrimaryType    VARCHAR(100) NOT NULL,
    Description    VARCHAR(255) NOT NULL,
    FBICode        VARCHAR(10)  NOT NULL
);
GO

-- DimLocationType
CREATE TABLE DimLocationType (
    LocationTypeKey     INT IDENTITY(1,1) PRIMARY KEY,
    LocationDescription VARCHAR(255) NOT NULL
);
GO

-- DimLocation
CREATE TABLE DimLocation (
    LocationKey    INT IDENTITY(1,1) PRIMARY KEY,
    Block          VARCHAR(100) NOT NULL,
    Beat           INT NOT NULL,
    District       INT NOT NULL,
    Ward           INT NOT NULL,
    CommunityArea  INT NOT NULL,
    Latitude       FLOAT,
    Longitude      FLOAT
);
GO

-- ============================================
-- 3. TABELA FAKTÓW (FACT TABLE)
-- ============================================

CREATE TABLE FactCrime (
    CrimeKey          INT IDENTITY(1,1) PRIMARY KEY,
    DateKey           INT NOT NULL,
    CrimeTypeKey      INT NOT NULL,
    LocationKey       INT NOT NULL,
    LocationTypeKey   INT NOT NULL,
    CrimeID           INT NOT NULL,
    CaseNumber        VARCHAR(20) NOT NULL,
    Arrest            BIT NOT NULL,
    Domestic          BIT NOT NULL,

    CONSTRAINT FK_Fact_Date
        FOREIGN KEY (DateKey)         REFERENCES DimDate(DateKey),
    CONSTRAINT FK_Fact_CrimeType
        FOREIGN KEY (CrimeTypeKey)    REFERENCES DimCrimeType(CrimeTypeKey),
    CONSTRAINT FK_Fact_Location
        FOREIGN KEY (LocationKey)     REFERENCES DimLocation(LocationKey),
    CONSTRAINT FK_Fact_LocationType
        FOREIGN KEY (LocationTypeKey) REFERENCES DimLocationType(LocationTypeKey)
);
GO

-- ============================================
-- 4. INDEKSY NA TABELI FAKTÓW
-- ============================================

CREATE INDEX IX_Fact_DateKey
    ON FactCrime(DateKey);

CREATE INDEX IX_Fact_CrimeTypeKey
    ON FactCrime(CrimeTypeKey);

CREATE INDEX IX_Fact_LocationKey
    ON FactCrime(LocationKey);

CREATE INDEX IX_Fact_Arrest
    ON FactCrime(Arrest);
GO

-- ============================================
-- KONIEC SKRYPTU
-- ============================================
