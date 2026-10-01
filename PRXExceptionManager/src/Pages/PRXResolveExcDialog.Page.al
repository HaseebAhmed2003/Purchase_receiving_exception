page 50103 "PRX Resolve Exc. Dialog"
{
    Caption = 'Resolve Exception';
    PageType = StandardDialog;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Exception)
            {
                Caption = 'Exception';

                field(ExceptionNo; ExceptionNo)
                {
                    Caption = 'Exception No.';
                    ToolTip = 'Specifies the exception you are resolving.';
                    Editable = false;
                }
                field(ExceptionDescription; ExceptionDescription)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies what was reported.';
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(Resolution)
            {
                Caption = 'Resolution';

                field(ResolutionNotes; ResolutionNotes)
                {
                    Caption = 'Resolution Notes';
                    ToolTip = 'Specifies how the problem was investigated and addressed, for example "Supplier confirmed only 12 shipped; remaining 8 to follow on delivery DN-2044".';
                    MultiLine = true;
                    ShowMandatory = true;
                }
            }
        }
    }

    var
        ExceptionNo: Code[20];
        ExceptionDescription: Text[250];
        ResolutionNotes: Text[250];

    procedure SetException(PRXPurchException: Record "PRX Purch. Exception")
    begin
        ExceptionNo := PRXPurchException."No.";
        ExceptionDescription := PRXPurchException.Description;
    end;

    procedure GetResolutionNotes(): Text[250]
    begin
        exit(ResolutionNotes);
    end;
}
