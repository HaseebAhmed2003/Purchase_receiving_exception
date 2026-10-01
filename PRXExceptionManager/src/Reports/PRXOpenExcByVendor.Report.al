report 50100 "PRX Open Exc. by Vendor"
{
    Caption = 'Open Purchasing Exceptions by Vendor';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = OpenExceptionsRdlc;

    dataset
    {
        // Vendor name comes from the snapshot on the exception; grouping and totals are in the layout.
        dataitem(PRXPurchException; "PRX Purch. Exception")
        {
            DataItemTableView = sorting("Vendor No.", "Reported Date") where(Status = const(Open));
            RequestFilterFields = "Vendor No.", "Reported Date";

            column(CompanyName; CompanyProperty.DisplayName())
            {
            }
            column(FilterText; FilterText)
            {
            }
            column(VendorNo; "Vendor No.")
            {
            }
            column(VendorName; "Vendor Name")
            {
            }
            column(ExceptionNo; "No.")
            {
            }
            column(DocumentNo; "Document No.")
            {
            }
            column(ReasonText; Format(Reason))
            {
            }
            column(Description; Description)
            {
            }
            column(ReportedDateText; Format("Reported Date"))
            {
            }
            column(RequiresReviewText; Format("Requires Invoice Review"))
            {
            }
        }
    }

    rendering
    {
        layout(OpenExceptionsRdlc)
        {
            Type = RDLC;
            LayoutFile = './src/Layouts/PRXOpenExcByVendor.rdl';
            Caption = 'Open exceptions by vendor';
            Summary = 'Open exceptions grouped by vendor with a count per vendor.';
        }
    }

    labels
    {
        ReportTitleLbl = 'Open Purchasing Exceptions by Vendor';
        ExceptionNoLbl = 'Exception No.';
        OrderNoLbl = 'Purchase Order';
        ReasonLbl = 'Reason';
        DescriptionLbl = 'Description';
        ReportedDateLbl = 'Reported Date';
        InvoiceReviewLbl = 'Invoice Review';
        VendorLbl = 'Vendor';
        VendorTotalLbl = 'Open exceptions for this vendor';
        GrandTotalLbl = 'Open exceptions in total';
        FiltersLbl = 'Filters';
        // Plain count of open exceptions, not a vendor quality measure.
        CountNoteLbl = 'Counts are open exceptions only. They are not a measure of vendor quality, because they do not account for how many deliveries each vendor made.';
    }

    var
        FilterText: Text;

    trigger OnPreReport()
    begin
        FilterText := PRXPurchException.GetFilters();
    end;
}
