table 50100 "PRX Purch. Exc. Setup"
{
    Caption = 'Purchase Exception Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "PRX Purch. Exc. Setup";
    LookupPageId = "PRX Purch. Exc. Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
            AllowInCustomizations = Never;
        }
        field(2; "Exception Nos."; Code[20])
        {
            Caption = 'Exception Nos.';
            ToolTip = 'Specifies the number series used to number new purchase receiving exceptions.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
