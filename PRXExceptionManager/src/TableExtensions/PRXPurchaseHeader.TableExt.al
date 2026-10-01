tableextension 50100 "PRX Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(50100; "PRX Open Exception Count"; Integer)
        {
            Caption = 'Open Exceptions';
            ToolTip = 'Specifies how many receiving exceptions for this order are still Open. Choose the number to see them.';
            FieldClass = FlowField;
            // Keep in sync with the Exceptions action on the Purchase Order page extension.
            CalcFormula = count("PRX Purch. Exception" where("Document Type" = field("Document Type"),
                                                            "Document No." = field("No."),
                                                            Status = const(Open)));
            Editable = false;
        }
    }
}
