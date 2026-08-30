## 2026-08-30T07:41:52Z

Mission: Conduct a comprehensive, read-only audit of the Finances & Split Bills domain (lib/features/finances/, lib/services/sms/, receipt scanner, split bills, and related tests) for Everything App.

Authoritative references to inspect:
- /Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md
- /Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md
- /Users/saadhjawwadh/Documents/Code/Note taking/.agent/map.md
- /Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/App-Feature-Expert/SKILL.md

Scope to Audit:
1. Two-Bank Account Model (AccountType.daily vs AccountType.savings, dual cash flow hero metrics, 0ms account filtering, bank deposit auto-routing).
2. SMS regex parsing, test sender sandbox whitelisting ('BANK_SMS', 'CARD', 'ALERTS', 'BANK'), SMS permission manifest parity (Permission.sms only), timestamp normalization (resolveMessageDate for 10-digit and 13-digit epochs).
3. Tombstone ingestion safety (smsExists checking both active transactions and deleted_transaction_sms_ids).
4. SMS 24-hour default lookback on quick/app-launch catch-up sync, non-blocking chunked processing (yield every 25 msgs), cancellation flag (_cancelRequested), and real-time frosted progress banner with 1-tap Cancel.
5. Recurring rule propagation (RecurringRuleRepository.findMatchingRule() updating future auto-generated cycles when a transaction is edited).
6. Split Bills & Shared Debts integration (ledger cash flow contract: master expense on user pay, debt repayments as Daily Income, friend pay personal liability on settle up).
7. 100% offline receipt OCR (ML Kit local), WhatsApp payment reminder template sharing, authentic currency symbol badges.
