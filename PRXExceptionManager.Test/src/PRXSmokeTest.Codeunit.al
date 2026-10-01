codeunit 50140 "PRX Smoke Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure NewStatusDefaultsToOpen()
    var
        Status: Enum "PRX Exception Status";
    begin
        // [SCENARIO] A new status defaults to Open
        Assert.AreEqual(Enum::"PRX Exception Status"::Open, Status, 'Default status should be Open.');
    end;
}
