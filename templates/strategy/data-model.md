# [Project Name] — Data Model

**Version:** v0.1.0
**Last Updated:** YYYY-MM-DD
**Audience:** Developers

---

## Overview

[High-level description of the data model: how many core entities, what paradigm (relational, document, graph), key design decisions.]

---

## Entity Relationship Diagram

[Text-based ERD or description of relationships between core entities.]

```
[Entity A] 1──* [Entity B] *──1 [Entity C]
```

---

## Core Entities

### [Entity 1]

**Purpose:** [what this entity represents]

| Field | Type | Constraints | Notes |
|-------|------|------------|-------|
| | | | |

**Relationships:**
- Has many [Entity 2] via `entity2.entity1_id`

**Indexes:**
- 

---

### [Entity 2]

**Purpose:** [what this entity represents]

| Field | Type | Constraints | Notes |
|-------|------|------------|-------|
| | | | |

---

## Calculations & Derived Data

[If the product involves calculations, define the source of truth and computation rules here. Which layer is authoritative — DB, utils, or API?]

---

## Migration Patterns

[Conventions for schema changes: naming, idempotency rules, rollback strategy.]

---

## Seed Data

[What data needs to exist for the system to function: default roles, lookup tables, configuration records.]
