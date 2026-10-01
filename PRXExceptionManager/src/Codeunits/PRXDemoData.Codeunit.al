codeunit 50104 "PRX Demo Data"
{
    Access = Internal;

    var
        VendorNoTok: Label 'PRX-RLS', Locked = true;
        VendorNameTok: Label 'Riyadh Leather Supplies', Locked = true;
        ItemNoTok: Label 'PRX-TOTE', Locked = true;
        ItemDescriptionTok: Label 'Handbag - Tan Tote', Locked = true;
        NoSourceVendorErr: Label 'No existing vendor with posting groups was found to copy settings from.';
        NoSourceItemErr: Label 'No existing inventory item with posting groups was found to copy settings from.';
        DemoDataCreatedMsg: Label 'Demo data is ready: vendor %1 (%2) and item %3 (%4).', Comment = '%1 = vendor no., %2 = vendor name, %3 = item no., %4 = item description';

    /// <summary>
    /// Creates the demo vendor and item. Does nothing if they already exist.
    /// </summary>
    procedure CreateDemoData()
    begin
        CreateVendor();
        CreateItem();
        Message(DemoDataCreatedMsg, VendorNoTok, VendorNameTok, ItemNoTok, ItemDescriptionTok);
    end;

    local procedure CreateVendor()
    var
        SourceVendor: Record Vendor;
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNoTok) then
            exit;
        SourceVendor.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        SourceVendor.SetFilter("Vendor Posting Group", '<>%1', '');
        SourceVendor.SetRange(Blocked, SourceVendor.Blocked::" ");
        if not SourceVendor.FindFirst() then
            Error(NoSourceVendorErr);

        Vendor.Init();
        Vendor."No." := VendorNoTok;
        Vendor.Insert(true);
        Vendor.Validate(Name, VendorNameTok);
        Vendor.Validate("Gen. Bus. Posting Group", SourceVendor."Gen. Bus. Posting Group");
        Vendor.Validate("Vendor Posting Group", SourceVendor."Vendor Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", SourceVendor."VAT Bus. Posting Group");
        Vendor.Validate("Tax Area Code", SourceVendor."Tax Area Code");
        Vendor.Validate("Tax Liable", SourceVendor."Tax Liable");
        Vendor.Validate("Payment Terms Code", SourceVendor."Payment Terms Code");
        Vendor.Modify(true);
    end;

    local procedure CreateItem()
    var
        SourceItem: Record Item;
        Item: Record Item;
    begin
        if Item.Get(ItemNoTok) then
            exit;
        SourceItem.SetRange(Type, SourceItem.Type::Inventory);
        SourceItem.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        SourceItem.SetFilter("Inventory Posting Group", '<>%1', '');
        SourceItem.SetFilter("Base Unit of Measure", '<>%1', '');
        SourceItem.SetRange(Blocked, false);
        if not SourceItem.FindFirst() then
            Error(NoSourceItemErr);

        Item.Init();
        Item."No." := ItemNoTok;
        Item.Insert(true);
        Item.Validate(Description, ItemDescriptionTok);
        Item.Validate(Type, Item.Type::Inventory);
        Item.Validate("Base Unit of Measure", SourceItem."Base Unit of Measure");
        Item.Validate("Gen. Prod. Posting Group", SourceItem."Gen. Prod. Posting Group");
        Item.Validate("Inventory Posting Group", SourceItem."Inventory Posting Group");
        Item.Validate("VAT Prod. Posting Group", SourceItem."VAT Prod. Posting Group");
        Item.Validate("Tax Group Code", SourceItem."Tax Group Code");
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Unit Cost", 45);
        Item.Validate("Last Direct Cost", 45);
        Item.Validate("Vendor No.", VendorNoTok);
        Item.Modify(true);
    end;
}
