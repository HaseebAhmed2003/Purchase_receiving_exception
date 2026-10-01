codeunit 50144 "PRX Permission Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Test data is created first, then the session is restricted with Permissions Mock.

    var
        PRXTestLibrary: Codeunit "PRX Test Library";
        PermissionsMock: Codeunit "Permissions Mock";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ManagerCanResolve()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        ExceptionNo: Code[20];
    begin
        // [SCENARIO] With only PRX MANAGER, a user can resolve through the Resolve codeunit
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, PurchaseLine."Line No.", true);

        // [WHEN] the session runs with only the manager permission set
        PermissionsMock.Set('PRX MANAGER');
        PRXTestLibrary.ResolveException(ExceptionNo);
        PermissionsMock.ClearAssignments();

        // [THEN] the exception is resolved
        PRXPurchException.Get(ExceptionNo);
        Assert.AreEqual(Enum::"PRX Exception Status"::Resolved, PRXPurchException.Status, 'Manager should be able to resolve.');
    end;

    [Test]
    procedure ManagerCannotEditDirectly()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PRXPurchException: Record "PRX Purch. Exception";
        ExceptionNo: Code[20];
    begin
        // [SCENARIO] A manager cannot modify an exception outside the Resolve codeunit
        PRXTestLibrary.Initialize();
        PRXTestLibrary.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, 20);
        ExceptionNo := PRXTestLibrary.CreateException(PurchaseHeader, 0, true);

        PermissionsMock.Set('PRX MANAGER');
        PRXPurchException.Get(ExceptionNo);
        PRXPurchException.Description := 'Edited outside the controlled operation';
        asserterror PRXPurchException.Modify(true);
        PermissionsMock.ClearAssignments();

        Assert.ExpectedErrorCode('DB:ClientModifyDenied');
    end;
}
