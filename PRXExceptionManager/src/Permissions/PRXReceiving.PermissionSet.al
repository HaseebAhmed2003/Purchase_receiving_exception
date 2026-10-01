permissionset 50100 "PRX RECEIVING"
{
    Caption = 'PRX Receiving User';
    Assignable = true;

    // Assigned on top of the standard purchasing permission sets.
    Permissions =
        tabledata "PRX Purch. Exception" = RI,
        tabledata "PRX Purch. Exc. Setup" = R,
        table "PRX Purch. Exception" = X,
        table "PRX Purch. Exc. Setup" = X,
        page "PRX Purch. Exception List" = X,
        page "PRX Purch. Exception Card" = X,
        codeunit "PRX Exception Mgt." = X,
        codeunit "PRX Posting Subscriber" = X;
}
