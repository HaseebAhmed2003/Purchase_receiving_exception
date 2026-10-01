codeunit 50143 "PRX Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        PRXTestLibrary: Codeunit "PRX Test Library";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure InvoicePostingProceedsAfterResolution()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ExceptionNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] 20 ordered, 12 received, exception resolved, invoice posts
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", true);
        PRXTestLibrary.ReceivePartially(PurchaseHeader, PurchaseLine, 12);

        // [WHEN] the manager resolves the exception and the invoice is posted
        PRXTestLibrary.ResolveException(ExceptionNo);
        PostedInvoiceNo := PRXTestLibrary.PostInvoice(PurchaseHeader);

        // [THEN] a posted invoice exists for the order
        Assert.IsTrue(PurchInvHeader.Get(PostedInvoiceNo), 'Posted purchase invoice should exist.');
        Assert.AreEqual(PurchaseHeader."No.", PurchInvHeader."Order No.", 'Posted invoice should reference the order.');
    end;

    [Test]
    procedure NonBlockingExceptionDoesNotBlockInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] An Open exception WITHOUT "Requires Invoice Review" does not stop invoicing
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", false);

        PostedInvoiceNo := PRXTestLibrary.PostReceiveAndInvoice(PurchaseHeader);

        Assert.IsTrue(PurchInvHeader.Get(PostedInvoiceNo), 'Posted purchase invoice should exist.');
    end;

    [Test]
    procedure ExceptionOnAnotherOrderDoesNotBlock()
    var
        BlockedOrder: Record "Purchase Header";
        OtherOrder: Record "Purchase Header";
        BlockedLine: Record "Purchase Line";
        OtherLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] A blocking exception on order A does not affect order B
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(BlockedOrder, BlockedLine, 20);
        PRXTestLibrary.CreateException(BlockedOrder, BlockedLine."Line No.", true);
        PRXTestLibrary.CreatePurchaseOrder(OtherOrder, OtherLine, 10);

        PostedInvoiceNo := PRXTestLibrary.PostReceiveAndInvoice(OtherOrder);

        Assert.IsTrue(PurchInvHeader.Get(PostedInvoiceNo), 'Order B should post its invoice.');
    end;
}
