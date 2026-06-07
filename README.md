# Chicago Crime — Hurtownia Danych & Analiza Wielowymiarowa

> Projekt z przedmiotu **Wielowymiarowa Analiza Danych** realizujący pełen cykl Business Intelligence: od plików źródłowych, przez ETL i hurtownię danych, aż po kostkę OLAP, KPI, Data Mining i wizualizacje w Power BI.

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=flat&logo=microsoft-sql-server&logoColor=white)
![SSIS](https://img.shields.io/badge/SSIS-ETL-orange)
![SSAS](https://img.shields.io/badge/SSAS-OLAP-blue)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![Visual Studio](https://img.shields.io/badge/Visual%20Studio-2019-5C2D91?style=flat&logo=visual-studio)

---

## Spis treści

- [Cel projektu](#cel-projektu)
- [Opis danych](#opis-danych)
- [Architektura rozwiązania](#architektura-rozwiązania)
- [Stack technologiczny](#stack-technologiczny)
- [Struktura hurtowni](#struktura-hurtowni)
- [Procesy ETL](#procesy-etl)
- [Kostka OLAP](#kostka-olap)
- [KPI](#kpi)
- [Data Mining](#data-mining)
- [Wizualizacje Power BI](#wizualizacje-power-bi)
- [Uruchomienie](#uruchomienie)
- [Struktura repozytorium](#struktura-repozytorium)

---

## Cel projektu

Celem projektu jest przeprowadzenie pełnej analizy wielowymiarowej na zestawie **1 000 000 wierszy** danych dotyczących przestępczości w Chicago. Projekt obejmuje:

- przygotowanie i wczytanie danych do hurtowni (ETL)
- modelowanie wielowymiarowe (schemat gwiazdy)
- budowę kostki OLAP z miarami obliczanymi (MDX) i wskaźnikami KPI
- analizy Data Mining (klasyfikacja, klastrowanie, predykcja)
- raportowanie i wizualizację wyników w Power BI

## Opis danych

Zestaw danych pochodzi z otwartego portalu **City of Chicago Data Portal**:

🔗 **[Crimes — 2001 to Present](https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2/about_data)**

Dane są aktualizowane codziennie i obejmują wszystkie zgłoszone przestępstwa w Chicago od 2001 roku (z wyjątkiem zabójstw, które są raportowane na poziomie ofiary). Dla potrzeb projektu wczytano próbkę 1 000 000 wierszy. Każdy wiersz to pojedynczy incydent z informacjami o:

- **ID, CaseNumber, Date** — identyfikacja i czas zdarzenia
- **PrimaryType, Description, IUCR, FBICode** — klasyfikacja przestępstwa
- **District, Ward, CommunityArea** — lokalizacja administracyjna
- **Latitude, Longitude** — współrzędne geograficzne
- **LocationDescription** — typ miejsca (street, residence, apartment...)
- **Arrest, Domestic** — flagi BIT (czy zakończyło się aresztem, czy to przemoc domowa)

## Architektura rozwiązania

```
[CSV Chicago Crime] 
       │
       ▼
[SSIS / Integration Services]  ◄── 5 przepływów ETL
       │
       ▼
[ChicagoCrime_DW]              ◄── Hurtownia (schemat gwiazdy)
       │                          FactCrime + 4 wymiary
       ▼
[SSAS — Kostka OLAP]           ◄── Wielowymiarowy projekt Analysis Services
       │                          miary, calculations (MDX), KPI, hierarchie
       ├──► [Data Mining Models]   Drzewa, sieci neuronowe, klastrowanie
       │
       ▼
[Power BI Desktop]             ◄── Raporty z slicerami i KPI
```

## Stack technologiczny

| Warstwa | Narzędzie |
|---|---|
| Bazy / hurtownia | Microsoft SQL Server |
| ETL | SQL Server Integration Services (SSIS) |
| OLAP & Data Mining | SQL Server Analysis Services (SSAS) — Multidimensional |
| Język zapytań kostki | MDX |
| Wizualizacja | Power BI Desktop |
| IDE | Visual Studio z dodatkami SSDT |

## Struktura hurtowni

Schemat gwiazdy zbudowany wokół tabeli faktów `FactCrime` z 1 mln wierszy i 4 wymiarów:

```
                    ┌──────────────┐
                    │   DimDate    │
                    │  DateKey PK  │
                    │  FullDate    │
                    │  Year, Month │
                    │  Quarter, Day│
                    └──────┬───────┘
                           │
   ┌───────────────┐       │       ┌──────────────────┐
   │ DimCrimeType  │       │       │ DimLocationType  │
   │ CrimeTypeKey  │◄──────┼──────►│ LocationTypeKey  │
   │ PrimaryType   │   ┌───┴───┐   │ LocationDesc.    │
   │ IUCR, FBICode │◄──┤Fact   ├──►└──────────────────┘
   │ Description   │   │Crime  │
   └───────────────┘   │       │   ┌──────────────────┐
                       │ 1M    │   │   DimLocation    │
                       │ rows  ├──►│ LocationKey      │
                       └───────┘   │ District, Ward   │
                                   │ CommunityArea    │
                                   │ Lat, Long        │
                                   └──────────────────┘
```

**Tabela faktów `FactCrime`:**
- `CrimeKey` (PK)
- `DateKey`, `CrimeTypeKey`, `LocationKey`, `LocationTypeKey` (FK)
- `CrimeID`, `CaseNumber`
- `Arrest`, `Domestic` (BIT)

## Procesy ETL

W projekcie SSIS zaimplementowano **5 przepływów ETL**, które:

1. Pobierają dane z plików źródłowych (Flat File Source)
2. Sortują i scalają strumienie (Sort, Merge)
3. Sprawdzają duplikaty (Lookup) — błędne rekordy do tabel błędów
4. Wykonują transformacje (Derived Column, Data Conversion)
5. Ładują oczyszczone dane do tabel hurtowni (OLE DB Destination)

## Kostka OLAP

Wielowymiarowy projekt SSAS `CHICAGO_CRIME_OLAP` zawiera:

### Miary podstawowe
- `Fact Crime Count` — łączna liczba przestępstw
- `Arrest` — liczba aresztów (SUM po `CAST(Arrest AS INT)`)
- `Domestic` — liczba przypadków przemocy domowej (SUM po `CAST(Domestic AS INT)`)

### Miary obliczane (Calculations / MDX)
- `[Arrest Rate]` — `Arrest / Fact Crime Count * 100`
- `[Domestic Rate]` — `Domestic / Fact Crime Count * 100`
- `[Theft Rate]` — procentowy udział kradzieży w ogólnej liczbie przestępstw
- `[Daily Crime Average]` — średnia dzienna liczba zdarzeń

### Hierarchie
- **DimDate**: Year → Quarter → Month → Day
- **DimLocation**: District → Ward → CommunityArea
- **DimCrimeType**: FBICode → PrimaryType → Description

## KPI

W kostce zdefiniowano **5 KPI** wykorzystujących wyrażenia `KpiValue()`, `KpiGoal()` i `CASE WHEN`:

| KPI | Cel | Logika statusu |
|---|---|---|
| Arrest Effectiveness | ≥ 15% | więcej = lepiej |
| Domestic Violence Watch | ≤ 20% | mniej = lepiej |
| Crime Volume Annual | ≤ 250 000 | mniej = lepiej |
| Theft Dominance | ≤ 25% | mniej = lepiej |
| Daily Crime Load | ≤ 700 | mniej = lepiej |

Każdy KPI ma trzystopniowy status (Traffic Light): 🔴 / 🟡 / 🟢.

## Data Mining

Cztery modele analityczne zbudowane na danych hurtowni:

1. **Microsoft Decision Trees** — predykcja `Arrest` na podstawie typu przestępstwa, lokalizacji i czasu
2. **Microsoft Neural Network** — klasyfikacja `Domestic` 
3. **Microsoft Clustering** — segmentacja dzielnic według charakterystyki przestępczości
4. **Microsoft Naive Bayes** — dodatkowa klasyfikacja porównawcza

## Wizualizacje Power BI

Raporty łączą się z kostką OLAP przez **Live Connection do SSAS**.

- Raport 1 — KPI: Arrest Effectiveness, Domestic Violence Watch + breakdown po dzielnicach
- Raport 2 — pozostałe KPI + slicery (rok, miesiąc, typ przestępstwa)
- Raport 3 — mapa przestępczości (z latitude/longitude)
- Raport 4 — wyniki Data Mining (predykcje vs rzeczywistość)

## Uruchomienie

### Wymagania
- Microsoft SQL Server 2019+ z włączoną instancją Analysis Services (Multidimensional)
- Visual Studio 2019/2022 z dodatkami **SSDT** (SQL Server Data Tools)
- Power BI Desktop

### Kroki
1. Sklonuj to repozytorium
2. Odtwórz hurtownię z pliku `database/ChicagoCrime_DW.bak`
3. Otwórz solucję `WAD_Projekt_<numer>.sln` w Visual Studio
4. W projekcie SSIS — uruchom przepływy ETL (Package.dtsx)
5. W projekcie SSAS — Deploy + Process Full kostki
6. Otwórz raporty Power BI w pliku `.pbix` i odśwież połączenie

## Struktura repozytorium

```
chicago-crime-wad/
├── database/
│   └── ChicagoCrime_DW.bak              # Backup hurtowni
├── etl/
│   ├── Package.dtsx                     # 5 przepływów ETL
│   └── data/                            # Pliki źródłowe CSV
├── olap/
│   ├── CHICAGO_CRIME_OLAP.sln           # Projekt SSAS
│   ├── Cubes/
│   ├── Dimensions/
│   └── DataSourceViews/
├── powerbi/
│   └── ChicagoCrime_Reports.pbix
├── docs/
│   ├── sprawozdanie.pdf                 # Pełna dokumentacja
│   └── screenshots/
└── README.md
```

---

## Autor

Maciej Gilecki, Wioletta Grabias

Projekt zrealizowany w ramach przedmiotu **Wielowymiarowa Analiza Danych**, Politechnika Rzeszowska, Wydział Matematyki i Fizyki Stosowanej.

## Licencja

Projekt edukacyjny. Dane Chicago Crime są publicznie dostępne na portalu [data.cityofchicago.org](https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2/about_data) i udostępniane przez Chicago Police Department.
