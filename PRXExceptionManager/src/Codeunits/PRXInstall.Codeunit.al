codeunit 50103 "PRX Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        PRXExceptionMgt: Codeunit "PRX Exception Mgt.";
    begin
        PRXExceptionMgt.EnsureSetup();
    end;
}
