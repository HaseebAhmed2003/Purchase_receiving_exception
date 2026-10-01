codeunit 50141 "PRX Test Library"
{
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
        DefaultDescriptionTxt: Label 'Paperwork says 20 units shipped; only 12 arrived.', Locked = true;
        DefaultDeliveryRefTxt: Label 'DN-TEST-001', Locked = true;
        DefaultResolutionTxt: Label 'Supplier confirmed only 12 shipped; remaining 8 follow on a new delivery.', Locked = true;

    /// <summary>Creates the setup record and number series if they are missing.</summary>
    procedure Initialize()
    begin
        PRXExceptionMgt.EnsureSetup();
    end;

    /// <summary>Creates a purchase order for a new vendor with one item line of Quantity units.</summary>
    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        if PurchaseHeader."Vendor Invoice No." = '' then begin
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify(true);
        end;
        AddItemLine(PurchaseHeader, PurchaseLine, Quantity);
    end;

    /// <summary>Adds another item line to an existing order.</summary>
    procedure AddItemLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", 45);
        PurchaseLine.Modify(true);
    end;

    /// <summary>Creates a quantity-discrepancy exception on the given line (0 = order level).</summary>
    procedure CreateException(PurchaseHeader: Record "Purchase Header"; LineNo: Integer; RequiresInvoiceReview: Boolean): Code[20]
    var
        AffectedQuantity: Decimal;
    begin
        if LineNo <> 0 then
            AffectedQuantity := 8;
        exit(PRXExceptionMgt.CreateException(PurchaseHeader."No.", LineNo, Enum::"PRX Exception Reason"::"Quantity Discrepancy",
            DefaultDescriptionTxt, DefaultDeliveryRefTxt, AffectedQuantity, RequiresInvoiceReview));
    end;

    /// <summary>Resolves an exception with standard resolution notes.</summary>
    procedure ResolveException(ExceptionNo: Code[20])
    var
        PRXPurchException: Record "PRX Purch. Exception";
        PRXResolveException: Codeunit "PRX Resolve Exception";
    begin
        PRXPurchException.Get(ExceptionNo);
        PRXResolveException.Resolve(PRXPurchException, DefaultResolutionTxt);
    end;

    /// <summary>Receives QtyToReceive units of the line (receipt only, no invoice).</summary>
    procedure ReceivePartially(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal): Code[20]
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    /// <summary>Posts only the invoice for what has been received so far.</summary>
    procedure PostInvoice(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    /// <summary>Posts receipt and invoice in one run ("Receive and Invoice").</summary>
    procedure PostReceiveAndInvoice(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    /// <summary>Returns the number of Open exceptions on the order through the FlowField.</summary>
    procedure GetOpenExceptionCount(PurchaseHeader: Record "Purchase Header"): Integer
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.CalcFields("PRX Open Exception Count");
        exit(PurchaseHeader."PRX Open Exception Count");
    end;
}
