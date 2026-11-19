namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-045 Automated Unit Tests, area Equipment Creation. Covers the creation rules of table 50100 that the existing
/// tests do not reach: a blank number without a number series, the warranty dates and the last maintenance date on
/// insert, and the next maintenance date calculated on insert.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50150 "EQM Equipment Creation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Counter: Integer;
        EquipmentNoTok: Label 'EQMCRT%1X', Locked = true;
        CategoryCodeTok: Label 'EQMCRTC%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        MonthsDateFormulaTok: Label '<%1M>', Locked = true;
        WarrantyEndDateFragmentTxt: Label 'must be later than the warranty start date', Locked = true;
        LastMaintenanceFutureFragmentTxt: Label 'is in the future', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithoutNumberAndWithoutSeriesIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO C1] (negative) New equipment without a number is rejected when the setup has no equipment number series
        // [GIVEN] The equipment setup has no Equipment Nos., and new equipment E has a blank number
        EquipmentSetup.Get();
        EquipmentSetup."Equipment Nos." := '';
        EquipmentSetup.Modify(false);
        InitEquipment(Equipment, '');

        // [WHEN] E is inserted with triggers
        asserterror Equipment.Insert(true);

        // [THEN] The error names the Equipment Nos. field
        Assert.ExpectedError(EquipmentSetup.FieldCaption("Equipment Nos."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithWarrantyEndNotAfterStartIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO C2] (negative) New equipment whose warranty end date is not after the start date is rejected on insert
        // [GIVEN] New equipment E whose warranty end date is before its warranty start date, set directly (no field validation)
        InitEquipment(Equipment, CreateEquipmentNo());
        Equipment."Warranty Start Date" := Today() + Random(365);
        Equipment."Warranty End Date" := Equipment."Warranty Start Date" - Random(30);

        // [WHEN] E is inserted with triggers
        asserterror Equipment.Insert(true);

        // [THEN] The warranty date error is raised
        Assert.ExpectedError(WarrantyEndDateFragmentTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithFutureLastMaintenanceDateIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO C3] (negative) New equipment with a last maintenance date after today is rejected on insert
        // [GIVEN] New equipment E whose last maintenance date is after today
        InitEquipment(Equipment, CreateEquipmentNo());
        Equipment."Last Maintenance Date" := Today() + 1 + Random(365);

        // [WHEN] E is inserted with triggers
        asserterror Equipment.Insert(true);

        // [THEN] The future date error is raised
        Assert.ExpectedError(LastMaintenanceFutureFragmentTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertCalculatesNextMaintenanceDate()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNo: Code[20];
        Frequency: Integer;
        LastDate: Date;
    begin
        Initialize();
        // [SCENARIO C4] New equipment with a last maintenance date and a frequency gets the next maintenance date on insert
        // [GIVEN] New equipment E with a last maintenance date in the past and a frequency in months
        EquipmentNo := CreateEquipmentNo();
        Frequency := 1 + Random(12);
        LastDate := Today() - Random(365);
        InitEquipment(Equipment, EquipmentNo);
        Equipment."Last Maintenance Date" := LastDate;
        Equipment."Maintenance Frequency (Months)" := Frequency;

        // [WHEN] E is inserted with triggers
        Equipment.Insert(true);

        // [THEN] The stored next maintenance date is the last date plus the frequency in months
        Equipment.Get(EquipmentNo);
        Assert.AreNotEqual(0D, Equipment."Next Maintenance Date", 'The next maintenance date should be calculated');
        Assert.AreEqual(CalcDate(StrSubstNo(MonthsDateFormulaTok, Frequency), LastDate), Equipment."Next Maintenance Date", 'Next maintenance date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithoutFrequencyLeavesNextMaintenanceDateBlank()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNo: Code[20];
    begin
        Initialize();
        // [SCENARIO C5] (negative) New equipment without a maintenance frequency has no next maintenance date
        // [GIVEN] New equipment E with a last maintenance date in the past and no frequency
        EquipmentNo := CreateEquipmentNo();
        InitEquipment(Equipment, EquipmentNo);
        Equipment."Last Maintenance Date" := Today() - Random(365);

        // [WHEN] E is inserted with triggers
        Equipment.Insert(true);

        // [THEN] The stored next maintenance date is blank
        Equipment.Get(EquipmentNo);
        Assert.AreEqual(0D, Equipment."Next Maintenance Date", 'The next maintenance date should stay blank without a frequency');
    end;

    local procedure Initialize()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEquipmentNo(): Code[20]
    var
        Equipment: Record "EQM Equipment";
    begin
        exit(CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No.")));
    end;

    local procedure InitEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CopyStr(StrSubstNo(CategoryCodeTok, NextId()), 1, MaxStrLen(Category.Code));
        Category.Description := Category.Code;
        Category.Active := true;
        Category.Insert(false);

        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := EquipmentNo;
        Equipment."Category Code" := Category.Code;
    end;
}
