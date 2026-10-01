codeunit 50100 "PRX Exception Mgt."
{
    // Public for the test app.
    Access = Public;

    var
        NoSeriesCodeTok: Label 'PRX-EXC', Locked = true;
        NoSeriesDescriptionLbl: Label 'Purchase receiving exceptions';
        NoSeriesStartingNoTok: Label 'PEX-00001', Locked = true;
        OnlyPurchaseOrdersErr: Label 'Receiving exceptions can only be recorded for purchase orders.';
        OrderNotFoundErr: Label 'Purchase order %1 does not exist.', Comment = '%1 = purchase order number';
        LineNotOnOrderErr: Label 'Line %1 does not belong to purchase order %2. Choose a line from that order.', Comment = '%1 = line number, %2 = purchase order number';
        ReasonRequiredErr: Label 'Select a reason for the exception.';
        DescriptionRequiredErr: Label 'Describe what was observed before saving the exception.';
        AffectedQtyNotPositiveErr: Label 'The affected quantity must be greater than zero. Leave it blank if the problem is not about a quantity.';
        AffectedQtyNeedsLineErr: Label 'An affected quantity can only be entered when a purchase line is selected.';
        AffectedQtyNeedsItemLineErr: Label 'An affected quantity can only be entered for an item line. Line %1 on purchase order %2 is of type %3.', Comment = '%1 = line number, %2 = purchase order number, %3 = line type';
        ResolvedReadOnlyErr: Label 'Exception %1 is resolved and can no longer be changed or deleted.', Comment = '%1 = exception number';
        RenameNotAllowedErr: Label 'Receiving exceptions cannot be renumbered.';
        SourceMissingMsg: Label 'Purchase order %1 no longer exists. Exception %2 still shows the vendor, item and delivery details that were recorded with it.', Comment = '%1 = purchase order number, %2 = exception number';

    /// <summary>
    /// Creates the setup record and number series if they are missing.
    /// </summary>
    procedure EnsureSetup()
    var
        PRXPurchExcSetup: Record "PRX Purch. Exc. Setup";
    begin
        if not PRXPurchExcSetup.Get() then begin
            PRXPurchExcSetup.Init();
            PRXPurchExcSetup.Insert();
        end;
        if PRXPurchExcSetup."Exception Nos." <> '' then
            exit;
        CreateNoSeries();
        PRXPurchExcSetup."Exception Nos." := NoSeriesCodeTok;
        PRXPurchExcSetup.Modify();
    end;

    local procedure CreateNoSeries()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get(NoSeriesCodeTok) then begin
            NoSeries.Init();
            NoSeries.Code := NoSeriesCodeTok;
            NoSeries.Description := NoSeriesDescriptionLbl;
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := false;
            NoSeries.Insert();
        end;
        NoSeriesLine.SetRange("Series Code", NoSeriesCodeTok);
        if not NoSeriesLine.IsEmpty() then
            exit;
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeriesCodeTok;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", NoSeriesStartingNoTok);
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Insert(true);
    end;

    /// <summary>
    /// Creates an exception using the same validation as the page.
    /// </summary>
    procedure CreateException(DocumentNo: Code[20]; DocumentLineNo: Integer; NewReason: Enum "PRX Exception Reason"; NewDescription: Text[250]; DeliveryReference: Text[35]; AffectedQuantity: Decimal; RequiresInvoiceReview: Boolean): Code[20]
    var
        PRXPurchException: Record "PRX Purch. Exception";
    begin
        PRXPurchException.Init();
        PRXPurchException.Validate("Document No.", DocumentNo);
        if DocumentLineNo <> 0 then
            PRXPurchException.Validate("Document Line No.", DocumentLineNo);
        PRXPurchException.Validate(Reason, NewReason);
        PRXPurchException.Validate(Description, NewDescription);
        PRXPurchException.Validate("Delivery Reference", DeliveryReference);
        PRXPurchException.Validate("Affected Quantity", AffectedQuantity);
        PRXPurchException.Validate("Requires Invoice Review", RequiresInvoiceReview);
        PRXPurchException.Insert(true);
        exit(PRXPurchException."No.");
    end;

    /// <summary>
    /// Copies vendor and location from the order.
    /// </summary>
    procedure ValidateDocumentNo(var PRXPurchException: Record "PRX Purch. Exception")
    begin
        PRXPurchException."Document Line No." := 0;
        ClearLineSnapshot(PRXPurchException);
        PRXPurchException."Affected Quantity" := 0;
        if PRXPurchException."Document No." = '' then begin
            ClearHeaderSnapshot(PRXPurchException);
            exit;
        end;
        CopyFromOrder(PRXPurchException);
    end;

    /// <summary>
    /// The line must belong to the selected order.
    /// </summary>
    procedure ValidateDocumentLineNo(var PRXPurchException: Record "PRX Purch. Exception")
    begin
        ClearLineSnapshot(PRXPurchException);
        if PRXPurchException."Document Line No." = 0 then begin
            if PRXPurchException."Document No." <> '' then
                CopyFromOrder(PRXPurchException);
            PRXPurchException."Affected Quantity" := 0;
            exit;
        end;
        PRXPurchException.TestField("Document No.");
        CopyFromLine(PRXPurchException);
        CheckAffectedQuantity(PRXPurchException);
    end;

    /// <summary>
    /// Optional; must be positive and on an item line.
    /// Not compared with the received quantity (missing units can exceed it).
    /// </summary>
    procedure CheckAffectedQuantity(PRXPurchException: Record "PRX Purch. Exception")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PRXPurchException."Affected Quantity" = 0 then
            exit;
        if PRXPurchException."Affected Quantity" < 0 then
            Error(AffectedQtyNotPositiveErr);
        if PRXPurchException."Document Line No." = 0 then
            Error(AffectedQtyNeedsLineErr);
        GetLine(PRXPurchException, PurchaseLine);
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            Error(AffectedQtyNeedsItemLineErr, PurchaseLine."Line No.", PurchaseLine."Document No.", PurchaseLine.Type);
    end;

    /// <summary>
    /// Runs from OnInsert.
    /// </summary>
    procedure PrepareForInsert(var PRXPurchException: Record "PRX Purch. Exception")
    begin
        if PRXPurchException."Document Type" <> PRXPurchException."Document Type"::Order then
            Error(OnlyPurchaseOrdersErr);
        PRXPurchException.TestField("Document No.");

        // Refresh the snapshot fields from the order.
        CopyFromOrder(PRXPurchException);
        if PRXPurchException."Document Line No." <> 0 then
            CopyFromLine(PRXPurchException);

        if PRXPurchException.Reason = PRXPurchException.Reason::" " then
            Error(ReasonRequiredErr);
        if DelChr(PRXPurchException.Description, '<>', ' ') = '' then
            Error(DescriptionRequiredErr);
        CheckAffectedQuantity(PRXPurchException);

        PRXPurchException.Status := PRXPurchException.Status::Open;
        PRXPurchException."Resolved By" := '';
        PRXPurchException."Resolved At" := 0DT;
        PRXPurchException."Resolution Notes" := '';

        if PRXPurchException."Reported Date" = 0D then
            PRXPurchException."Reported Date" := WorkDate();
        PRXPurchException."Created By" := CopyStr(UserId(), 1, MaxStrLen(PRXPurchException."Created By"));
        PRXPurchException."Created At" := CurrentDateTime();

        // Get the number last so a failed insert does not use one.
        if PRXPurchException."No." = '' then
            PRXPurchException."No." := GetNextExceptionNo();
    end;

    /// <summary>
    /// Reads the stored record (not xRec) so the check also works when called from code.
    /// </summary>
    procedure CheckNotResolved(PRXPurchException: Record "PRX Purch. Exception")
    var
        StoredPRXPurchException: Record "PRX Purch. Exception";
    begin
        if not StoredPRXPurchException.Get(PRXPurchException."No.") then
            exit;
        if StoredPRXPurchException.Status = StoredPRXPurchException.Status::Resolved then
            Error(ResolvedReadOnlyErr, StoredPRXPurchException."No.");
    end;

    procedure ThrowRenameNotAllowed()
    begin
        Error(RenameNotAllowedErr);
    end;

    /// <summary>
    /// Opens the purchase order, or shows a message if it no longer exists.
    /// </summary>
    procedure OpenSourceDocument(PRXPurchException: Record "PRX Purch. Exception")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if not PurchaseHeader.Get(PRXPurchException."Document Type", PRXPurchException."Document No.") then begin
            Message(SourceMissingMsg, PRXPurchException."Document No.", PRXPurchException."No.");
            exit;
        end;
        Page.Run(Page::"Purchase Order", PurchaseHeader);
    end;

    local procedure GetNextExceptionNo(): Code[20]
    var
        PRXPurchExcSetup: Record "PRX Purch. Exc. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PRXPurchExcSetup.Get();
        PRXPurchExcSetup.TestField("Exception Nos.");
        exit(NoSeries.GetNextNo(PRXPurchExcSetup."Exception Nos."));
    end;

    local procedure CopyFromOrder(var PRXPurchException: Record "PRX Purch. Exception")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if not PurchaseHeader.Get(PRXPurchException."Document Type", PRXPurchException."Document No.") then
            Error(OrderNotFoundErr, PRXPurchException."Document No.");
        PRXPurchException."Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PRXPurchException."Vendor Name" := PurchaseHeader."Buy-from Vendor Name";
        PRXPurchException."Location Code" := PurchaseHeader."Location Code";
    end;

    local procedure CopyFromLine(var PRXPurchException: Record "PRX Purch. Exception")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetLine(PRXPurchException, PurchaseLine);
        if PurchaseLine.Type = PurchaseLine.Type::Item then
            PRXPurchException."Item No." := PurchaseLine."No."
        else
            PRXPurchException."Item No." := '';
        PRXPurchException."Item Description" := PurchaseLine.Description;
        PRXPurchException."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        if PurchaseLine."Location Code" <> '' then
            PRXPurchException."Location Code" := PurchaseLine."Location Code";
    end;

    local procedure GetLine(PRXPurchException: Record "PRX Purch. Exception"; var PurchaseLine: Record "Purchase Line")
    begin
        if not PurchaseLine.Get(PRXPurchException."Document Type", PRXPurchException."Document No.", PRXPurchException."Document Line No.") then
            Error(LineNotOnOrderErr, PRXPurchException."Document Line No.", PRXPurchException."Document No.");
    end;

    local procedure ClearHeaderSnapshot(var PRXPurchException: Record "PRX Purch. Exception")
    begin
        PRXPurchException."Vendor No." := '';
        PRXPurchException."Vendor Name" := '';
        PRXPurchException."Location Code" := '';
    end;

    local procedure ClearLineSnapshot(var PRXPurchException: Record "PRX Purch. Exception")
    begin
        PRXPurchException."Item No." := '';
        PRXPurchException."Item Description" := '';
        PRXPurchException."Unit of Measure Code" := '';
    end;
}
