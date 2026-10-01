codeunit 50101 "PRX Resolve Exception"
{
    // Public for the test app; access is controlled by the permission sets.
    Access = Public;
    // Grants the modify that PRX MANAGER holds only indirectly.
    Permissions = tabledata "PRX Purch. Exception" = rm;

    var
        NotOpenErr: Label 'Exception %1 is already %2. Only Open exceptions can be resolved.', Comment = '%1 = exception number, %2 = current status';
        NotesRequiredErr: Label 'Enter resolution notes that explain how exception %1 was investigated and addressed.', Comment = '%1 = exception number';

    /// <summary>
    /// Moves an exception from Open to Resolved.
    /// </summary>
    procedure Resolve(var PRXPurchException: Record "PRX Purch. Exception"; ResolutionNotes: Text[250])
    begin
        // Lock and re-read in case two users resolve at the same time.
        PRXPurchException.LockTable();
        PRXPurchException.Get(PRXPurchException."No.");
        if PRXPurchException.Status <> PRXPurchException.Status::Open then
            Error(NotOpenErr, PRXPurchException."No.", PRXPurchException.Status);
        if DelChr(ResolutionNotes, '<>', ' ') = '' then
            Error(NotesRequiredErr, PRXPurchException."No.");

        PRXPurchException.Status := PRXPurchException.Status::Resolved;
        PRXPurchException."Resolution Notes" := ResolutionNotes;
        PRXPurchException."Resolved By" := CopyStr(UserId(), 1, MaxStrLen(PRXPurchException."Resolved By"));
        PRXPurchException."Resolved At" := CurrentDateTime();
        PRXPurchException.Modify(true);
    end;
}
