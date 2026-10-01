page 50102 "PRX Purch. Exception Card"
{
    Caption = 'Purchase Receiving Exception';
    PageType = Card;
    SourceTable = "PRX Purch. Exception";
    UsageCategory = None;
    ApplicationArea = All;
    // Receiving users have Insert but not Modify, so the record is only written once.
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                // Saved exceptions are changed only through Resolve.
                Editable = IsNewRecord;

                field("No."; Rec."No.")
                {
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Item Description"; Rec."Item Description")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
            }
            group(Problem)
            {
                Caption = 'Problem';
                Editable = IsNewRecord;

                field("Delivery Reference"; Rec."Delivery Reference")
                {
                }
                field("Reported Date"; Rec."Reported Date")
                {
                }
                field(Reason; Rec.Reason)
                {
                    ShowMandatory = true;
                }
                field(Description; Rec.Description)
                {
                    MultiLine = true;
                    ShowMandatory = true;
                }
                field("Affected Quantity"; Rec."Affected Quantity")
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Requires Invoice Review"; Rec."Requires Invoice Review")
                {
                }
            }
            group(StatusAndHistory)
            {
                Caption = 'Status and History';

                field(Status; Rec.Status)
                {
                }
                field("Created By"; Rec."Created By")
                {
                }
                field("Created At"; Rec."Created At")
                {
                }
                field("Resolved By"; Rec."Resolved By")
                {
                }
                field("Resolved At"; Rec."Resolved At")
                {
                }
                field("Resolution Notes"; Rec."Resolution Notes")
                {
                    MultiLine = true;
                }
                field(SystemIdentifier; Rec.SystemId)
                {
                    Caption = 'System ID';
                    ToolTip = 'Specifies the permanent technical identifier of the record. Unlike the exception number it never changes, which is what an API or integration would use to identify the record.';
                    Importance = Additional;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Resolve)
            {
                Caption = 'Resolve';
                ToolTip = 'Marks the exception as resolved after you enter resolution notes. Only users with the PRX MANAGER permission set can do this. Resolving does not change the purchase order, receipts or invoices.';
                Image = Approve;
                Enabled = IsOpen;

                trigger OnAction()
                var
                    PRXResolveException: Codeunit "PRX Resolve Exception";
                    PRXResolveDialog: Page "PRX Resolve Exc. Dialog";
                begin
                    PRXResolveDialog.SetException(Rec);
                    if PRXResolveDialog.RunModal() <> Action::OK then
                        exit;
                    PRXResolveException.Resolve(Rec, PRXResolveDialog.GetResolutionNotes());
                    CurrPage.Update(false);
                end;
            }
            action(ShowSourceDocument)
            {
                Caption = 'Show Purchase Order';
                ToolTip = 'Opens the purchase order this exception belongs to. If the order no longer exists, a message explains this and the exception keeps its recorded details.';
                Image = Order;

                trigger OnAction()
                var
                    PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
                begin
                    PRXExceptionMgt.OpenSourceDocument(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Resolve_Promoted; Resolve)
            {
            }
            actionref(ShowSourceDocument_Promoted; ShowSourceDocument)
            {
            }
        }
    }

    var
        IsOpen: Boolean;
        IsNewRecord: Boolean;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocumentNo: Code[20];
    begin
        IsNewRecord := true;
        Rec."Reported Date" := WorkDate();
        // Pre-fill the order when opened from "New Exception" on the Purchase Order.
        DocumentNo := GetDocumentNoFromFilter();
        if DocumentNo <> '' then
            Rec.Validate("Document No.", DocumentNo);
    end;

    local procedure GetDocumentNoFromFilter() DocumentNo: Code[20]
    var
        CurrentFilterGroup: Integer;
        Group: Integer;
    begin
        // RunPageLink filter group is not fixed, so check each group for a single order number.
        CurrentFilterGroup := Rec.FilterGroup();
        for Group := 0 to 6 do
            if DocumentNo = '' then begin
                Rec.FilterGroup(Group);
                if Rec.GetFilter("Document No.") <> '' then
                    if Rec.GetRangeMin("Document No.") = Rec.GetRangeMax("Document No.") then
                        DocumentNo := Rec.GetRangeMin("Document No.");
            end;
        Rec.FilterGroup(CurrentFilterGroup);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
        // CurrPage.Editable did not work here, so the groups use IsNewRecord.
        IsNewRecord := Rec."No." = '';
    end;
}
