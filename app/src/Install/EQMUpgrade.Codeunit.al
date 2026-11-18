namespace MiguelCarvalho.EquipmentManagement;

codeunit 50134 "EQM Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
        UpgradeMgt: Codeunit "EQM Upgrade Mgt.";
    begin
        ChangeLogRegistration.RegisterChangeLogSetupOnce();
        UpgradeMgt.UpgradePerCompany();
    end;
}
