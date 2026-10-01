page 50101 "PRX Purch. Exception List"
{
    Caption = 'Purchase Receiving Exceptions';
    PageType = List;
    SourceTable = "PRX Purch. Exception";
    CardPageId = "PRX Purch. Exception Card";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    SourceTableView = sorting("No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Exceptions)
            {
                field("No."; Rec."No.")
                {
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field(Reason; Rec.Reason)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Reported Date"; Rec."Reported Date")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Requires Invoice Review"; Rec."Requires Invoice Review")
                {
                }
                field("Delivery Reference"; Rec."Delivery Reference")
                {
                    Visible = false;
                }
                field("Resolved By"; Rec."Resolved By")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
        area(Reporting)
        {
            action(OpenExceptionsByVendor)
            {
                Caption = 'Open Exceptions by Vendor';
                ToolTip = 'Prints the open purchasing exceptions grouped by vendor, with the number of open exceptions per vendor.';
                Image = Report;
                RunObject = report "PRX Open Exc. by Vendor";
            }
        }
        area(Promoted)
        {
            actionref(ShowSourceDocument_Promoted; ShowSourceDocument)
            {
            }
            actionref(OpenExceptionsByVendor_Promoted; OpenExceptionsByVendor)
            {
            }
        }
    }

    views
    {
        view(OpenExceptions)
        {
            Caption = 'Open';
            Filters = where(Status = const(Open));
        }
        view(BlockingInvoice)
        {
            Caption = 'Open, requires invoice review';
            Filters = where(Status = const(Open), "Requires Invoice Review" = const(true));
        }
        view(ResolvedExceptions)
        {
            Caption = 'Resolved';
            Filters = where(Status = const(Resolved));
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.Status = Rec.Status::Open then
            StatusStyle := Format(PageStyle::Attention)
        else
            StatusStyle := Format(PageStyle::Favorable);
    end;
}
