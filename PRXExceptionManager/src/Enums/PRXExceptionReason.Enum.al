enum 50100 "PRX Exception Reason"
{
    Extensible = true;
    Caption = 'Exception Reason';

    value(0; " ") { Caption = ' '; }
    value(1; "Quantity Discrepancy") { Caption = 'Quantity Discrepancy'; }
    value(2; "Damaged Goods") { Caption = 'Damaged Goods'; }
    value(3; "Wrong Item") { Caption = 'Wrong Item'; }
    value(4; Other) { Caption = 'Other'; }
}
