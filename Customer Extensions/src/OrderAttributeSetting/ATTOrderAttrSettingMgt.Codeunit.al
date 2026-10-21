namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Computes the resulting order attribute setting of an item: for every attribute mapped anywhere on the item itself,
/// its item category, or an ancestor of that category, the setting of the closest level wins outright.
/// </summary>
codeunit 50105 "ATT Order Attr. Setting Mgt."
{
    var
        ItemLevelTxt: Label 'Item';
        ItemCategoryLevelTxt: Label 'Item category %1', Comment = '%1 = item category code';
        CyclicCategoryErr: Label 'The item category structure is not valid: %1 is a parent of itself or of one of its children.', Comment = '%1 = item category code';

    /// <summary>
    /// Returns the resulting order attribute setting of an item.
    /// </summary>
    /// <param name="ItemNo">The number of the item.</param>
    /// <param name="TempResult">Returns one row per attribute that applies to the item, with the winning Mandatory, Sequence,
    /// Default Value and print settings, and the level they came from. Attributes marked Not Applicable at the closest
    /// level that has a row for them are not returned at all.</param>
    /// <remarks>
    /// For every attribute, the setting of the closest level wins outright: the item itself, then its item category,
    /// then each ancestor category (via Parent Category, walked as far as it goes). Fields of different levels are never
    /// mixed for the same attribute. The two print settings fall back to the item attribute's own setting when the
    /// winning row leaves them blank (inherit).
    /// </remarks>
    procedure GetResultingSetting(ItemNo: Code[20]; var TempResult: Record "ATT Res. Order Attr. Setting" temporary)
    var
        Item: Record Item;
        DecidedAttributeIds: List of [Integer];
    begin
        TempResult.Reset();
        TempResult.DeleteAll();

        Item.SetLoadFields("Item Category Code");
        Item.Get(ItemNo);

        ResolveLevel(TempResult, DecidedAttributeIds, Database::Item, ItemNo, ItemLevelTxt);
        ResolveCategoryChain(TempResult, DecidedAttributeIds, Item."Item Category Code");
    end;

    local procedure ResolveCategoryChain(var TempResult: Record "ATT Res. Order Attr. Setting" temporary; var DecidedAttributeIds: List of [Integer]; StartCategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
        VisitedCategories: List of [Code[20]];
        CurrentCategoryCode: Code[20];
    begin
        CurrentCategoryCode := StartCategoryCode;
        while CurrentCategoryCode <> '' do begin
            if VisitedCategories.Contains(CurrentCategoryCode) then
                Error(CyclicCategoryErr, CurrentCategoryCode);
            VisitedCategories.Add(CurrentCategoryCode);

            ResolveLevel(
                TempResult, DecidedAttributeIds, Database::"Item Category", CurrentCategoryCode,
                CopyStr(StrSubstNo(ItemCategoryLevelTxt, CurrentCategoryCode), 1, 100));

            ItemCategory.SetLoadFields("Parent Category");
            if ItemCategory.Get(CurrentCategoryCode) then
                CurrentCategoryCode := ItemCategory."Parent Category"
            else
                CurrentCategoryCode := '';
        end;
    end;

    local procedure ResolveLevel(var TempResult: Record "ATT Res. Order Attr. Setting" temporary; var DecidedAttributeIds: List of [Integer]; TableId: Integer; No: Code[20]; LevelText: Text[100])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", TableId);
        ItemAttributeValueMapping.SetRange("No.", No);
        if not ItemAttributeValueMapping.FindSet() then
            exit;

        repeat
            if not DecidedAttributeIds.Contains(ItemAttributeValueMapping."Item Attribute ID") then begin
                DecidedAttributeIds.Add(ItemAttributeValueMapping."Item Attribute ID");
                if not ItemAttributeValueMapping."ATT Not Applicable" then
                    InsertResult(TempResult, ItemAttributeValueMapping, LevelText);
            end;
        until ItemAttributeValueMapping.Next() = 0;
    end;

    local procedure InsertResult(var TempResult: Record "ATT Res. Order Attr. Setting" temporary; ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; LevelText: Text[100])
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.SetLoadFields(Name, "ATT Show on Customer Docs", "ATT Show on Production Docs");
        ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID");

        TempResult.Init();
        TempResult."Attribute ID" := ItemAttributeValueMapping."Item Attribute ID";
        TempResult."Attribute Name" := ItemAttribute.Name;
        TempResult.Mandatory := ItemAttributeValueMapping."ATT Mandatory";
        TempResult.Sequence := ItemAttributeValueMapping."ATT Sequence";
        TempResult."Default Value" := GetDefaultValueText(ItemAttributeValueMapping);
        TempResult."Show on Customer Documents" :=
            ResolvePrintFlag(ItemAttributeValueMapping."ATT Cust. Docs Override", ItemAttribute."ATT Show on Customer Docs");
        TempResult."Show on Production Documents" :=
            ResolvePrintFlag(ItemAttributeValueMapping."ATT Prod. Docs Override", ItemAttribute."ATT Show on Production Docs");
        TempResult.Level := LevelText;
        TempResult.Insert();
    end;

    local procedure GetDefaultValueText(ItemAttributeValueMapping: Record "Item Attribute Value Mapping"): Text[250]
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // "Item Attribute Value ID" is the authoritative value (it is what the sales line would actually get); it is read
        // first so that a row whose value was last changed through a standard Microsoft page (which sets this field directly
        // and never touches "ATT Default Value") is never masked by a stale "ATT Default Value" entry. The text field is
        // only a fallback for rows where no value has been resolved into "Item Attribute Value ID" at all.
        if ItemAttributeValueMapping."Item Attribute Value ID" <> 0 then begin
            ItemAttributeValue.SetLoadFields(Value);
            if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                exit(ItemAttributeValue.Value);
        end;

        exit(ItemAttributeValueMapping."ATT Default Value");
    end;

    local procedure ResolvePrintFlag(OverrideOption: Enum "ATT Override Option"; ItemAttributeFlag: Boolean): Boolean
    begin
        case OverrideOption of
            OverrideOption::Yes:
                exit(true);
            OverrideOption::No:
                exit(false);
            else
                exit(ItemAttributeFlag);
        end;
    end;
}
