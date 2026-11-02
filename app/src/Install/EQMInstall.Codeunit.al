namespace MiguelCarvalho.EquipmentManagement;

codeunit 50104 "EQM Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        DefaultData: Codeunit "EQM Default Data";
    begin
        DefaultData.CreateDefaultData();
    end;
}
