namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50195 "EQM Equipment Register Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Counter: Integer;
        EquipmentNoTok: Label 'RGEQ%1X', Locked = true;
        CategoryCodeTok: Label 'RGCAT%1', Locked = true;
        CategoryDescriptionTok: Label 'Register category %1', Locked = true;
        EmployeeNoTok: Label 'RGEMP%1', Locked = true;
        FirstNameTok: Label 'Rgfirst%1', Locked = true;
        LastNameTok: Label 'Rglast%1', Locked = true;
        MissingEmployeeNoTok: Label 'RGNOEMP%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        ListedErr: Label 'Equipment %1 should be listed in the register.', Locked = true, Comment = '%1 = equipment number';
        NotListedErr: Label 'Equipment %1 should not be listed in the register.', Locked = true, Comment = '%1 = equipment number';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisterListsCategoryDescriptionAndEmployeeName()
    var
        Equipment: Record "EQM Equipment";
        Employee1: Record Employee;
        Employee2: Record Employee;
        CategoryCode1: Code[20];
        CategoryCode2: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        EquipmentNo3: Code[20];
        Output: Text;
    begin
        // [SCENARIO 1] The register lists equipment with category description and employee name
        // [GIVEN] Categories C1 and C2, employees EMP1 and EMP2, E1 in C1 assigned to EMP1, E2 in C2 assigned to EMP2, E3 in C1 available
        CategoryCode1 := CreateCategory();
        CategoryCode2 := CreateCategory();
        CreateEmployee(Employee1);
        CreateEmployee(Employee2);
        EquipmentNo1 := CreateEquipment(CategoryCode1);
        EquipmentNo2 := CreateEquipment(CategoryCode2);
        EquipmentNo3 := CreateEquipment(CategoryCode1);
        SetStatus(EquipmentNo1, Equipment.Status::Assigned, Employee1."No.");
        SetStatus(EquipmentNo2, Equipment.Status::Assigned, Employee2."No.");

        // [WHEN] The register runs with category filter C1|C2
        Equipment.SetFilter("Category Code", '%1|%2', CategoryCode1, CategoryCode2);
        Output := RunRegister(Equipment);

        // [THEN] E1, E2 and E3 are listed, with both category descriptions and both employee names
        AssertListed(Output, EquipmentNo1);
        AssertListed(Output, EquipmentNo2);
        AssertListed(Output, EquipmentNo3);
        Assert.IsTrue(Output.Contains(StrSubstNo(CategoryDescriptionTok, CategoryCode1)), 'The description of the first category should be in the output');
        Assert.IsTrue(Output.Contains(StrSubstNo(CategoryDescriptionTok, CategoryCode2)), 'The description of the second category should be in the output');
        Assert.IsTrue(Output.Contains(Employee1.FullName()), 'The name of the first employee should be in the output');
        Assert.IsTrue(Output.Contains(Employee2.FullName()), 'The name of the second employee should be in the output');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisterRunsWhenAssignedEmployeeNoLongerExists()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        EquipmentNo: Code[20];
        Output: Text;
    begin
        // [SCENARIO 2] (failure path) An assigned employee that no longer exists does not stop the report
        // [GIVEN] E1 in C1 with status Assigned and an employee number that has no Employee record
        CategoryCode := CreateCategory();
        EquipmentNo := CreateEquipment(CategoryCode);
        SetStatus(EquipmentNo, Equipment.Status::Assigned, StrSubstNo(MissingEmployeeNoTok, NextId()));

        // [WHEN] The register runs with category filter C1
        Equipment.SetRange("Category Code", CategoryCode);
        Output := RunRegister(Equipment);

        // [THEN] There is no error and E1 is listed
        AssertListed(Output, EquipmentNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryFilterListsMatchingCategory()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode1: Code[20];
        CategoryCode2: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        Output: Text;
    begin
        // [SCENARIO 3] Equipment of the filtered category is listed
        // [GIVEN] E1 in C1 and E2 in C2
        CategoryCode1 := CreateCategory();
        CategoryCode2 := CreateCategory();
        EquipmentNo1 := CreateEquipment(CategoryCode1);
        EquipmentNo2 := CreateEquipment(CategoryCode2);

        // [WHEN] The register runs with category filter C1
        Equipment.SetRange("Category Code", CategoryCode1);
        Output := RunRegister(Equipment);

        // [THEN] E1 is listed
        AssertListed(Output, EquipmentNo1);
        Assert.AreNotEqual('', EquipmentNo2, 'The second equipment should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryFilterExcludesOtherCategories()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode1: Code[20];
        CategoryCode2: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        Output: Text;
    begin
        // [SCENARIO 4] (negative) Equipment of other categories is not listed
        // [GIVEN] E1 in C1 and E2 in C2
        CategoryCode1 := CreateCategory();
        CategoryCode2 := CreateCategory();
        EquipmentNo1 := CreateEquipment(CategoryCode1);
        EquipmentNo2 := CreateEquipment(CategoryCode2);

        // [WHEN] The register runs with category filter C1
        Equipment.SetRange("Category Code", CategoryCode1);
        Output := RunRegister(Equipment);

        // [THEN] E2 is not listed
        AssertNotListed(Output, EquipmentNo2);
        Assert.AreNotEqual('', EquipmentNo1, 'The first equipment should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusFilterListsMatchingStatusIncludingFinalStatus()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        Output: Text;
    begin
        // [SCENARIO 5] Equipment with the filtered status is listed, final statuses included
        // [GIVEN] E1 Available and E2 Disposed, both in C1
        CategoryCode := CreateCategory();
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        SetStatus(EquipmentNo2, Equipment.Status::Disposed, '');

        // [WHEN] The register runs with category filter C1 and status Disposed
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange(Status, Equipment.Status::Disposed);
        Output := RunRegister(Equipment);

        // [THEN] E2 is listed
        AssertListed(Output, EquipmentNo2);
        Assert.AreNotEqual('', EquipmentNo1, 'The first equipment should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusFilterExcludesOtherStatuses()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        Output: Text;
    begin
        // [SCENARIO 6] (negative) Equipment with another status is not listed
        // [GIVEN] E1 Available and E2 Disposed, both in C1
        CategoryCode := CreateCategory();
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        SetStatus(EquipmentNo2, Equipment.Status::Disposed, '');

        // [WHEN] The register runs with category filter C1 and status Disposed
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange(Status, Equipment.Status::Disposed);
        Output := RunRegister(Equipment);

        // [THEN] E1 is not listed
        AssertNotListed(Output, EquipmentNo1);
        Assert.AreNotEqual('', EquipmentNo2, 'The second equipment should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeFilterListsEquipmentOfEmployee()
    var
        Equipment: Record "EQM Equipment";
        Employee1: Record Employee;
        Employee2: Record Employee;
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        EquipmentNo3: Code[20];
        Output: Text;
    begin
        // [SCENARIO 7] Equipment of the filtered employee is listed
        // [GIVEN] In C1: E1 assigned to EMP1, E2 assigned to EMP2, E3 available
        CategoryCode := CreateCategory();
        CreateEmployee(Employee1);
        CreateEmployee(Employee2);
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        EquipmentNo3 := CreateEquipment(CategoryCode);
        SetStatus(EquipmentNo1, Equipment.Status::Assigned, Employee1."No.");
        SetStatus(EquipmentNo2, Equipment.Status::Assigned, Employee2."No.");

        // [WHEN] The register runs with category filter C1 and employee EMP1
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange("Assigned Employee No.", Employee1."No.");
        Output := RunRegister(Equipment);

        // [THEN] E1 is listed
        AssertListed(Output, EquipmentNo1);
        Assert.AreNotEqual('', EquipmentNo3, 'The third equipment should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeFilterExcludesOtherEmployeesAndUnassigned()
    var
        Equipment: Record "EQM Equipment";
        Employee1: Record Employee;
        Employee2: Record Employee;
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        EquipmentNo3: Code[20];
        Output: Text;
    begin
        // [SCENARIO 8] (negative) Equipment of other employees and unassigned equipment is not listed
        // [GIVEN] In C1: E1 assigned to EMP1, E2 assigned to EMP2, E3 available
        CategoryCode := CreateCategory();
        CreateEmployee(Employee1);
        CreateEmployee(Employee2);
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        EquipmentNo3 := CreateEquipment(CategoryCode);
        SetStatus(EquipmentNo1, Equipment.Status::Assigned, Employee1."No.");
        SetStatus(EquipmentNo2, Equipment.Status::Assigned, Employee2."No.");

        // [WHEN] The register runs with category filter C1 and employee EMP1
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange("Assigned Employee No.", Employee1."No.");
        Output := RunRegister(Equipment);

        // [THEN] E2 and E3 are not listed
        AssertNotListed(Output, EquipmentNo2);
        AssertNotListed(Output, EquipmentNo3);
        Assert.AreNotEqual('', EquipmentNo1, 'The first equipment should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PurchaseDateFilterIncludesBothBoundaries()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        FromDate: Date;
        Days: Integer;
        Output: Text;
    begin
        // [SCENARIO 9] Equipment purchased on the first and on the last day of the filter is listed
        // [GIVEN] In C1: E1 with purchase date R and E2 with purchase date R + N
        FromDate := Today() - Random(365);
        Days := Random(10);
        CategoryCode := CreateCategory();
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        SetPurchaseDate(EquipmentNo1, FromDate);
        SetPurchaseDate(EquipmentNo2, FromDate + Days);

        // [WHEN] The register runs with category filter C1 and purchase date R..R+N
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange("Purchase Date", FromDate, FromDate + Days);
        Output := RunRegister(Equipment);

        // [THEN] E1 and E2 are listed
        AssertListed(Output, EquipmentNo1);
        AssertListed(Output, EquipmentNo2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PurchaseDateFilterExcludesOutsideAndBlankDates()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        EquipmentNo3: Code[20];
        FromDate: Date;
        Days: Integer;
        Output: Text;
    begin
        // [SCENARIO 10] (negative) Equipment purchased outside the filter, or without a purchase date, is not listed
        // [GIVEN] In C1: E3 with purchase date R - 1, E4 with R + N + 1 and E5 without purchase date
        FromDate := Today() - Random(365);
        Days := Random(10);
        CategoryCode := CreateCategory();
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        EquipmentNo3 := CreateEquipment(CategoryCode);
        SetPurchaseDate(EquipmentNo1, FromDate - 1);
        SetPurchaseDate(EquipmentNo2, FromDate + Days + 1);
        SetPurchaseDate(EquipmentNo3, 0D);

        // [WHEN] The register runs with category filter C1 and purchase date R..R+N
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange("Purchase Date", FromDate, FromDate + Days);
        Output := RunRegister(Equipment);

        // [THEN] E3, E4 and E5 are not listed
        AssertNotListed(Output, EquipmentNo1);
        AssertNotListed(Output, EquipmentNo2);
        AssertNotListed(Output, EquipmentNo3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllFiltersMustMatch()
    var
        Equipment: Record "EQM Equipment";
        Employee1: Record Employee;
        Employee2: Record Employee;
        CategoryCode: Code[20];
        EquipmentNo1: Code[20];
        EquipmentNo2: Code[20];
        PurchaseDate: Date;
        Output: Text;
    begin
        // [SCENARIO 11] (negative) Equipment is listed only when all filters match
        // [GIVEN] In C1: E1 assigned to EMP1 with purchase date R, and E2 assigned to EMP2 with purchase date R
        PurchaseDate := Today() - Random(365);
        CategoryCode := CreateCategory();
        CreateEmployee(Employee1);
        CreateEmployee(Employee2);
        EquipmentNo1 := CreateEquipment(CategoryCode);
        EquipmentNo2 := CreateEquipment(CategoryCode);
        SetStatus(EquipmentNo1, Equipment.Status::Assigned, Employee1."No.");
        SetStatus(EquipmentNo2, Equipment.Status::Assigned, Employee2."No.");
        SetPurchaseDate(EquipmentNo1, PurchaseDate);
        SetPurchaseDate(EquipmentNo2, PurchaseDate);

        // [WHEN] The register runs with category C1, status Assigned, employee EMP1 and purchase date R
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange(Status, Equipment.Status::Assigned);
        Equipment.SetRange("Assigned Employee No.", Employee1."No.");
        Equipment.SetRange("Purchase Date", PurchaseDate);
        Output := RunRegister(Equipment);

        // [THEN] E1 is listed and E2 is not
        AssertListed(Output, EquipmentNo1);
        AssertNotListed(Output, EquipmentNo2);
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateCategory(): Code[20]
    var
        EquipmentCategory: Record "EQM Equipment Category";
        Id: Text;
    begin
        Id := NextId();
        EquipmentCategory.Init();
        EquipmentCategory.Code := CopyStr(StrSubstNo(CategoryCodeTok, Id), 1, MaxStrLen(EquipmentCategory.Code));
        EquipmentCategory.Description := CopyStr(StrSubstNo(CategoryDescriptionTok, EquipmentCategory.Code), 1, MaxStrLen(EquipmentCategory.Description));
        EquipmentCategory.Active := true;
        EquipmentCategory.Insert(false);
        exit(EquipmentCategory.Code);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        Id: Text;
    begin
        Id := NextId();
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, Id), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := CopyStr(StrSubstNo(FirstNameTok, Id), 1, MaxStrLen(Employee."First Name"));
        Employee."Last Name" := CopyStr(StrSubstNo(LastNameTok, Id), 1, MaxStrLen(Employee."Last Name"));
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure CreateEquipment(CategoryCode: Code[20]): Code[20]
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := 'Register test equipment';
        Equipment."Category Code" := CategoryCode;
        Equipment.Insert(true);
        exit(Equipment."No.");
    end;

    local procedure SetStatus(EquipmentNo: Code[20]; NewStatus: Enum "EQM Equipment Status"; EmployeeNo: Code[20])
    var
        Equipment: Record "EQM Equipment";
    begin
        // Set the fields directly, without validation, to avoid dependency on the assignment flow
        Equipment.Get(EquipmentNo);
        Equipment.Status := NewStatus;
        Equipment."Assigned Employee No." := EmployeeNo;
        Equipment.Modify(false);
    end;

    local procedure SetPurchaseDate(EquipmentNo: Code[20]; PurchaseDate: Date)
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.Get(EquipmentNo);
        Equipment."Purchase Date" := PurchaseDate;
        Equipment.Modify(false);
    end;

    local procedure RunRegister(var Equipment: Record "EQM Equipment"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: TextBuilder;
    begin
        RecRef.GetTable(Equipment);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Report.SaveAs(Report::"EQM Equipment Register", '', ReportFormat::Xml, OutStr, RecRef);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result.AppendLine(Line);
        end;
        exit(Result.ToText());
    end;

    local procedure AssertListed(Output: Text; EquipmentNo: Code[20])
    begin
        Assert.IsTrue(Output.Contains(EquipmentNo), StrSubstNo(ListedErr, EquipmentNo));
    end;

    local procedure AssertNotListed(Output: Text; EquipmentNo: Code[20])
    begin
        Assert.IsFalse(Output.Contains(EquipmentNo), StrSubstNo(NotListedErr, EquipmentNo));
    end;
}
