# Note Book v1.14.0 — Smarter SMS Descriptions, Payments & Deposit Categories

## What's New

### Smarter, Human-Readable SMS Descriptions
Descriptions extracted from bank SMS are now structured and meaningful rather than raw scraped text:

| SMS | Description | Category |
|-----|-------------|----------|
| COMBANK CRM Deposit for Rs. 10,000 | `Deposit of 10,000 in Commercial Bank` | **Deposit** |
| Purchase at PickMe Food for LKR 1,559 | `Purchase at PickMe Food 1,559` | **Food & Dining** |
| KOKO instalment of 7895.98 for Simplytek order | `KOKO Instalment Simplytek` | **Payments** |
| ATM withdrawal of LKR 15,000 | `ATM Withdrawal 15,000` | **Other** |

Amounts are formatted with thousands separators (`10,000`) and trailing `.00` is dropped.

### Cancelled + Reversed Orders Now Auto-Delete
Previously, SMS messages that were **both cancelled and reversed** (e.g. a PickMe Food order that was cancelled and refunded) were silently ignored — leaving the original charge in your transaction list. They now correctly delete the original expense.

### New Built-in Categories: Payments & Deposit
- **Payments** — covers instalments, EMI, KOKO, loan repayments, credit card payments
- **Deposit** — covers bank deposits, salary credits, cash deposits, income

Both categories are **added automatically** to existing installs via a database migration. No reinstall required.

### Custom Categories Now Included in Backup
Backups are now **version 4**. Custom categories (names, keywords, colours) are fully exported and restored. Restoring a v4 backup reloads the category cache instantly so the changes take effect without restarting the app.

Previous backups (v1, v2, v3) continue to import without any issues.

### Expanded Provider Support
Added **KOKO**, **Nations Trust Bank (NTB)**, **LOLC**, **FriMi**, and **PayApp** to the recognised SMS sender whitelist.

## Upgrade Guide

**From any previous version**: Simply install the new APK. The database migrates automatically — no data is lost and no reinstall is needed.

---

*Fully local. No data leaves your device.*
