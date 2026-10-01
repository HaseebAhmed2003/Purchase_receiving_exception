table 50101 "PRX Purch. Exception"
{
    Caption = 'Purchase Receiving Exception';
    DataClassification = CustomerContent;
    DrillDownPageId = "PRX Purch. Exception List";
    LookupPageId = "PRX Purch. Exception List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the exception number. It is assigned from the number series in Purchase Exception Setup when the exception is saved.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the purchase document. Version 1 supports purchase orders only.';
            DataClassification = CustomerContent;
            InitValue = "Order";
            Editable = false;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            ToolTip = 'Specifies the purchase order the exception belongs to. The vendor and location are copied from this order.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = field("Document Type"));
            // Existence is checked in PRX Exception Mgt. to give a clearer error message.
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
            begin
                PRXExceptionMgt.ValidateDocumentNo(Rec);
            end;
        }
        field(4; "Document Line No."; Integer)
        {
            Caption = 'Purchase Line No.';
            ToolTip = 'Specifies the purchase order line the exception is about, if the problem concerns a specific line. The item, description, unit of measure and location are copied from this line.';
            DataClassification = CustomerContent;
            BlankZero = true;
            TableRelation = "Purchase Line"."Line No." where("Document Type" = field("Document Type"), "Document No." = field("Document No."));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
            begin
                PRXExceptionMgt.ValidateDocumentLineNo(Rec);
            end;
        }
        field(5; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the vendor of the purchase order. It is copied from the order and cannot be typed.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
            ValidateTableRelation = false;
            Editable = false;
        }
        field(6; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            ToolTip = 'Specifies the vendor name as it was on the purchase order when the exception was recorded.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item on the selected purchase line. It is copied from the line and cannot be typed.';
            DataClassification = CustomerContent;
            TableRelation = Item;
            ValidateTableRelation = false;
            Editable = false;
        }
        field(8; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            ToolTip = 'Specifies the description of the selected purchase line as it was when the exception was recorded.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location from the purchase line, or from the order header when no line is selected.';
            DataClassification = CustomerContent;
            TableRelation = Location;
            ValidateTableRelation = false;
            Editable = false;
        }
        field(10; "Delivery Reference"; Text[35])
        {
            Caption = 'Supplier Delivery Reference';
            ToolTip = 'Specifies the supplier''s delivery note or shipment reference for the delivery this problem was found in. Each exception keeps its own reference, so one order can have exceptions from different deliveries.';
            DataClassification = CustomerContent;
        }
        field(11; "Reported Date"; Date)
        {
            Caption = 'Reported Date';
            ToolTip = 'Specifies the business date on which the problem was reported. It defaults to the work date.';
            DataClassification = CustomerContent;
        }
        field(12; Reason; Enum "PRX Exception Reason")
        {
            Caption = 'Reason';
            ToolTip = 'Specifies the category of the problem.';
            DataClassification = CustomerContent;
        }
        field(13; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what was observed, for example what the paperwork said and what actually arrived.';
            DataClassification = CustomerContent;
        }
        field(14; "Affected Quantity"; Decimal)
        {
            Caption = 'Affected Quantity';
            ToolTip = 'Specifies how many units the problem concerns, in the unit of measure of the purchase line. Leave it blank if the problem is not about a quantity. It is not compared with the received quantity, because for missing units it can be larger than what was received.';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            BlankZero = true;

            trigger OnValidate()
            var
                PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
            begin
                PRXExceptionMgt.CheckAffectedQuantity(Rec);
            end;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure of the affected quantity. It is copied from the purchase line.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "Requires Invoice Review"; Boolean)
        {
            Caption = 'Requires Invoice Review';
            ToolTip = 'Specifies whether invoice posting from this purchase order is blocked while this exception is open.';
            DataClassification = CustomerContent;
        }
        field(17; Status; Enum "PRX Exception Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the exception is Open or Resolved. Only the Resolve action can change it.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; "Created By"; Code[50])
        {
            Caption = 'Created By';
            ToolTip = 'Specifies the user who recorded the exception.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(19; "Created At"; DateTime)
        {
            Caption = 'Created At';
            ToolTip = 'Specifies when the exception was recorded.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Resolved By"; Code[50])
        {
            Caption = 'Resolved By';
            ToolTip = 'Specifies the user who resolved the exception.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(21; "Resolved At"; DateTime)
        {
            Caption = 'Resolved At';
            ToolTip = 'Specifies when the exception was resolved.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; "Resolution Notes"; Text[250])
        {
            Caption = 'Resolution Notes';
            ToolTip = 'Specifies how the problem was investigated and addressed. Resolving does not change received quantities, create credit memos or correct invoices; those are done with standard documents.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        // FlowField on Purchase Header and posting check
        key(Document; "Document Type", "Document No.", Status, "Requires Invoice Review")
        {
        }
        // Report and vendor/date filtering
        key(Vendor; "Vendor No.", "Reported Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Document No.", "Vendor Name", Reason, Status)
        {
        }
    }

    trigger OnInsert()
    var
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
    begin
        // All validation is in the management codeunit so every caller gets the same checks.
        PRXExceptionMgt.PrepareForInsert(Rec);
    end;

    trigger OnModify()
    var
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
    begin
        PRXExceptionMgt.CheckNotResolved(Rec);
    end;

    trigger OnDelete()
    var
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
    begin
        PRXExceptionMgt.CheckNotResolved(Rec);
    end;

    trigger OnRename()
    var
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
    begin
        PRXExceptionMgt.ThrowRenameNotAllowed();
    end;
}
