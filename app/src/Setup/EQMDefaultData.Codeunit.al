namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;

// Permission design: every read or write of the setup, the categories and the number series for the
// default data happens in this codeunit. The Permissions property grants INDIRECT permissions only:
// it works only with matching rights in the user's permission sets. Only EQM - Administrator has them
// (direct RIMD on the setup and the categories, indirect ri on No. Series and No. Series Line).
// The setup page calls this codeunit only for users with write permission on the setup. The install
// codeunit runs it as the installing user.
// This behavior still needs a sandbox check.
codeunit 50105 "EQM Default Data"
{
    Access = Internal;
    Permissions = tabledata "EQM Equipment Setup" = rim,
                  tabledata "EQM Equipment Category" = ri,
                  tabledata "No. Series" = ri,
                  tabledata "No. Series Line" = ri;

    var
        EquipmentSeriesCodeTok: Label 'EQUIP', Locked = true;
        EquipmentSeriesStartTok: Label 'EQ00001', Locked = true;
        EquipmentSeriesDescriptionTxt: Label 'Equipment', MaxLength = 100;
        MaintenanceSeriesCodeTok: Label 'EQMAINT', Locked = true;
        MaintenanceSeriesStartTok: Label 'MNT00001', Locked = true;
        MaintenanceSeriesDescriptionTxt: Label 'Equipment Maintenance', MaxLength = 100;
        LaptopCodeTok: Label 'LAPTOP', Locked = true;
        MonitorCodeTok: Label 'MONITOR', Locked = true;
        PhoneCodeTok: Label 'PHONE', Locked = true;
        TabletCodeTok: Label 'TABLET', Locked = true;
        PrinterCodeTok: Label 'PRINTER', Locked = true;
        VehicleCodeTok: Label 'VEHICLE', Locked = true;
        ToolCodeTok: Label 'TOOL', Locked = true;
        LaptopDescriptionTxt: Label 'Laptop', MaxLength = 100;
        MonitorDescriptionTxt: Label 'Monitor', MaxLength = 100;
        PhoneDescriptionTxt: Label 'Mobile Phone', MaxLength = 100;
        TabletDescriptionTxt: Label 'Tablet', MaxLength = 100;
        PrinterDescriptionTxt: Label 'Printer', MaxLength = 100;
        VehicleDescriptionTxt: Label 'Vehicle', MaxLength = 100;
        ToolDescriptionTxt: Label 'Tool', MaxLength = 100;

    /// <summary>
    /// Creates the equipment setup record if it does not exist.
    /// </summary>
    /// <returns>True if the setup record was created by this call; false if it already existed.</returns>
    procedure EnsureSetupExists(): Boolean
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        if EquipmentSetup.Get() then
            exit(false);

        EquipmentSetup.Init();
        EquipmentSetup.Insert();
        exit(true);
    end;

    /// <summary>
    /// Creates the setup record, number series EQUIP (if the setup has no Equipment Nos.), number series EQMAINT
    /// (if the setup has no Maintenance Nos.) and the starter categories LAPTOP, MONITOR, PHONE, TABLET, PRINTER, VEHICLE and TOOL. Safe to run repeatedly: existing records are never changed.
    /// </summary>
    procedure CreateDefaultData()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        SetupChanged: Boolean;
    begin
        EnsureSetupExists();
        EquipmentSetup.Get();
        if EquipmentSetup."Equipment Nos." = '' then begin
            EnsureNoSeries(EquipmentSeriesCodeTok, EquipmentSeriesStartTok, EquipmentSeriesDescriptionTxt);
            EquipmentSetup."Equipment Nos." := CopyStr(EquipmentSeriesCodeTok, 1, MaxStrLen(EquipmentSetup."Equipment Nos."));
            SetupChanged := true;
        end;
        if EquipmentSetup."Maintenance Nos." = '' then begin
            EnsureNoSeries(MaintenanceSeriesCodeTok, MaintenanceSeriesStartTok, MaintenanceSeriesDescriptionTxt);
            EquipmentSetup."Maintenance Nos." := CopyStr(MaintenanceSeriesCodeTok, 1, MaxStrLen(EquipmentSetup."Maintenance Nos."));
            SetupChanged := true;
        end;
        if SetupChanged then
            EquipmentSetup.Modify();

        InsertCategoryIfMissing(LaptopCodeTok, LaptopDescriptionTxt);
        InsertCategoryIfMissing(MonitorCodeTok, MonitorDescriptionTxt);
        InsertCategoryIfMissing(PhoneCodeTok, PhoneDescriptionTxt);
        InsertCategoryIfMissing(TabletCodeTok, TabletDescriptionTxt);
        InsertCategoryIfMissing(PrinterCodeTok, PrinterDescriptionTxt);
        InsertCategoryIfMissing(VehicleCodeTok, VehicleDescriptionTxt);
        InsertCategoryIfMissing(ToolCodeTok, ToolDescriptionTxt);
    end;

    local procedure EnsureNoSeries(SeriesCodeTxt: Text; StartingNoTxt: Text; SeriesDescription: Text)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SeriesCode: Code[20];
        StartingNo: Code[20];
    begin
        SeriesCode := CopyStr(SeriesCodeTxt, 1, MaxStrLen(SeriesCode));
        StartingNo := CopyStr(StartingNoTxt, 1, MaxStrLen(StartingNo));
        if not NoSeries.Get(SeriesCode) then begin
            NoSeries.Init();
            NoSeries.Code := SeriesCode;
            NoSeries.Description := CopyStr(SeriesDescription, 1, MaxStrLen(NoSeries.Description));
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert();
        end;

        NoSeriesLine.SetRange("Series Code", SeriesCode);
        if NoSeriesLine.IsEmpty() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := SeriesCode;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine.Validate("Starting No.", StartingNo);
            NoSeriesLine.Validate("Increment-by No.", 1);
            NoSeriesLine.Insert(true);
        end;
    end;

    local procedure InsertCategoryIfMissing(CategoryCode: Text; CategoryDescription: Text)
    var
        EquipmentCategory: Record "EQM Equipment Category";
        CategoryKey: Code[20];
    begin
        CategoryKey := CopyStr(CategoryCode, 1, MaxStrLen(CategoryKey));
        if EquipmentCategory.Get(CategoryKey) then
            exit;

        EquipmentCategory.Init();
        EquipmentCategory.Code := CategoryKey;
        EquipmentCategory.Description := CopyStr(CategoryDescription, 1, MaxStrLen(EquipmentCategory.Description));
        EquipmentCategory.Insert();
    end;
}
