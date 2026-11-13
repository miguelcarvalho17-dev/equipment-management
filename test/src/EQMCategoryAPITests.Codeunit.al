namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the read-only categories API page 50124 (FR-027). The page has no logic of its own: it exposes
/// table 50101 "EQM Equipment Category" (id = SystemId, code, description, active, lastModifiedDateTime = SystemModifiedAt).
/// These tests run the table-level equivalents of the requests: the filter active eq true, categories({id}) and the
/// stability of the id. Real HTTP calls cannot be authenticated in the CI container (see FR-026), so
/// scenarios 4 to 8 (GET list and by id, 404, rejected writes, equipment categoryCode lookup, permissions)
/// are verified manually in the sandbox.
/// </summary>
codeunit 50181 "EQM Category API Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ActiveCategoryTok: Label 'EQMCAT-A', Locked = true;
        InactiveCategoryTok: Label 'EQMCAT-I', Locked = true;
        ActiveDescriptionTok: Label 'Laptops', Locked = true;
        UpdatedDescriptionTok: Label 'EQMCAT updated description', Locked = true;
        UnknownIdTok: Label '{00000000-0000-0000-0000-000000000001}', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ActiveFilterReturnsOnlyActiveCategories()
    var
        Category: Record "EQM Equipment Category";
    begin
        // [SCENARIO 1] The filter active eq true returns EQMCAT-A and not EQMCAT-I; without the filter both are returned
        Initialize();

        // [GIVEN] Active category EQMCAT-A and inactive category EQMCAT-I (Initialize)

        // [WHEN] The categories are read with Active = true (the $filter=active eq true equivalent)
        Category.SetRange(Active, true);

        // [THEN] EQMCAT-A is included and EQMCAT-I is not
        Category.SetRange(Code, ActiveCategoryTok);
        Assert.RecordCount(Category, 1);
        Category.SetRange(Code, InactiveCategoryTok);
        Assert.RecordIsEmpty(Category);

        // [WHEN] The categories are read without the Active filter
        Category.Reset();

        // [THEN] Both are included
        Category.SetFilter(Code, '%1|%2', ActiveCategoryTok, InactiveCategoryTok);
        Assert.RecordCount(Category, 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InactiveFilterReturnsOnlyInactiveCategories()
    var
        Category: Record "EQM Equipment Category";
    begin
        // [SCENARIO 1b] (boundary) The filter active eq false returns EQMCAT-I and not EQMCAT-A
        Initialize();

        // [GIVEN] Active category EQMCAT-A and inactive category EQMCAT-I (Initialize)

        // [WHEN] The categories are read with Active = false
        Category.SetRange(Active, false);

        // [THEN] EQMCAT-I is included and EQMCAT-A is not
        Category.SetRange(Code, InactiveCategoryTok);
        Assert.RecordCount(Category, 1);
        Category.SetRange(Code, ActiveCategoryTok);
        Assert.RecordIsEmpty(Category);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryIsFoundBySystemId()
    var
        Category: Record "EQM Equipment Category";
        ById: Record "EQM Equipment Category";
    begin
        // [SCENARIO 2] categories({id}) equivalent: the category is read by its SystemId and the fields match
        Initialize();

        // [GIVEN] Category EQMCAT-A
        Category.Get(ActiveCategoryTok);

        // [WHEN] It is read by its SystemId
        Assert.IsTrue(ById.GetBySystemId(Category.SystemId), 'The category should be found by its SystemId');

        // [THEN] Code, Description and Active match
        Assert.AreEqual(ActiveCategoryTok, ById.Code, 'Code should match');
        Assert.AreEqual(ActiveDescriptionTok, ById.Description, 'Description should match');
        Assert.IsTrue(ById.Active, 'Active should match');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InactiveCategoryIsFoundBySystemId()
    var
        Category: Record "EQM Equipment Category";
        ById: Record "EQM Equipment Category";
    begin
        // [SCENARIO 2b] (boundary) An inactive category is also found by its SystemId, with Active = false
        Initialize();

        // [GIVEN] Inactive category EQMCAT-I
        Category.Get(InactiveCategoryTok);

        // [WHEN] It is read by its SystemId
        Assert.IsTrue(ById.GetBySystemId(Category.SystemId), 'The inactive category should be found by its SystemId');

        // [THEN] Code matches and Active is false
        Assert.AreEqual(InactiveCategoryTok, ById.Code, 'Code should match');
        Assert.IsFalse(ById.Active, 'Active should be false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownSystemIdIsNotFound()
    var
        Category: Record "EQM Equipment Category";
        UnknownId: Guid;
    begin
        // [SCENARIO 2c] (negative) An unknown id finds nothing (the 404 case of categories({id}))
        Initialize();

        // [GIVEN] A GUID that belongs to no category
        Evaluate(UnknownId, UnknownIdTok);

        // [WHEN] It is read by that SystemId
        // [THEN] No category is found
        Assert.IsFalse(Category.GetBySystemId(UnknownId), 'An unknown SystemId should not be found');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemIdIsStableWhenDescriptionChanges()
    var
        Category: Record "EQM Equipment Category";
        IdBefore: Guid;
    begin
        // [SCENARIO 3] Modifying the description keeps the SystemId, and SystemModifiedAt is filled
        Initialize();

        // [GIVEN] Category EQMCAT-A and its SystemId
        Category.Get(ActiveCategoryTok);
        IdBefore := Category.SystemId;

        // [WHEN] The description is modified
        Category.Validate(Description, UpdatedDescriptionTok);
        Category.Modify(true);

        // [THEN] The SystemId is unchanged, the description is stored and SystemModifiedAt is filled
        Category.Get(ActiveCategoryTok);
        Assert.AreEqual(IdBefore, Category.SystemId, 'The SystemId should not change');
        Assert.AreEqual(UpdatedDescriptionTok, Category.Description, 'The description should be saved');
        Assert.AreNotEqual(0DT, Category.SystemModifiedAt, 'SystemModifiedAt should be filled');
    end;

    local procedure Initialize()
    var
        Category: Record "EQM Equipment Category";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        Category.Init();
        Category.Code := ActiveCategoryTok;
        Category.Description := ActiveDescriptionTok;
        Category.Active := true;
        Category.Insert(true);

        Category.Init();
        Category.Code := InactiveCategoryTok;
        Category.Active := false;
        Category.Insert(true);
    end;
}
