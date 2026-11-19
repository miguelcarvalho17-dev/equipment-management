namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-055 Multi-Language Support. Checks that the pt-PT and es-ES translation files reach the session: the table
/// caption, an enum caption and an error text under a Portuguese and a Spanish language, and the English fallback
/// under a language without a translation file (German). Each test restores the language before it asserts, so a
/// failed assertion never leaks the language into the next test.
/// </summary>
codeunit 50153 "EQM Translation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        MissingCategoryTok: Label 'EQMTRNONE', Locked = true;
        EquipmentPtTxt: Label 'Equipamento', Locked = true;
        EquipmentEsTxt: Label 'Equipo', Locked = true;
        EquipmentEnTxt: Label 'Equipment', Locked = true;
        InMaintenancePtTxt: Label 'Em manutenção', Locked = true;
        InMaintenanceEsTxt: Label 'En mantenimiento', Locked = true;
        InMaintenanceEnTxt: Label 'In Maintenance', Locked = true;
        CategoryNotFoundPtErr: Label 'A categoria de equipamento %1 não existe. Escolha uma categoria na página Categorias de equipamento.', Locked = true, Comment = '%1 = category code';
        CategoryNotFoundEsErr: Label 'La categoría de equipo %1 no existe. Elija una categoría en la página Categorías de equipo.', Locked = true, Comment = '%1 = category code';
        CategoryNotFoundEnErr: Label 'Equipment category %1 does not exist. Choose a category from the Equipment Categories page.', Locked = true, Comment = '%1 = category code';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TableCaptionIsPortugueseUnderPortugueseLanguage()
    var
        Caption: Text;
    begin
        // [SCENARIO T1] The equipment table caption shows in Portuguese for a Portuguese user
        // [GIVEN] The session language is Portuguese (Portugal)
        // [WHEN] The caption of table "EQM Equipment" is read
        Caption := TableCaptionIn(PortugueseLanguageId());

        // [THEN] It is the pt-PT translation
        Assert.AreEqual(EquipmentPtTxt, Caption, 'The table caption must be translated to Portuguese.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TableCaptionIsSpanishUnderSpanishLanguage()
    var
        Caption: Text;
    begin
        // [SCENARIO T2] The equipment table caption shows in Spanish for a Spanish user
        // [GIVEN] The session language is Spanish (Spain)
        // [WHEN] The caption of table "EQM Equipment" is read
        Caption := TableCaptionIn(SpanishLanguageId());

        // [THEN] It is the es-ES translation
        Assert.AreEqual(EquipmentEsTxt, Caption, 'The table caption must be translated to Spanish.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusCaptionIsPortugueseUnderPortugueseLanguage()
    var
        Caption: Text;
    begin
        // [SCENARIO T3] An enum value caption shows in Portuguese for a Portuguese user
        // [GIVEN] The session language is Portuguese (Portugal)
        // [WHEN] The status In Maintenance is formatted
        Caption := StatusCaptionIn(PortugueseLanguageId());

        // [THEN] It is the pt-PT translation
        Assert.AreEqual(InMaintenancePtTxt, Caption, 'The status caption must be translated to Portuguese.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusCaptionIsSpanishUnderSpanishLanguage()
    var
        Caption: Text;
    begin
        // [SCENARIO T4] An enum value caption shows in Spanish for a Spanish user
        // [GIVEN] The session language is Spanish (Spain)
        // [WHEN] The status In Maintenance is formatted
        Caption := StatusCaptionIn(SpanishLanguageId());

        // [THEN] It is the es-ES translation
        Assert.AreEqual(InMaintenanceEsTxt, Caption, 'The status caption must be translated to Spanish.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryErrorIsPortugueseUnderPortugueseLanguage()
    var
        Equipment: Record "EQM Equipment";
        OriginalLanguage: Integer;
        ErrorText: Text;
    begin
        // [SCENARIO T5] (error) The category-not-found error shows in Portuguese for a Portuguese user
        // [GIVEN] A category that does not exist, new equipment, and a Portuguese session language
        EnsureCategoryMissing();
        Equipment.Init();
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(PortugueseLanguageId());

        // [WHEN] The missing category is validated on the equipment
        asserterror Equipment.Validate("Category Code", MissingCategoryTok);
        ErrorText := GetLastErrorText();
        GlobalLanguage(OriginalLanguage);

        // [THEN] The error text is the pt-PT translation with the category code filled in
        Assert.AreEqual(StrSubstNo(CategoryNotFoundPtErr, MissingCategoryTok), ErrorText, 'The error must be translated to Portuguese.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryErrorIsSpanishUnderSpanishLanguage()
    var
        Equipment: Record "EQM Equipment";
        OriginalLanguage: Integer;
        ErrorText: Text;
    begin
        // [SCENARIO T6] (error) The category-not-found error shows in Spanish for a Spanish user
        // [GIVEN] A category that does not exist, new equipment, and a Spanish session language
        EnsureCategoryMissing();
        Equipment.Init();
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(SpanishLanguageId());

        // [WHEN] The missing category is validated on the equipment
        asserterror Equipment.Validate("Category Code", MissingCategoryTok);
        ErrorText := GetLastErrorText();
        GlobalLanguage(OriginalLanguage);

        // [THEN] The error text is the es-ES translation with the category code filled in
        Assert.AreEqual(StrSubstNo(CategoryNotFoundEsErr, MissingCategoryTok), ErrorText, 'The error must be translated to Spanish.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CaptionsFallBackToEnglishUnderUntranslatedLanguage()
    var
        TableCaption: Text;
        StatusCaption: Text;
    begin
        // [SCENARIO T7] (negative) A language without a translation file shows the English captions
        // [GIVEN] The session language is German (Germany), which the app does not translate
        // [WHEN] The table caption and the status caption are read
        TableCaption := TableCaptionIn(GermanLanguageId());
        StatusCaption := StatusCaptionIn(GermanLanguageId());

        // [THEN] Both are the English source text
        Assert.AreEqual(EquipmentEnTxt, TableCaption, 'The table caption must fall back to English.');
        Assert.AreEqual(InMaintenanceEnTxt, StatusCaption, 'The status caption must fall back to English.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryErrorFallsBackToEnglishUnderUntranslatedLanguage()
    var
        Equipment: Record "EQM Equipment";
        OriginalLanguage: Integer;
        ErrorText: Text;
    begin
        // [SCENARIO T8] (negative, error) A language without a translation file shows the English error
        // [GIVEN] A category that does not exist, new equipment, and a German session language
        EnsureCategoryMissing();
        Equipment.Init();
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(GermanLanguageId());

        // [WHEN] The missing category is validated on the equipment
        asserterror Equipment.Validate("Category Code", MissingCategoryTok);
        ErrorText := GetLastErrorText();
        GlobalLanguage(OriginalLanguage);

        // [THEN] The error text is the English source text with the category code filled in
        Assert.AreEqual(StrSubstNo(CategoryNotFoundEnErr, MissingCategoryTok), ErrorText, 'The error must fall back to English.');
    end;

    local procedure PortugueseLanguageId(): Integer
    begin
        exit(2070);
    end;

    local procedure SpanishLanguageId(): Integer
    begin
        exit(3082);
    end;

    local procedure GermanLanguageId(): Integer
    begin
        exit(1031);
    end;

    local procedure TableCaptionIn(LanguageId: Integer): Text
    var
        Equipment: Record "EQM Equipment";
        OriginalLanguage: Integer;
        Caption: Text;
    begin
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Caption := Equipment.TableCaption();
        GlobalLanguage(OriginalLanguage);
        exit(Caption);
    end;

    local procedure StatusCaptionIn(LanguageId: Integer): Text
    var
        OriginalLanguage: Integer;
        Caption: Text;
    begin
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Caption := Format("EQM Equipment Status"::"In Maintenance");
        GlobalLanguage(OriginalLanguage);
        exit(Caption);
    end;

    local procedure EnsureCategoryMissing()
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.SetRange(Code, MissingCategoryTok);
        Category.DeleteAll();
    end;
}
