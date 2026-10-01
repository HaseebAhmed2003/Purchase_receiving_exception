permissionset 50101 "PRX MANAGER"
{
    Caption = 'PRX Purchasing Manager';
    Assignable = true;
    IncludedPermissionSets = "PRX RECEIVING";

    // Indirect modify only: changes go through the PRX Resolve Exception codeunit.
    // Read and Insert come from PRX RECEIVING.
    Permissions =
        tabledata "PRX Purch. Exception" = m,
        codeunit "PRX Resolve Exception" = X,
        page "PRX Resolve Exc. Dialog" = X,
        report "PRX Open Exc. by Vendor" = X;
}
