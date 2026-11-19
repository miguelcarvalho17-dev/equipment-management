namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.Attachment;
using MiguelCarvalho.EquipmentManagement;
using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Tests for FR-036 Permission Sets: structural checks of the four assignable roles (Reader, Manager, Administrator
/// and the new API Consumer), scenarios 1 to 9 of the plan. They read the effective permissions from the platform
/// tables "Expanded Permission" (effective rights after inclusion), "Metadata Permission Set" and
/// "Metadata Permission Set Rel." (assignable flag and includes), "Page Metadata" and "AllObjWithCaption" (object lists).
/// Nothing is written, so there is nothing to roll back. Permission enforcement itself (scenarios S1 to S4) is a
/// manual sandbox check.
/// Rights are compared as a 5 character text in the order Read, Insert, Modify, Delete, Execute.
/// Y = Yes (direct), I = Indirect, - = none.
/// </summary>
codeunit 50162 "EQM Role Permission Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ReaderRoleTok: Label 'EQM - READER', Locked = true;
        ManagerRoleTok: Label 'EQM - MANAGER', Locked = true;
        AdministratorRoleTok: Label 'EQM - ADMINISTRATOR', Locked = true;
        ApiConsumerRoleTok: Label 'EQM - API CONSUMER', Locked = true;
        EQMObjectIdFilterTok: Label '50100..50149', Locked = true;
        SetMissingErr: Label 'Permission set %1 should exist.', Comment = '%1 = role ID';
        AssignableErr: Label 'Permission set %1 should be assignable.', Comment = '%1 = role ID';
        IncludeCountErr: Label 'Permission set %1 should have the expected number of included or excluded sets.', Comment = '%1 = role ID';
        IncludeTargetErr: Label 'Permission set %1 should include the expected set.', Comment = '%1 = role ID';
        TableDataRightsErr: Label 'Effective tabledata rights of %1 on table %2 (Read, Insert, Modify, Delete, Execute) should match the matrix.', Comment = '%1 = role ID, %2 = table ID';
        ObjectCountErr: Label 'The number of %1 permission entries (type %2) of %3 in 50100-50149 should match the matrix.', Comment = '%1 = object type name, %2 = object type number, %3 = role ID';
        ExecuteMissingErr: Label '%1 should have Execute on object type %2, ID %3.', Comment = '%1 = role ID, %2 = object type number, %3 = object ID';
        UnexpectedEntryErr: Label '%1 should have no permission entry on object type %2, ID %3.', Comment = '%1 = role ID, %2 = object type number, %3 = object ID';
        UnexpectedRightErr: Label '%1 should have no Insert, Modify or Delete on table %2.', Comment = '%1 = role ID, %2 = table ID';
        NoDeleteErr: Label '%1 should have no Delete on table %2.', Comment = '%1 = role ID, %2 = table ID';
        NothingCheckedErr: Label 'No objects of type %1 were found in 50100-50149, so the check would pass for no reason.', Comment = '%1 = object type number';
        NotAtLeastAdminErr: Label 'Administrator should have equal or stronger rights than API Consumer on object type %1, ID %2 (API Consumer %3, Administrator %4).', Comment = '%1 = object type number, %2 = object ID, %3 = rights of API Consumer, %4 = rights of Administrator';
        ReaderMissingErr: Label 'Reader should have Execute on object type %1, ID %2.', Comment = '%1 = object type number, %2 = object ID';
        ApiConsumerMissingErr: Label 'API Consumer should have Execute on API page %1.', Comment = '%1 = page ID';
        NoneErr: Label 'API Consumer should have no access to non-API page %1.', Comment = '%1 = page ID';

    [Test]
    procedure ApiConsumerIsAssignableAndStandalone()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        MetadataPermissionSetRel: Record "Metadata Permission Set Rel.";
    begin
        // [SCENARIO 1] API Consumer exists, is assignable and includes no other permission set
        // [GIVEN] The installed apps
        // [WHEN] The permission set EQM - API Consumer is read from the metadata
        MetadataPermissionSet.SetRange("Role ID", ApiConsumerRoleTok);

        // [THEN] It exists, is assignable and has no include or exclude relation
        Assert.IsFalse(MetadataPermissionSet.IsEmpty(), StrSubstNo(SetMissingErr, ApiConsumerRoleTok));
        MetadataPermissionSet.FindFirst();
        Assert.IsTrue(MetadataPermissionSet.Assignable, StrSubstNo(AssignableErr, ApiConsumerRoleTok));
        MetadataPermissionSetRel.SetRange("Role ID", ApiConsumerRoleTok);
        Assert.AreEqual(0, MetadataPermissionSetRel.Count(), StrSubstNo(IncludeCountErr, ApiConsumerRoleTok));
    end;

    [Test]
    procedure ExistingRolesKeepTheirHierarchy()
    begin
        // [SCENARIO 1] Reader is standalone, Manager includes Reader, Administrator includes Manager, all assignable
        // [GIVEN] The installed apps
        // [WHEN] The three existing permission sets are read from the metadata
        // [THEN] Each is assignable and has exactly the expected include relation
        AssertAssignableWithInclude(ReaderRoleTok, '');
        AssertAssignableWithInclude(ManagerRoleTok, ReaderRoleTok);
        AssertAssignableWithInclude(AdministratorRoleTok, ManagerRoleTok);
    end;

    [Test]
    procedure ApiConsumerTableDataMatchesMatrix()
    begin
        // [SCENARIO 2] API Consumer effective tabledata equals the matrix column exactly
        // [GIVEN] The matrix of the plan: letters are Read, Insert, Modify, Delete, Execute (Y = Yes, I = Indirect, - = none)
        // [WHEN] The effective permissions of EQM - API Consumer are expanded
        // [THEN] Every table has exactly the rights of the matrix, and no other EQM table has a tabledata entry
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Equipment", 'YYY--');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Equipment Category", 'Y----');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Equipment Setup", 'Y----');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Equipment Assignment", 'YII--');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Maintenance Record", 'Y----');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Integration Event Entry", 'YII--');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Equipment Audit Entry", 'II---');
        AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Feature Setup", 'Y----');
        Assert.AreEqual(8, CountEntries(ApiConsumerRoleTok, 0), StrSubstNo(ObjectCountErr, 'tabledata', 0, ApiConsumerRoleTok));
    end;

    [Test]
    procedure ApiConsumerExecuteMatchesMatrix()
    begin
        // [SCENARIO 2] API Consumer object Execute rights equal the matrix: 8 tables, 4 API pages, 13 codeunits, no query
        // [GIVEN] The object lists of the plan
        // [WHEN] The effective permissions of EQM - API Consumer are expanded
        // [THEN] Each listed object has Execute, and the counts per type match exactly (no more, no fewer)
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Equipment");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Equipment Category");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Equipment Setup");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Equipment Assignment");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Maintenance Record");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Integration Event Entry");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Equipment Audit Entry");
        AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Feature Setup");
        Assert.AreEqual(8, CountEntries(ApiConsumerRoleTok, 1), StrSubstNo(ObjectCountErr, 'table', 1, ApiConsumerRoleTok));

        AssertExecute(ApiConsumerRoleTok, 8, Page::"EQM Equipment API");
        AssertExecute(ApiConsumerRoleTok, 8, Page::"EQM Category API");
        AssertExecute(ApiConsumerRoleTok, 8, Page::"EQM Assignment API");
        AssertExecute(ApiConsumerRoleTok, 8, Page::"EQM Integration Event API");
        Assert.AreEqual(4, CountEntries(ApiConsumerRoleTok, 8), StrSubstNo(ObjectCountErr, 'page', 8, ApiConsumerRoleTok));

        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Assignment Mgt.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Maintenance Mgt.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Business Events");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Business Event Subscr.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Integration Event Subscr.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Integration Event Mgt.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Power Automate Events");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Power Automate Subscr.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Audit Trail Mgt.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Audit Trail Subscr.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Feature Mgt.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Telemetry Mgt.");
        AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Telemetry Subscr.");
        Assert.AreEqual(13, CountEntries(ApiConsumerRoleTok, 5), StrSubstNo(ObjectCountErr, 'codeunit', 5, ApiConsumerRoleTok));

        Assert.AreEqual(0, CountEntries(ApiConsumerRoleTok, 9), StrSubstNo(ObjectCountErr, 'query', 9, ApiConsumerRoleTok));
    end;

    [Test]
    procedure ApiConsumerHasNoAccessToOtherData()
    begin
        // [SCENARIO 3] (negative) API Consumer has no tabledata entry on tables outside the API surface
        // [GIVEN] The tables the API does not expose, plus Document Attachment and Job Queue Entry
        // [WHEN] The effective permissions of EQM - API Consumer are expanded
        // [THEN] There is no tabledata entry at all for these tables
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"EQM Maintenance History Entry");
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"EQM Warranty Alert");
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"EQM Maintenance Log Entry");
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"EQM Equipment Note");
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"EQM Equipment Request");
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"Document Attachment");
        AssertNoEntry(ApiConsumerRoleTok, 0, Database::"Job Queue Entry");
    end;

    [Test]
    procedure ApiConsumerCannotWriteCategorySetupOrMaintenance()
    begin
        // [SCENARIO 3] (negative) API Consumer has no Insert, Modify or Delete on Category, Setup and Maintenance Record
        // [GIVEN] The effective permissions of EQM - API Consumer
        // [WHEN] The rights on tables 50101, 50102 and 50105 are read
        // [THEN] Insert, Modify and Delete are none (direct and indirect)
        AssertNoWriteRights(ApiConsumerRoleTok, Database::"EQM Equipment Category");
        AssertNoWriteRights(ApiConsumerRoleTok, Database::"EQM Equipment Setup");
        AssertNoWriteRights(ApiConsumerRoleTok, Database::"EQM Maintenance Record");
        AssertNoWriteRights(ApiConsumerRoleTok, Database::"EQM Feature Setup");
    end;

    [Test]
    procedure ApiConsumerCannotDeleteEquipmentOrAssignmentsOrEvents()
    begin
        // [SCENARIO 3] (negative, boundary) D2: API Consumer cannot delete on any of its tables
        // [GIVEN] The effective permissions of EQM - API Consumer
        // [WHEN] The rights on its eight tables are read
        // [THEN] Delete is none on each
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Equipment");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Equipment Assignment");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Integration Event Entry");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Equipment Audit Entry");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Equipment Category");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Equipment Setup");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Maintenance Record");
        AssertNoDelete(ApiConsumerRoleTok, Database::"EQM Feature Setup");
    end;

    [Test]
    procedure ApiConsumerHasNoUIPageQueryOrUICodeunit()
    var
        PageMetadata: Record "Page Metadata";
        Checked: Integer;
    begin
        // [SCENARIO 4] (negative) API Consumer has no Execute on any page of the app whose type is not API, and none on any query
        // [GIVEN] All pages in 50100-50149
        PageMetadata.SetFilter(ID, EQMObjectIdFilterTok);
        PageMetadata.SetFilter(PageType, '<>%1', PageMetadata.PageType::API);

        // [WHEN] Each non-API page is looked up in the effective permissions of API Consumer
        if PageMetadata.FindSet() then
            repeat
                Checked += 1;
                Assert.AreEqual('-----', RightsOf(ApiConsumerRoleTok, 8, PageMetadata.ID), StrSubstNo(NoneErr, PageMetadata.ID));
            until PageMetadata.Next() = 0;

        // [THEN] None has any right, there are such pages (so the check is not vacuous), and no query and no UI codeunit is granted
        Assert.IsTrue(Checked > 0, StrSubstNo(NothingCheckedErr, 8));
        Assert.AreEqual(0, CountEntries(ApiConsumerRoleTok, 9), StrSubstNo(ObjectCountErr, 'query', 9, ApiConsumerRoleTok));
        AssertNoEntry(ApiConsumerRoleTok, 5, Codeunit::"EQM Employee Subscribers");
        AssertNoEntry(ApiConsumerRoleTok, 5, Codeunit::"EQM Default Data");
        AssertNoEntry(ApiConsumerRoleTok, 3, Report::"EQM Equipment Register");
        AssertNoEntry(ApiConsumerRoleTok, 3, Report::"EQM Asset Utilization");
        AssertNoEntry(ApiConsumerRoleTok, 3, Report::"EQM Maint. Cost Analysis");
    end;

    [Test]
    procedure EveryApiPageIsInReaderAndApiConsumer()
    var
        PageMetadata: Record "Page Metadata";
        Checked: Integer;
    begin
        // [SCENARIO 5] Every page with PageType API in 50100-50149 has Execute in API Consumer and in Reader
        // [GIVEN] All API pages in 50100-50149 (this includes the IDs 50127-50129 reserved for later features)
        PageMetadata.SetFilter(ID, EQMObjectIdFilterTok);
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);

        // [WHEN] Each is looked up in the effective permissions of both roles
        if PageMetadata.FindSet() then
            repeat
                Checked += 1;

                // [THEN] Both roles have Execute (direct)
                Assert.AreEqual('Y', CopyStr(RightsOf(ApiConsumerRoleTok, 8, PageMetadata.ID), 5, 1), StrSubstNo(ApiConsumerMissingErr, PageMetadata.ID));
                Assert.AreEqual('Y', CopyStr(RightsOf(ReaderRoleTok, 8, PageMetadata.ID), 5, 1), StrSubstNo(ReaderMissingErr, 8, PageMetadata.ID));
            until PageMetadata.Next() = 0;
        Assert.IsTrue(Checked >= 4, StrSubstNo(NothingCheckedErr, 8));
    end;

    [Test]
    procedure AdministratorCoversEverythingApiConsumerCan()
    var
        ApiConsumerPermission: Record "Expanded Permission";
        AdminRights: Text;
        ApiRights: Text;
        Position: Integer;
        Checked: Integer;
    begin
        // [SCENARIO 6] For every API Consumer entry, Administrator's effective right is equal or stronger (Yes > Indirect > none)
        // [GIVEN] All effective permission entries of API Consumer
        ApiConsumerPermission.SetRange("Role ID", ApiConsumerRoleTok);

        // [WHEN] The same object is looked up in the effective permissions of Administrator
        if ApiConsumerPermission.FindSet() then
            repeat
                Checked += 1;
                ApiRights := RightsText(ApiConsumerPermission);
                AdminRights := RightsOf(AdministratorRoleTok, ApiConsumerPermission."Object Type", ApiConsumerPermission."Object ID");

                // [THEN] Each of Read, Insert, Modify, Delete and Execute is equal or stronger
                for Position := 1 to 5 do
                    Assert.IsTrue(
                        Strength(CopyStr(AdminRights, Position, 1)) >= Strength(CopyStr(ApiRights, Position, 1)),
                        StrSubstNo(NotAtLeastAdminErr, ApiConsumerPermission."Object Type", ApiConsumerPermission."Object ID", ApiRights, AdminRights));
            until ApiConsumerPermission.Next() = 0;
        Assert.IsTrue(Checked > 0, StrSubstNo(NothingCheckedErr, 0));
    end;

    [Test]
    procedure ReaderIsReadOnlyOnAllEquipmentTables()
    var
        ReaderPermission: Record "Expanded Permission";
        Checked: Integer;
    begin
        // [SCENARIO 7] (negative) Reader has no Insert, Modify or Delete (direct or indirect) on any EQM table
        // [GIVEN] All tabledata entries of Reader in 50100-50149
        FilterPermissions(ReaderPermission, ReaderRoleTok, 0);
        ReaderPermission.SetFilter("Object ID", EQMObjectIdFilterTok);

        // [WHEN] The rights of each are read
        if ReaderPermission.FindSet() then
            repeat
                Checked += 1;

                // [THEN] Insert, Modify and Delete are none
                Assert.AreEqual('---', CopyStr(RightsText(ReaderPermission), 2, 3), StrSubstNo(UnexpectedRightErr, ReaderRoleTok, ReaderPermission."Object ID"));
            until ReaderPermission.Next() = 0;
        Assert.IsTrue(Checked > 0, StrSubstNo(NothingCheckedErr, 0));
        // Document Attachment is outside the range but Reader reads it too
        AssertNoWriteRights(ReaderRoleTok, Database::"Document Attachment");
    end;

    [Test]
    procedure ManagerCannotDeleteEquipmentCategoriesOrSetup()
    begin
        // [SCENARIO 7] (negative) Manager has no Delete on Equipment, Category and Setup (NFR-002 Q1: Administrators only)
        // [GIVEN] The effective permissions of EQM - Manager
        // [WHEN] The rights on tables 50100, 50101 and 50102 are read
        // [THEN] Delete is none (direct and indirect)
        AssertNoDelete(ManagerRoleTok, Database::"EQM Equipment");
        AssertNoDelete(ManagerRoleTok, Database::"EQM Equipment Category");
        AssertNoDelete(ManagerRoleTok, Database::"EQM Equipment Setup");
    end;

    [Test]
    procedure OnlyAdministratorCanChangeFeatures()
    begin
        // [SCENARIO 9] (negative) Only the Administrator can write the equipment feature setup; Manager and Reader cannot
        // [GIVEN] The effective permissions of EQM - Administrator, EQM - Manager and EQM - Reader
        // [WHEN] The rights on table 50114 are read
        // [THEN] Administrator has Read, Insert, Modify and Delete; Manager and Reader have no write rights
        AssertTableDataRights(AdministratorRoleTok, Database::"EQM Feature Setup", 'YYYY-');
        AssertNoWriteRights(ManagerRoleTok, Database::"EQM Feature Setup");
        AssertNoWriteRights(ReaderRoleTok, Database::"EQM Feature Setup");
    end;

    [Test]
    procedure ReaderHasExecuteOnEveryObjectOfTheApp()
    var
        ExcludedCodeunits: List of [Integer];
        ObjectType: Integer;
    begin
        // [SCENARIO 8] Every table, report, page, query and codeunit in 50100-50149 except codeunits 50104, 50133, 50134 has Execute in Reader
        // [GIVEN] The install, change log registration and upgrade codeunits are the only exceptions
        ExcludedCodeunits.Add(Codeunit::"EQM Install");
        ExcludedCodeunits.Add(Codeunit::"EQM Change Log Registration");
        ExcludedCodeunits.Add(Codeunit::"EQM Upgrade");

        // [WHEN] All objects of the five types in the range are looked up in the effective permissions of Reader
        // [THEN] Each has Execute (direct)
        foreach ObjectType in ObjectTypesToCheck() do
            AssertReaderExecuteForType(ObjectType, ExcludedCodeunits);
    end;

    [Test]
    procedure ReaderHasNoExecuteOnInstallAndUpgradeCodeunits()
    begin
        // [SCENARIO 8] (negative, boundary) The excluded codeunits are really outside Reader, so the exception list is not stale
        // [GIVEN] The effective permissions of EQM - Reader
        // [WHEN] The rights on codeunits 50104, 50133 and 50134 are read
        // [THEN] There is no entry
        AssertNoEntry(ReaderRoleTok, 5, Codeunit::"EQM Install");
        AssertNoEntry(ReaderRoleTok, 5, Codeunit::"EQM Change Log Registration");
        AssertNoEntry(ReaderRoleTok, 5, Codeunit::"EQM Upgrade");
    end;

    local procedure ObjectTypesToCheck() ObjectTypes: List of [Integer]
    begin
        // Platform object type numbers: 1 = Table, 3 = Report, 5 = Codeunit, 8 = Page, 9 = Query
        ObjectTypes.Add(1);
        ObjectTypes.Add(3);
        ObjectTypes.Add(5);
        ObjectTypes.Add(8);
        ObjectTypes.Add(9);
    end;

    local procedure AssertReaderExecuteForType(ObjectType: Integer; ExcludedCodeunits: List of [Integer])
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Checked: Integer;
    begin
        AllObjWithCaption.SetRange("Object Type", ObjectType);
        AllObjWithCaption.SetFilter("Object ID", EQMObjectIdFilterTok);
        if AllObjWithCaption.FindSet() then
            repeat
                if not ((ObjectType = 5) and ExcludedCodeunits.Contains(AllObjWithCaption."Object ID")) then begin
                    Checked += 1;
                    Assert.AreEqual('Y', CopyStr(RightsOf(ReaderRoleTok, ObjectType, AllObjWithCaption."Object ID"), 5, 1), StrSubstNo(ReaderMissingErr, ObjectType, AllObjWithCaption."Object ID"));
                end;
            until AllObjWithCaption.Next() = 0;
        Assert.IsTrue(Checked > 0, StrSubstNo(NothingCheckedErr, ObjectType));
    end;

    local procedure AssertAssignableWithInclude(RoleId: Code[30]; IncludedRoleId: Code[30])
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        MetadataPermissionSetRel: Record "Metadata Permission Set Rel.";
    begin
        MetadataPermissionSet.SetRange("Role ID", RoleId);
        Assert.IsFalse(MetadataPermissionSet.IsEmpty(), StrSubstNo(SetMissingErr, RoleId));
        MetadataPermissionSet.FindFirst();
        Assert.IsTrue(MetadataPermissionSet.Assignable, StrSubstNo(AssignableErr, RoleId));

        MetadataPermissionSetRel.SetRange("Role ID", RoleId);
        if IncludedRoleId = '' then begin
            Assert.AreEqual(0, MetadataPermissionSetRel.Count(), StrSubstNo(IncludeCountErr, RoleId));
            exit;
        end;
        Assert.AreEqual(1, MetadataPermissionSetRel.Count(), StrSubstNo(IncludeCountErr, RoleId));
        MetadataPermissionSetRel.FindFirst();
        Assert.AreEqual(IncludedRoleId, MetadataPermissionSetRel."Related Role ID", StrSubstNo(IncludeTargetErr, RoleId));
        Assert.AreEqual(MetadataPermissionSetRel.Type::Include, MetadataPermissionSetRel.Type, StrSubstNo(IncludeTargetErr, RoleId));
    end;

    local procedure FilterPermissions(var ExpandedPermission: Record "Expanded Permission"; RoleId: Code[30]; ObjectType: Integer)
    begin
        ExpandedPermission.Reset();
        ExpandedPermission.SetRange("Role ID", RoleId);
        // Platform object type numbers match: 0 = Table Data, 1 = Table, 5 = Codeunit, 8 = Page, 9 = Query
        ExpandedPermission."Object Type" := ObjectType;
        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type");
    end;

    local procedure CountEntries(RoleId: Code[30]; ObjectType: Integer): Integer
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        FilterPermissions(ExpandedPermission, RoleId, ObjectType);
        ExpandedPermission.SetFilter("Object ID", EQMObjectIdFilterTok);
        exit(ExpandedPermission.Count());
    end;

    /// <summary>Effective rights of the role on one object as 5 characters: Read, Insert, Modify, Delete, Execute.</summary>
    local procedure RightsOf(RoleId: Code[30]; ObjectType: Integer; ObjectId: Integer): Text
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        FilterPermissions(ExpandedPermission, RoleId, ObjectType);
        ExpandedPermission.SetRange("Object ID", ObjectId);
        if not ExpandedPermission.FindFirst() then
            exit('-----');
        exit(RightsText(ExpandedPermission));
    end;

    local procedure RightsText(ExpandedPermission: Record "Expanded Permission"): Text
    begin
        exit(
            LevelChar(ExpandedPermission."Read Permission") +
            LevelChar(ExpandedPermission."Insert Permission") +
            LevelChar(ExpandedPermission."Modify Permission") +
            LevelChar(ExpandedPermission."Delete Permission") +
            LevelChar(ExpandedPermission."Execute Permission"));
    end;

    local procedure LevelChar(Level: Integer): Text
    begin
        // Option members of the permission fields: 0 = none, 1 = Yes, 2 = Indirect
        case Level of
            1:
                exit('Y');
            2:
                exit('I');
        end;
        exit('-');
    end;

    local procedure Strength(Level: Text): Integer
    begin
        case Level of
            'Y':
                exit(2);
            'I':
                exit(1);
        end;
        exit(0);
    end;

    local procedure AssertTableDataRights(RoleId: Code[30]; TableId: Integer; ExpectedRights: Text)
    begin
        Assert.AreEqual(ExpectedRights, RightsOf(RoleId, 0, TableId), StrSubstNo(TableDataRightsErr, RoleId, TableId));
    end;

    local procedure AssertExecute(RoleId: Code[30]; ObjectType: Integer; ObjectId: Integer)
    begin
        Assert.AreEqual('Y', CopyStr(RightsOf(RoleId, ObjectType, ObjectId), 5, 1), StrSubstNo(ExecuteMissingErr, RoleId, ObjectType, ObjectId));
    end;

    local procedure AssertNoEntry(RoleId: Code[30]; ObjectType: Integer; ObjectId: Integer)
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        FilterPermissions(ExpandedPermission, RoleId, ObjectType);
        ExpandedPermission.SetRange("Object ID", ObjectId);
        Assert.IsTrue(ExpandedPermission.IsEmpty(), StrSubstNo(UnexpectedEntryErr, RoleId, ObjectType, ObjectId));
    end;

    local procedure AssertNoWriteRights(RoleId: Code[30]; TableId: Integer)
    begin
        Assert.AreEqual('---', CopyStr(RightsOf(RoleId, 0, TableId), 2, 3), StrSubstNo(UnexpectedRightErr, RoleId, TableId));
    end;

    local procedure AssertNoDelete(RoleId: Code[30]; TableId: Integer)
    begin
        Assert.AreEqual('-', CopyStr(RightsOf(RoleId, 0, TableId), 4, 1), StrSubstNo(NoDeleteErr, RoleId, TableId));
    end;
}
