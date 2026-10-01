pageextension 50100 "PRX Purchase Order" extends "Purchase Order"
{
    layout
    {
        addafter(Status)
        {
            field("PRX Open Exception Count"; Rec."PRX Open Exception Count")
            {
                ApplicationArea = All;
                StyleExpr = OpenExceptionStyle;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group(PRXExceptions)
            {
                Caption = 'Receiving Exceptions';
                Image = Warning;

                action(PRXShowExceptions)
                {
                    ApplicationArea = All;
                    Caption = 'Exceptions';
                    ToolTip = 'Shows the open receiving exceptions for this order. These are exactly the exceptions counted in the Open Exceptions field.';
                    Image = List;
                    RunObject = page "PRX Purch. Exception List";
                    // Same filters as the PRX Open Exception Count FlowField
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No."),
                                  Status = const(Open);
                }
                action(PRXNewException)
                {
                    ApplicationArea = All;
                    Caption = 'New Exception';
                    ToolTip = 'Records a new receiving exception for this order. The order, vendor and location are filled in for you.';
                    Image = New;
                    RunObject = page "PRX Purch. Exception Card";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                    RunPageMode = Create;
                }
            }
        }
        addlast(Promoted)
        {
            group(PRXCategoryExceptions)
            {
                Caption = 'Receiving Exceptions';

                actionref(PRXNewException_Promoted; PRXNewException)
                {
                }
                actionref(PRXShowExceptions_Promoted; PRXShowExceptions)
                {
                }
            }
        }
    }

    var
        OpenExceptionStyle: Text;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("PRX Open Exception Count");
        if Rec."PRX Open Exception Count" > 0 then
            OpenExceptionStyle := Format(PageStyle::Unfavorable)
        else
            OpenExceptionStyle := Format(PageStyle::Standard);
    end;
}
