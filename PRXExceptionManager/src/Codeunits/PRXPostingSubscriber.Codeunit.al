codeunit 50102 "PRX Posting Subscriber"
{
    Access = Internal;

    var
        InvoiceBlockedErr: Label 'Purchase order %1 cannot be invoiced yet. Receiving exception %2 (%3: %4) is Open and requires invoice review. Ask a purchasing manager to review and resolve it, or post the receipt only.', Comment = '%1 = purchase order number, %2 = exception number, %3 = reason, %4 = description';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure BlockInvoiceWhileReviewExceptionOpen(var PurchaseHeader: Record "Purchase Header")
    begin
        CheckInvoicePostingAllowed(PurchaseHeader);
    end;

    // The user posting may not have a PRX permission set.
    [InherentPermissions(PermissionObjectType::TableData, Database::"PRX Purch. Exception", 'R')]
    local procedure CheckInvoicePostingAllowed(PurchaseHeader: Record "Purchase Header")
    var
        PRXPurchException: Record "PRX Purch. Exception";
    begin
        // Only purchase orders, and only when invoicing. Receipt-only posting is allowed.
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
            exit;
        if not PurchaseHeader.Invoice then
            exit;

        PRXPurchException.SetCurrentKey("Document Type", "Document No.", Status, "Requires Invoice Review");
        PRXPurchException.SetRange("Document Type", PurchaseHeader."Document Type");
        PRXPurchException.SetRange("Document No.", PurchaseHeader."No.");
        PRXPurchException.SetRange(Status, PRXPurchException.Status::Open);
        PRXPurchException.SetRange("Requires Invoice Review", true);
        if PRXPurchException.FindFirst() then
            Error(InvoiceBlockedErr, PurchaseHeader."No.", PRXPurchException."No.", PRXPurchException.Reason, PRXPurchException.Description);
    end;
}
