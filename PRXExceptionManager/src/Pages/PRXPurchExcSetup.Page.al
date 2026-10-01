page 50100 "PRX Purch. Exc. Setup"
{
    Caption = 'Purchase Exception Setup';
    PageType = Card;
    SourceTable = "PRX Purch. Exc. Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Exception Nos."; Rec."Exception Nos.")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateDemoData)
            {
                Caption = 'Create Demo Data';
                ToolTip = 'Creates the synthetic vendor "Riyadh Leather Supplies" and item "Handbag - Tan Tote" used for the demo. Running it again does not create duplicates.';
                Image = CreateDocument;

                trigger OnAction()
                var
                    PRXDemoData: Codeunit "PRX Demo Data";
                begin
                    PRXDemoData.CreateDemoData();
                end;
            }
        }
        area(Promoted)
        {
            actionref(CreateDemoData_Promoted; CreateDemoData)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
    begin
        // For companies created after the app was installed.
        PRXExceptionMgt.EnsureSetup();
        Rec.Get();
    end;
}
