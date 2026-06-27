# MAICA Resource Search — Salesforce Health Cloud Experience Site

> A Lightning Web Component (LWC) search tool built for **after-hours support workers** and coordinators of an aged care / NDIS organisation, deployed on a **Salesforce Health Cloud Experience Site**. Workers can quickly search for care resources (Support Workers, Therapists, Nurses) by name, view their type and supplier contact details, and navigate directly to the full resource record — without needing full Salesforce CRM access.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Business Context](#business-context)
- [Solution Design](#solution-design)
- [Component Features](#component-features)
- [Data Model](#data-model)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Test Coverage](#test-coverage)
- [Deployment Guide](#deployment-guide)
- [Adding to the Experience Site](#adding-to-the-experience-site)

---

## Project Overview

This project delivers a resource search tool deployed inside an Experience Site (Customer Account Portal) on **Salesforce Health Cloud**, using the **MAICA managed package** (`maica_cc`). It allows coordinators and after-hours support workers to search for care resources by name, view their type and supplier email, and navigate directly to the resource record — all within a simplified portal interface that does not require a full Salesforce licence.

| Component | Purpose |
|-----------|---------|
| `maicaResourceSearch` (LWC) | Search UI — name input, results datatable with row-action navigation, auto-navigation |
| `MaicaResourceSearchController` (Apex) | Server-side search logic — dynamic SOQL on `maica_cc__Resource__c` |
| `MaicaResourceSearchControllerTest` (Apex) | Unit tests — 12 test methods covering all search scenarios |

---

## Business Context

Aged care and NDIS (National Disability Insurance Scheme) organisations manage a large workforce of care resources — Support Workers, Therapists, Nurses — rostered across client appointments. The **MAICA** Salesforce managed package (`maica_cc`) is a purpose-built workforce management platform used by these organisations to schedule and manage their care resources.

After-hours coordinators and support workers frequently need to:
- Quickly locate a specific Support Worker or Therapist by name
- Confirm their resource type and supplier contact email
- Navigate to the full resource record to check availability, rostering, or contact details

This tool provides that lookup capability directly within the Experience Site portal, removing the need for a full Salesforce licence for after-hours staff.

---

## Solution Design

```
┌──────────────────────────────────────────────────────────────────────┐
│          Aged Care / NDIS Health Cloud Experience Site               │
│                   (Customer Account Portal)                          │
│                                                                      │
│   ┌────────────────────────────────────────────────────────────┐     │
│   │                 maicaResourceSearch (LWC)                  │     │
│   │                                                            │     │
│   │  ┌─────────────────┐                                       │     │
│   │  │  SCREEN 1       │  Coordinator types resource name      │     │
│   │  │  Search Form    │  e.g. "Margaret" or "Support Worker"  │     │
│   │  │  [Name Input  ] │  ──────────────────────────────────── │     │
│   │  │  [Search Btn  ] │                                       │     │
│   │  └────────┬────────┘                                       │     │
│   │           │                                                │     │
│   │    ┌──────┴──────┐                                         │     │
│   │    │  Apex call  │  searchResources(resourceName)          │     │
│   │    └──────┬──────┘                                         │     │
│   │           │                                                │     │
│   │   ┌───────┴────────────┐   ┌───────────────────────────┐  │     │
│   │   │  SCREEN 2          │   │  SCREEN 3                 │  │     │
│   │   │  Results Datatable │   │  No Results               │  │     │
│   │   │  • Resource Name ──┼───┼──► Row Action (button)    │  │     │
│   │   │    [clickable btn] │   │     Navigate to Record    │  │     │
│   │   │  • Resource Type   │   │  • Prompt to retry        │  │     │
│   │   │  • Supplier Email  │   │  • Back / New Search      │  │     │
│   │   │  • Back / New Srch │   └───────────────────────────┘  │     │
│   │   └────────────────────┘                                   │     │
│   │                                                            │     │
│   │   * Single result → auto-navigate directly to record      │     │
│   └────────────────────────────────────────────────────────────┘     │
└────────────────────────────┬─────────────────────────────────────────┘
                             │  Apex (@AuraEnabled)
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│              MaicaResourceSearchController (Apex)                  │
│                                                                    │
│   searchResources(resourceName)                                    │
│   ├─ Builds dynamic SOQL with LIKE '%name%'                       │
│   ├─ String.escapeSingleQuotes() → prevents SOQL injection        │
│   ├─ ORDER BY Name ASC LIMIT 100                                  │
│   └─ Returns List<maica_cc__Resource__c>                          │
└────────────────────────────┬───────────────────────────────────────┘
                             │  SOQL
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│              Salesforce Health Cloud + MAICA Package Data          │
│                                                                    │
│   maica_cc__Resource__c  (MAICA managed object)                    │
│   ├─ Id, Name                                                     │
│   ├─ maica_cc__Type__c   (Support Worker / Therapist / Nurse)     │
│   └─ Supplier_Email__c   (custom field — supplier contact email)  │
└────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `@AuraEnabled(cacheable=false)` | Search results must always be live; stale cache could show outdated resource availability details |
| `LIKE '%name%'` partial match | Coordinators may only know part of a resource name during an after-hours call |
| `String.escapeSingleQuotes()` | Prevents SOQL injection from user-supplied search input — critical since the query is dynamically constructed |
| Button-type column for row action (`onrowaction`) | Used instead of a URL-type column because `maica_cc__Resource__c` is a managed package object; row action navigation via `NavigationMixin` with `standard__recordPage` is the most reliable approach inside an Experience Site |
| Auto-navigate on single result | When exactly one match is found, the component navigates directly to the record without showing the datatable — saves coordinators time on unambiguous searches |
| `with sharing` on Apex | Respects Experience Site sharing rules — coordinators only see resources their profile allows |
| Dynamic SOQL with conditions list | Designed to be extensible — filter by Type or Supplier Email can be re-enabled by uncommenting conditions (scaffolding is preserved in commented-out code) |

---

## Component Features

### `maicaResourceSearch` LWC

**Screen 1 — Search Form**
- Single text input: Resource Name (partial match supported)
- Search button with loading spinner while the Apex call is in flight
- Blank or null input returns all resources (up to 100), ordered A–Z

**Screen 2 — Results Datatable**
- `lightning-datatable` showing up to 100 matching resources
- Resource Name column is a clickable **button** — clicking opens the full Resource record detail page in the Experience Site via `NavigationMixin`
- Resource Type shows the category of care worker (Support Worker, Therapist, Nurse, etc.)
- Supplier Email displays the contact email for the resource's supplier
- Back and New Search buttons to return to the search form

**Smart single-result navigation**
- If only one resource matches, the component automatically navigates to that record without displaying the datatable — the fastest possible path for after-hours coordinators

**Screen 3 — No Results**
- Clear messaging when no resources match the search term
- Back and New Search buttons to retry

**Error handling**
- Toast notification for Apex errors with a human-readable message
- `getErrorMessage()` helper handles all Salesforce error response formats (`error.body.message`, `error.message`, array body)

---

## Data Model

| Field | API Name | Type | Purpose |
|-------|----------|------|---------|
| Resource Name | `Name` | Text | Primary search field; displayed as a clickable button in results |
| Resource Type | `maica_cc__Type__c` | Picklist | Category of care resource (Support Worker, Therapist, Nurse) — from MAICA package |
| Supplier Email | `Supplier_Email__c` | Email | Contact email for the resource's supplying organisation |

All records are from the **`maica_cc__Resource__c`** object — a MAICA managed package object that represents the care workforce available for rostering against client appointments.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Lightning Web Components (LWC), SLDS |
| Data display | `lightning-datatable` with button-type column and `onrowaction` handler |
| Navigation | `lightning/navigation` — `NavigationMixin` (`standard__recordPage`) |
| Backend | Apex (`with sharing`, `@AuraEnabled(cacheable=false)`) |
| Managed Package | MAICA (`maica_cc`) — aged care / NDIS workforce management |
| Platform | Salesforce Health Cloud, Experience Cloud |
| Site Template | Customer Account Portal |
| API Version | v62.0 |
| Dev Tooling | Salesforce CLI (`sf`), VS Code + Salesforce Extension Pack |
| Version Control | Git / GitHub |

---

## Project Structure

```
force-app/main/default/
│
├── classes/
│   ├── MaicaResourceSearchController.cls              # Apex search logic
│   ├── MaicaResourceSearchController.cls-meta.xml
│   ├── MaicaResourceSearchControllerTest.cls          # Unit tests (12 test methods)
│   └── MaicaResourceSearchControllerTest.cls-meta.xml
│
└── lwc/
    └── maicaResourceSearch/
        ├── maicaResourceSearch.html                   # 3-screen template (form / results / no-results)
        ├── maicaResourceSearch.js                     # NavigationMixin + row-action + search logic
        ├── maicaResourceSearch.css                    # SLDS layout padding overrides
        └── maicaResourceSearch.js-meta.xml            # Exposed to lightningCommunity__Page + standard pages
```

---

## Test Coverage

`MaicaResourceSearchControllerTest` covers 12 test scenarios across four categories:

### Happy Path Tests

| Test Method | Scenario Covered |
|-------------|-----------------|
| `testSearchResources_NoFilters_ReturnsAll` | Null input returns all resources |
| `testSearchResources_BlankName_ReturnsAll` | Blank string returns all resources |
| `testSearchResources_ExactName_ReturnsMatch` | Exact name returns exactly 1 record |
| `testSearchResources_PartialName_ReturnsMatches` | Partial match ("Support Worker") returns multiple records |
| `testSearchResources_PartialNamePrefix_ReturnsMatch` | Prefix match returns the correct single record |
| `testSearchResources_CaseInsensitive_ReturnsMatch` | Lowercase search matches mixed-case names |
| `testSearchResources_ReturnsCorrectFields` | All queried fields (Id, Name, Type, Email) are populated |
| `testSearchResources_ResultsOrderedByName` | Results are sorted A–Z by name |

### No Results Test

| Test Method | Scenario Covered |
|-------------|-----------------|
| `testSearchResources_NoMatch_ReturnsEmpty` | Unmatched search returns empty list (not null) |

### Injection / Special Character Tests

| Test Method | Scenario Covered |
|-------------|-----------------|
| `testSearchResources_SingleQuoteInName_DoesNotThrow` | Single quote input handled safely by `escapeSingleQuotes()` |
| `testSearchResources_SpecialCharacters_HandledGracefully` | `%` and other special characters do not cause exceptions |

### Limit Test

| Test Method | Scenario Covered |
|-------------|-----------------|
| `testSearchResources_RespectsLimit` | Inserts 100+ records and verifies result set is capped at LIMIT 100 |

Test data uses four `maica_cc__Resource__c` records representing different care resource types (Support Worker, Therapist, Nurse), with `DMLOptions.DuplicateRuleHeader.allowSave = true` to bypass duplicate rules in test context. A unique timestamp suffix is appended to each record name to prevent conflicts across test runs.

---

## Deployment Guide

### Prerequisites
- Salesforce CLI installed (`sf --version`)
- Authenticated org with Health Cloud and Experience Cloud enabled
- **MAICA managed package** (`maica_cc`) installed in the org
- Custom field `Supplier_Email__c` deployed on `maica_cc__Resource__c`

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/paramita2026/ResourceSearchProject.git
cd ResourceSearchProject
```

**2. Authenticate your org**
```bash
sf org login web --alias myOrg
```

**3. Deploy the Apex class and test class**
```bash
sf project deploy start \
  --source-dir force-app/main/default/classes/MaicaResourceSearchController.cls \
  --source-dir force-app/main/default/classes/MaicaResourceSearchControllerTest.cls \
  --target-org myOrg
```

**4. Deploy the LWC component**
```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/maicaResourceSearch \
  --target-org myOrg
```

**5. Run tests to verify deployment**
```bash
sf apex run test \
  --class-names MaicaResourceSearchControllerTest \
  --target-org myOrg \
  --result-format human
```

---

## Adding to the Experience Site

1. Go to **Setup → Digital Experiences → All Sites**
2. Click **Builder** next to your Experience Site
3. Navigate to the page where coordinators land after logging in (e.g. the Home page)
4. In the left component panel, search for **Maica Resource Search**
5. Drag the component onto the page
6. Click **Publish**

Coordinators and after-hours support workers logging in to the Experience Site will see the resource search form and can immediately search by name.

---

## Author

**Paramita Bhattacharya**  
GitHub: [@paramita2026](https://github.com/paramita2026)
