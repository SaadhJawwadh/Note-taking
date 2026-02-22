# Note Book v1.13.0 — Custom Categories, Smarter SMS & Better Previews

## What's New

### Custom Category Management
Create your own transaction categories with a name, colour, and keywords. Edit the keywords for any built-in category too. Accessible from **Settings → Financial Manager → Manage Categories**. Changes take effect immediately for new SMS imports and manual transactions.

### Transaction Search
A search bar now appears above the category filter chips on the Finances screen. Filter transactions by description or category name in real time with a clear button to reset.

### Date-Range Net Balance Card
The hero card at the top of the Finances screen now shows the **net balance for your selected date range** rather than an all-time figure, giving you an instant read on the period you're viewing.

### Long-Press to Delete Transactions
Long-press any transaction card to get a confirmation dialog for deletion — no need to open the editor.

### Note Checklist Preview
Quill-format notes with checklist items now show **☐ unchecked** and **☑ checked** symbols in home-screen note cards, so you can see your list state at a glance.

### Better Note Preview (4-line limit)
Note card previews are now capped at **4 lines** of content for both rich text and markdown notes, replacing the old 100-character limit.

## SMS Import Improvements

| Behaviour | Before | After |
|-----------|--------|-------|
| Promotional messages | Imported | Skipped |
| Cancelled / declined transactions | Imported | Skipped |
| Reversal / refund SMS | Imported as income | Original expense deleted |
| Salary / fund transfer credit | Missed | Imported as income |
| "PickMe Food" vs "PickMe" | Both → Transport | Correctly Food vs Transport |
| "Uber Eats" vs "Uber" | Both → Transport | Correctly Food vs Transport |

---

*Fully local. No data leaves your device.*
