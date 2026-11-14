namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Smoke tests for the production subscribers of codeunit 50131 (FR-031). The platform raises an external business
/// event itself and does not call AL subscribers in the test runner (CI run of PR #122: a manual subscriber on the
/// event saw 0 raises), so the payload and the raise count cannot be asserted here. These tests only prove that the
/// operations that fire the subscribers complete without an error. The payload, and that the event is raised once,
/// are sandbox checks (scenarios 1 and 4 of the plan).
/// </summary>
codeunit 50187 "EQM Power Automate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'EQMPAE-CAT', Locked = true;
        EmployeeTok: Label 'EQMPAE-E1', Locked = true;
        EquipmentNoTok: Label 'EQMPAE-EQ', Locked = true;
        WarrantyNoTok: Label 'EQMPAE-W%1', Locked = true;
        DescriptionTok: Label 'EQMPAE test equipment', Locked = true;
        ProviderTok: Label 'EQMPAE Provider', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignRunsSubscriberWithoutError()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 1] (smoke) Assigning equipment runs the EquipmentAssigned subscriber without an error
        Initialize();

        // [GIVEN] Available equipment EQ
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] EQ is assigned to E1
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] The assignment is done
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'EQ should be assigned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GenerateAlertsRunsSubscriberWithoutError()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        ReferenceDate: Date;
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // [SCENARIO 4] (smoke) Creating a warranty alert runs the WarrantyExpiring subscriber without an error
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] Equipment W with warranty end R+20
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate + 20);

        // [WHEN] The alerts are generated for R
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);

        // [THEN] One alert is created
        Assert.AreEqual(1, CreatedCount, 'One alert should be created');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AlertInsertWithoutRaiseDoesNotFail()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        TempWarrantyAlert: Record "EQM Warranty Alert" temporary;
        ReferenceDate: Date;
    begin
        // [SCENARIO 6] (smoke) A temporary alert and an Insert(false) pass the subscriber guards without an error
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] Equipment W with warranty end R+20
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate + 20);

        // [WHEN] An alert for W is inserted as a temporary record, and another with Insert(false)
        InitAlert(TempWarrantyAlert, Equipment, ReferenceDate);
        TempWarrantyAlert.Insert(true);
        InitAlert(WarrantyAlert, Equipment, ReferenceDate);
        WarrantyAlert.Insert(false);

        // [THEN] Both records are inserted
        Assert.IsTrue(WarrantyAlert.Get(WarrantyAlert."Entry No."), 'The stored alert should exist');
        Assert.AreEqual(1, TempWarrantyAlert.Count(), 'The temporary alert should exist');
    end;

    local procedure Initialize()
    var
        Category: Record "EQM Equipment Category";
        Employee: Record Employee;
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        Category.Init();
        Category.Code := CategoryTok;
        Category.Active := true;
        Category.Insert();

        Employee.Init();
        Employee."No." := EmployeeTok;
        Employee."First Name" := 'PAE';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := DescriptionTok;
        Equipment."Category Code" := CategoryTok;
        Equipment."Warranty Provider" := ProviderTok;
        Equipment.Insert(true);
    end;

    local procedure CreateEquipmentWithWarranty(var Equipment: Record "EQM Equipment"; Index: Integer; WarrantyEndDate: Date)
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(WarrantyNoTok, Index), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := DescriptionTok;
        Equipment."Category Code" := CategoryTok;
        Equipment."Warranty Provider" := ProviderTok;
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment.Insert(true);
    end;

    local procedure InitAlert(var WarrantyAlert: Record "EQM Warranty Alert"; Equipment: Record "EQM Equipment"; ReferenceDate: Date)
    begin
        WarrantyAlert.Init();
        WarrantyAlert."Equipment No." := Equipment."No.";
        WarrantyAlert."Alert Interval" := WarrantyAlert."Alert Interval"::"30 Days";
        WarrantyAlert."Warranty End Date" := Equipment."Warranty End Date";
        WarrantyAlert."Alert Date" := ReferenceDate;
        WarrantyAlert.Status := WarrantyAlert.Status::Open;
    end;
}
