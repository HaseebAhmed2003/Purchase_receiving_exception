codeunit 50142 "PRX Exception Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        PRXTestLibrary: Codeunit "PRX Test Library";
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
        Assert: Codeunit "Library Assert";
        LineNotOnOrderErr: Label 'does not belong to purchase order %1', Comment = '%1 = purchase order number', Locked = true;
        ResolvedReadOnlyErr: Label 'Exception %1 is resolved and can no longer be changed or deleted.', Comment = '%1 = exception number', Locked = true;

    [Test]
    procedure ValidExceptionCanBeCreated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
    begin
        // [SCENARIO] A valid line-level exception is saved Open with vendor and item from the order
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);

        // [WHEN] an exception is created for the line
        PRXPurchException.Get(PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", true));

        // [THEN] it is Open and carries the context derived from the order and line
        Assert.AreNotEqual('', PRXPurchException."No.", 'Exception should get a number from the number series.');
        Assert.AreEqual(Enum::"PRX Exception Status"::Open, PRXPurchException.Status, 'New exception should be Open.');
        Assert.AreEqual(PurchaseHeader."Buy-from Vendor No.", PRXPurchException."Vendor No.", 'Vendor No. should come from the order.');
        Assert.AreEqual(PurchaseHeader."Buy-from Vendor Name", PRXPurchException."Vendor Name", 'Vendor Name should come from the order.');
        Assert.AreEqual(PurchaseLine."No.", PRXPurchException."Item No.", 'Item No. should come from the line.');
        Assert.AreEqual(PurchaseLine.Description, PRXPurchException."Item Description", 'Item Description should come from the line.');
        Assert.AreEqual(PurchaseLine."Unit of Measure Code", PRXPurchException."Unit of Measure Code", 'Unit of measure should come from the line.');
        Assert.AreEqual(UserId(), PRXPurchException."Created By", 'Created By should be the current user.');
        Assert.AreEqual(8, PRXPurchException."Affected Quantity", 'Affected quantity should be stored.');
    end;

    [Test]
    procedure NewExceptionAlwaysStartsOpen()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
    begin
        // [SCENARIO] An exception inserted as Resolved is saved as Open
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);

        PRXPurchException.Init();
        PRXPurchException.Validate("Document No.", PurchaseHeader."No.");
        PRXPurchException.Validate(Reason, PRXPurchException.Reason::Other);
        PRXPurchException.Validate(Description, 'Paperwork discrepancy');
        PRXPurchException.Status := PRXPurchException.Status::Resolved;
        PRXPurchException."Resolved By" := 'SOMEONE';
        PRXPurchException.Insert(true);

        PRXPurchException.Get(PRXPurchException."No.");
        Assert.AreEqual(Enum::"PRX Exception Status"::Open, PRXPurchException.Status, 'Inserted exception must be Open.');
        Assert.AreEqual('', PRXPurchException."Resolved By", 'Resolved By must be cleared on insert.');
    end;

    [Test]
    procedure OrderMustExist()
    begin
        // [SCENARIO] An exception cannot reference a purchase order that does not exist
        PRXTestLibrary.Initialize();
        asserterror PRXExceptionMgt.CreateException('PRX-NO-SUCH-PO', 0, Enum::"PRX Exception Reason"::Other, 'x', '', 0, false);
        Assert.ExpectedError('Purchase order PRX-NO-SUCH-PO does not exist.');
    end;

    [Test]
    procedure LineFromDifferentOrderIsRejected()
    var
        OrderA: Record "Purchase Header";
        OrderB: Record "Purchase Header";
        LineA: Record "Purchase Line";
        LineB: Record "Purchase Line";
        SecondLineB: Record "Purchase Line";
    begin
        // [SCENARIO] A line number that exists only on another order is rejected
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(OrderA, LineA, 20);   // order A has one line
        PRXTestLibrary.CreatePurchaseOrder(OrderB, LineB, 5);
        PRXTestLibrary.AddItemLine(OrderB, SecondLineB, 5);      // order B has a second line

        // [WHEN] order B's second line number is used with order A
        asserterror PRXExceptionMgt.CreateException(OrderA."No.", SecondLineB."Line No.",
            Enum::"PRX Exception Reason"::"Wrong Item", 'Wrong item', '', 0, false);

        // [THEN] it is rejected
        Assert.ExpectedError(StrSubstNo(LineNotOnOrderErr, OrderA."No."));
    end;

    [Test]
    procedure ReasonIsRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Saving without a reason fails
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        asserterror PRXExceptionMgt.CreateException(PurchaseHeader."No.", 0, Enum::"PRX Exception Reason"::" ", 'Something happened', '', 0, false);
        Assert.ExpectedError('Select a reason for the exception.');
    end;

    [Test]
    procedure DescriptionIsRequired()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Saving without a description (or only spaces) fails
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        asserterror PRXExceptionMgt.CreateException(PurchaseHeader."No.", 0, Enum::"PRX Exception Reason"::Other, '   ', '', 0, false);
        Assert.ExpectedError('Describe what was observed before saving the exception.');
    end;

    [Test]
    procedure AffectedQuantityMustBePositive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] A negative affected quantity is rejected
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        asserterror PRXExceptionMgt.CreateException(PurchaseHeader."No.", PurchaseLine."Line No.",
            Enum::"PRX Exception Reason"::"Damaged Goods", 'Two damaged', '', -2, false);
        Assert.ExpectedError('The affected quantity must be greater than zero.');
    end;

    [Test]
    procedure AffectedQuantityNeedsALine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] An affected quantity without a purchase line is rejected
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        asserterror PRXExceptionMgt.CreateException(PurchaseHeader."No.", 0,
            Enum::"PRX Exception Reason"::"Damaged Goods", 'Two damaged', '', 2, false);
        Assert.ExpectedError('An affected quantity can only be entered when a purchase line is selected.');
    end;

    [Test]
    procedure AffectedQuantityMayExceedReceivedQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
    begin
        // [SCENARIO] For missing units the affected quantity can be larger than what was received
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        PRXTestLibrary.ReceivePartially(PurchaseHeader, PurchaseLine, 5);

        // [WHEN] 8 units are reported missing although only 5 were received
        PRXPurchException.Get(PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", false));

        // [THEN] the exception is accepted
        Assert.AreEqual(8, PRXPurchException."Affected Quantity", 'Affected quantity larger than received should be allowed.');
    end;

    [Test]
    procedure FlowFieldCountsOnlyThisOrdersOpenExceptions()
    var
        OrderA: Record "Purchase Header";
        OrderB: Record "Purchase Header";
        LineA: Record "Purchase Line";
        LineB: Record "Purchase Line";
    begin
        // [SCENARIO] The count includes only Open exceptions of the same order
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(OrderA, LineA, 20);
        PRXTestLibrary.CreatePurchaseOrder(OrderB, LineB, 20);

        // [GIVEN] order A: two Open and one Resolved exception; order B: one Open exception
        PRXTestLibrary.CreateException(OrderA, LineA."Line No.", true);
        PRXTestLibrary.CreateException(OrderA, 0, false);
        PRXTestLibrary.ResolveException(PRXTestLibrary.CreateException(OrderA, 0, false));
        PRXTestLibrary.CreateException(OrderB, 0, true);

        // [THEN]
        Assert.AreEqual(2, PRXTestLibrary.GetOpenExceptionCount(OrderA), 'Order A should count its two Open exceptions only.');
        Assert.AreEqual(1, PRXTestLibrary.GetOpenExceptionCount(OrderB), 'Order B should count only its own exception.');
    end;

    [Test]
    procedure ResolvingRemovesExceptionFromOpenCount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        ExceptionNo: Code[20];
    begin
        // [SCENARIO] Resolving removes the exception from the open count
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", true);
        Assert.AreEqual(1, PRXTestLibrary.GetOpenExceptionCount(PurchaseHeader), 'One open exception expected before resolving.');

        PRXTestLibrary.ResolveException(ExceptionNo);

        Assert.AreEqual(0, PRXTestLibrary.GetOpenExceptionCount(PurchaseHeader), 'Open count should be 0 after resolving.');
        PRXPurchException.Get(ExceptionNo);
        Assert.AreEqual(Enum::"PRX Exception Status"::Resolved, PRXPurchException.Status, 'Status should be Resolved.');
        Assert.AreEqual(UserId(), PRXPurchException."Resolved By", 'Resolved By should be the current user.');
        Assert.AreNotEqual(0DT, PRXPurchException."Resolved At", 'Resolved At should be set.');
        Assert.AreNotEqual('', PRXPurchException."Resolution Notes", 'Resolution notes should be stored.');
    end;

    [Test]
    procedure ResolutionWithoutExplanationIsRejected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        PRXResolveException: Codeunit "PRX Resolve Exception";
    begin
        // [SCENARIO] Resolve requires notes; blank or spaces-only notes are rejected
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        PRXPurchException.Get(PRXTestLibrary.CreateException(PurchaseHeader, 0, true));

        asserterror PRXResolveException.Resolve(PRXPurchException, '   ');
        Assert.ExpectedError('Enter resolution notes');
        // asserterror rolls back the transaction, so the record cannot be re-read here.
    end;

    [Test]
    procedure ResolvedExceptionCannotBeResolvedAgain()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        PRXResolveException: Codeunit "PRX Resolve Exception";
        ExceptionNo: Code[20];
    begin
        // [SCENARIO] Open -> Resolved only: a second Resolve is refused
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, 0, true);
        PRXTestLibrary.ResolveException(ExceptionNo);

        PRXPurchException.Get(ExceptionNo);
        asserterror PRXResolveException.Resolve(PRXPurchException, 'Second attempt');
        Assert.ExpectedError('Only Open exceptions can be resolved.');
    end;

    [Test]
    procedure ResolvedExceptionCannotBeModified()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        ExceptionNo: Code[20];
    begin
        // [SCENARIO] A Resolved exception cannot be modified
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, 0, true);
        PRXTestLibrary.ResolveException(ExceptionNo);

        PRXPurchException.Get(ExceptionNo);
        PRXPurchException.Description := 'Rewritten history';
        asserterror PRXPurchException.Modify(true);
        Assert.ExpectedError(StrSubstNo(ResolvedReadOnlyErr, ExceptionNo));
    end;

    [Test]
    procedure ResolvedExceptionCannotBeDeleted()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        ExceptionNo: Code[20];
    begin
        // [SCENARIO] A Resolved exception cannot be deleted
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, 0, true);
        PRXTestLibrary.ResolveException(ExceptionNo);

        PRXPurchException.Get(ExceptionNo);
        asserterror PRXPurchException.Delete(true);
        Assert.ExpectedError(StrSubstNo(ResolvedReadOnlyErr, ExceptionNo));
    end;

    [Test]
    [HandlerFunctions('SourceMissingMessageHandler')]
    procedure HistoryStaysReadableWhenOrderIsGone()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        OrderNo: Code[20];
        VendorName: Text[100];
        ItemDescription: Text[100];
    begin
        // [SCENARIO] After the order is deleted, the exception is still readable
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        PRXPurchException.Get(PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", false));
        OrderNo := PurchaseHeader."No.";
        VendorName := PurchaseHeader."Buy-from Vendor Name";
        ItemDescription := PurchaseLine.Description;

        // [WHEN] the order is deleted
        PurchaseHeader.Get(PurchaseHeader."Document Type", OrderNo);
        PurchaseHeader.Delete(true);

        // [THEN] the exception still shows what was recorded
        PRXPurchException.Get(PRXPurchException."No.");
        Assert.AreEqual(OrderNo, PRXPurchException."Document No.", 'Order number must be kept.');
        Assert.AreEqual(VendorName, PRXPurchException."Vendor Name", 'Vendor name snapshot must be kept.');
        Assert.AreEqual(ItemDescription, PRXPurchException."Item Description", 'Item description snapshot must be kept.');
        // [THEN] Show Purchase Order shows a message instead of an error
        PRXExceptionMgt.OpenSourceDocument(PRXPurchException);
    end;

    [MessageHandler]
    procedure SourceMissingMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'no longer exists') > 0, 'Expected the "order no longer exists" message, got: ' + Message);
    end;
}
