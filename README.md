# PRX Purchase Receiving Exception Manager

A Business Central AL extension for recording delivery problems against purchase orders
(short deliveries, damaged goods, wrong items) and holding back invoice posting until a
purchasing manager has reviewed them.

A 4-page illustrated walkthrough of the demo is in [docs/PRX_Illustrated_Walkthrough.pdf](docs/PRX_Illustrated_Walkthrough.pdf).

## What it does

- **Exception record** per problem, linked to a purchase order and optionally a line: reason,
  supplier delivery reference, affected quantity, description. Vendor, item, unit of measure and
  location are copied from the order, so the record stays readable after the order is deleted.
- **Purchase Order integration:** an *Open Exceptions* count and actions to view or create
  exceptions for the order.
- **Invoice restriction:** posting an invoice from a purchase order is blocked while the order has
  an Open exception marked *Requires Invoice Review*. Receipt-only posting is not blocked.
  Implemented as a subscriber to `OnBeforePostPurchaseDoc` in codeunit 90 "Purch.-Post"; standard
  posting itself is unchanged.
- **Controlled resolution:** an exception can only move from Open to Resolved, with notes, through
  the Resolve action. Who resolved it and when is recorded.
- **Permission sets:**
  - `PRX RECEIVING`: read and create exceptions.
  - `PRX MANAGER`: includes PRX RECEIVING and adds indirect modify, which is only usable
    through the Resolve codeunit.

  Both are meant to be assigned on top of standard purchasing permission sets.
- **Report:** Open Purchasing Exceptions by Vendor (RDLC).

## Tested environment

- Business Central 28.5 on-premises (US), CRONUS USA demo company
- AL runtime 17.0; compiled with CodeCop, UICop and PerTenantExtensionCop (no warnings)
- Manually tested with two Windows users:
  - receiver1: D365 BASIC, D365 PURCH DOC, EDIT, D365 PURCH DOC, POST, D365 JOBS, VIEW and PRX RECEIVING
  - manager1: the same standard sets and PRX MANAGER

  D365 JOBS, VIEW is needed for invoice-only posting of received lines, which reads the Job
  Planning Line table.

## Project structure

```
PRXExceptionManager/        main app  (object IDs 50100-50139)
PRXExceptionManager.Test/   test app  (object IDs 50140-50149)
docs/                       illustrated walkthrough (PDF)
```

## Installation

1. Open `PRXExceptionManager.code-workspace` in VS Code with the AL Language extension.
2. Update `.vscode/launch.json` in both folders for your server (the defaults are `localhost`,
   port 7049, instance `BC280`, Windows authentication).
3. Download symbols and publish the main app, then the test app. The test app needs Microsoft's
   Application Test Library, Library Assert, Any and Permissions Mock.
4. On install, the setup record and the `PRX-EXC` number series are created. For demo data, open
   **Purchase Exception Setup** and choose **Create Demo Data** (one vendor and one item).
5. Assign `PRX RECEIVING` or `PRX MANAGER` to users in addition to their purchasing permission sets.

## Tests

22 tests, all passing in the AL Test Tool (page 130451):

| Codeunit | Tests | Covers |
|---|---|---|
| 50140 PRX Smoke Test | 1 | Default status |
| 50142 PRX Exception Tests | 16 | Creation rules, open-exception count, resolution rules, read-only resolved records, history after the order is deleted |
| 50143 PRX Posting Tests | 3 | Invoice posts after resolution; non-blocking exceptions and other orders' exceptions don't block |
| 50144 PRX Permission Tests | 2 | Manager can resolve; manager cannot modify directly (Permissions Mock) |

The blocked invoice, receipt-only posting and a receiving user being refused on Resolve were
verified manually with the two users above.

## Known limitations

- The restriction is order-level: one review-required exception also blocks invoicing other lines
  on the same order.
- Only purchase-order posting through "Purch.-Post" is tested. Separate purchase invoices, warehouse
  receipts and other posting routes are not verified.
- No links to posted receipts or invoices, and no reopen or cancel (Open → Resolved only).
- Saved exceptions cannot be edited by receiving users or managers.
