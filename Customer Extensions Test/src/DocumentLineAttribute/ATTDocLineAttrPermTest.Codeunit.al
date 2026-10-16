namespace Attitutor.CustomerExtensions.Test.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests that the ATT CUSTOM permission set of the Customer Extensions app gives full access to the document line attribute
/// objects, and that every object of the app is in it (CU-123x5y65gje, permission set rule of the project).
/// </summary>
/// <remarks>
/// These tests read the permission set metadata instead of running code with lowered permissions, because
/// Library - Lower Permissions (Tests-TestLibraries) is not available in an online sandbox. They therefore do not prove
/// that users without ATT CUSTOM can post and delete sales lines with attributes; that relies on the InherentPermissions
/// attributes on the subscribers and is tested at runtime by the container-only app Customer Extensions Permission Test.
/// Run with test runner 130450 "Test Runner - Isol. Codeunit" (codeunit-level isolation) in a dedicated test company,
/// like the other test codeunits of this app. These tests only read metadata and change no data.
/// </remarks>
codeunit 50153 "ATT Doc. Line Attr. Perm. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Document Line Attribute] [Permissions]

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;
        CustomerExtensionsAppIdTxt: Label 'ca85000e-7040-449e-a825-6f7d7d6f718a', Locked = true;
        ATTCustomRoleIdTxt: Label 'ATT CUSTOM', Locked = true;
        PermissionMissingMsg: Label 'ATT CUSTOM must grant %1 permission on %2 %3.', Comment = '%1 = permission, %2 = object type, %3 = object ID';
        ObjectsMissingFromPermissionSetMsg: Label 'These objects of the Customer Extensions app are missing from ATT CUSTOM or lack full permissions: %1', Comment = '%1 = list of object types and IDs';
        PermissionSetNotAssignableMsg: Label 'ATT CUSTOM must be assignable.';
        ObjectEntryTxt: Label '%1 %2', Locked = true;
        DocLineAttrSubscrNameTxt: Label 'ATT Doc. Line Attr. Subscr.', Locked = true;
        AppCodeunitNotFoundErr: Label 'Codeunit %1 of the Customer Extensions app was not found.', Comment = '%1 = codeunit name';

    [Test]
    procedure ATTCustomPermissionSet_IsAssignable()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        // [SCENARIO] ATT CUSTOM can be assigned to users.
        Initialize();

        // [GIVEN] The ATT CUSTOM permission set of the Customer Extensions app
        // [WHEN] Its metadata is read
        MetadataPermissionSet.Get(GetCustomerExtensionsAppId(), ATTCustomRoleIdTxt);

        // [THEN] It is assignable
        Assert.IsTrue(MetadataPermissionSet.Assignable, PermissionSetNotAssignableMsg);
    end;

    [Test]
    procedure ATTCustomPermissionSet_GrantsFullAccessToDocLineAttributeData()
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        // [SCENARIO] ATT CUSTOM gives read, insert, modify and delete permission on the data of ATT Document Line Attribute.
        Initialize();

        // [GIVEN] The ATT CUSTOM permission set
        // [WHEN] Its permission on the data of ATT Document Line Attribute is read
        FindPermission(MetadataPermission, MetadataPermission."Object Type"::"Table Data", Database::"ATT Document Line Attribute");

        // [THEN] It is RIMD
        AssertFullTableDataPermission(MetadataPermission);
    end;

    [Test]
    procedure ATTCustomPermissionSet_GrantsExecuteOnDocLineAttributeTable()
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        // [SCENARIO] ATT CUSTOM gives execute permission on the ATT Document Line Attribute table object.
        Initialize();

        // [GIVEN] The ATT CUSTOM permission set
        // [WHEN] Its permission on the ATT Document Line Attribute table object is read
        FindPermission(MetadataPermission, MetadataPermission."Object Type"::Table, Database::"ATT Document Line Attribute");

        // [THEN] It is X
        AssertExecutePermission(MetadataPermission);
    end;

    [Test]
    procedure ATTCustomPermissionSet_GrantsExecuteOnDocLineAttributeMgt()
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        // [SCENARIO] ATT CUSTOM gives execute permission on the ATT Doc. Line Attribute Mgt. codeunit.
        Initialize();

        // [GIVEN] The ATT CUSTOM permission set
        // [WHEN] Its permission on the ATT Doc. Line Attribute Mgt. codeunit is read
        FindPermission(MetadataPermission, MetadataPermission."Object Type"::Codeunit, Codeunit::"ATT Doc. Line Attribute Mgt.");

        // [THEN] It is X
        AssertExecutePermission(MetadataPermission);
    end;

    [Test]
    procedure ATTCustomPermissionSet_GrantsExecuteOnDocLineAttrSubscr()
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        // [SCENARIO] ATT CUSTOM gives execute permission on the ATT Doc. Line Attr. Subscr. codeunit.
        Initialize();

        // [GIVEN] The ATT CUSTOM permission set
        // [WHEN] Its permission on the ATT Doc. Line Attr. Subscr. codeunit is read
        FindPermission(MetadataPermission, MetadataPermission."Object Type"::Codeunit, GetAppCodeunitId(DocLineAttrSubscrNameTxt));

        // [THEN] It is X
        AssertExecutePermission(MetadataPermission);
    end;

    [Test]
    procedure EveryObjectOfCustomerExtensions_IsInATTCustomPermissionSet()
    var
        MissingObjects: Text;
    begin
        // [SCENARIO] Every table, page, report, codeunit, XMLport and query of the Customer Extensions app is in ATT CUSTOM with full permissions.
        Initialize();

        // [GIVEN] The objects of the Customer Extensions app
        // [WHEN] Each object is looked up in ATT CUSTOM
        MissingObjects := GetObjectsMissingFromPermissionSet();

        // [THEN] No object is missing
        Assert.AreEqual('', MissingObjects, StrSubstNo(ObjectsMissingFromPermissionSetMsg, MissingObjects));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure GetCustomerExtensionsAppId(): Guid
    var
        AppId: Guid;
    begin
        Evaluate(AppId, CustomerExtensionsAppIdTxt);
        exit(AppId);
    end;

    local procedure FindPermission(var MetadataPermission: Record "Metadata Permission"; ObjectType: Option; ObjectId: Integer)
    begin
        SetPermissionFilter(MetadataPermission, ObjectType, ObjectId);
        Assert.RecordIsNotEmpty(MetadataPermission);
        MetadataPermission.FindFirst();
    end;

    local procedure SetPermissionFilter(var MetadataPermission: Record "Metadata Permission"; ObjectType: Option; ObjectId: Integer)
    begin
        MetadataPermission.SetRange("App ID", GetCustomerExtensionsAppId());
        MetadataPermission.SetRange("Role ID", ATTCustomRoleIdTxt);
        MetadataPermission.SetRange("Object Type", ObjectType);
        MetadataPermission.SetRange("Object ID", ObjectId);
    end;

    local procedure AssertFullTableDataPermission(MetadataPermission: Record "Metadata Permission")
    begin
        Assert.AreEqual(
            MetadataPermission."Read Permission"::Yes, MetadataPermission."Read Permission",
            StrSubstNo(PermissionMissingMsg, 'R', MetadataPermission."Object Type", MetadataPermission."Object ID"));
        Assert.AreEqual(
            MetadataPermission."Insert Permission"::Yes, MetadataPermission."Insert Permission",
            StrSubstNo(PermissionMissingMsg, 'I', MetadataPermission."Object Type", MetadataPermission."Object ID"));
        Assert.AreEqual(
            MetadataPermission."Modify Permission"::Yes, MetadataPermission."Modify Permission",
            StrSubstNo(PermissionMissingMsg, 'M', MetadataPermission."Object Type", MetadataPermission."Object ID"));
        Assert.AreEqual(
            MetadataPermission."Delete Permission"::Yes, MetadataPermission."Delete Permission",
            StrSubstNo(PermissionMissingMsg, 'D', MetadataPermission."Object Type", MetadataPermission."Object ID"));
    end;

    local procedure AssertExecutePermission(MetadataPermission: Record "Metadata Permission")
    begin
        Assert.AreEqual(
            MetadataPermission."Execute Permission"::Yes, MetadataPermission."Execute Permission",
            StrSubstNo(PermissionMissingMsg, 'X', MetadataPermission."Object Type", MetadataPermission."Object ID"));
    end;

    local procedure GetObjectsMissingFromPermissionSet() MissingObjects: Text
    var
        AppObject: Record AllObj;
        ExpandedPermission: Record "Expanded Permission";
    begin
        SetAppObjectFilter(AppObject);
        AppObject.SetLoadFields("Object Type", "Object ID");
        if not AppObject.FindSet() then
            exit;

        repeat
            if not HasExecutePermission(AppObject) then
                AddMissingObject(MissingObjects, Format(AppObject."Object Type"), AppObject."Object ID");
            if AppObject."Object Type" = AppObject."Object Type"::Table then
                if not HasFullTableDataPermission(AppObject."Object ID") then
                    AddMissingObject(MissingObjects, Format(ExpandedPermission."Object Type"::"Table Data"), AppObject."Object ID");
        until AppObject.Next() = 0;
    end;

    local procedure GetAppCodeunitId(CodeunitName: Text): Integer
    var
        AppObject: Record AllObj;
    begin
        // The codeunit is internal to the Customer Extensions app, so it cannot be referenced by name from this app.
        SetAppObjectFilter(AppObject);
        AppObject.SetRange("Object Type", AppObject."Object Type"::Codeunit);
        AppObject.SetRange("Object Name", CodeunitName);
        AppObject.SetLoadFields("Object ID");
        if not AppObject.FindFirst() then
            Error(AppCodeunitNotFoundErr, CodeunitName);
        exit(AppObject."Object ID");
    end;

    local procedure SetAppObjectFilter(var AppObject: Record AllObj)
    var
        AnchorObject: Record AllObj;
    begin
        // The ATT Document Line Attribute table belongs to the Customer Extensions app, so its package ID identifies the app's objects.
        AnchorObject.SetLoadFields("App Package ID");
        AnchorObject.Get(AnchorObject."Object Type"::Table, Database::"ATT Document Line Attribute");

        AppObject.SetRange("App Package ID", AnchorObject."App Package ID");
        AppObject.SetFilter(
            "Object Type", '%1|%2|%3|%4|%5|%6',
            AppObject."Object Type"::Table, AppObject."Object Type"::Report, AppObject."Object Type"::Codeunit,
            AppObject."Object Type"::XMLport, AppObject."Object Type"::Page, AppObject."Object Type"::Query);
    end;

    local procedure SetExpandedPermissionFilter(var ExpandedPermission: Record "Expanded Permission"; ObjectType: Option; ObjectId: Integer)
    begin
        // Expanded Permission includes the permissions of the sets that ATT CUSTOM includes, minus the ones it excludes.
        // Object ID 0 grants the permission on all objects of the type.
        ExpandedPermission.SetRange("App ID", GetCustomerExtensionsAppId());
        ExpandedPermission.SetRange("Role ID", ATTCustomRoleIdTxt);
        ExpandedPermission.SetRange("Object Type", ObjectType);
        ExpandedPermission.SetFilter("Object ID", '%1|%2', ObjectId, 0);
    end;

    local procedure HasExecutePermission(AppObject: Record AllObj): Boolean
    var
        ExpandedPermission: Record "Expanded Permission";
        ObjectTypeOrdinal: Integer;
    begin
        // AllObj and Expanded Permission use the same ordinals for these object types.
        ObjectTypeOrdinal := AppObject."Object Type";
        SetExpandedPermissionFilter(ExpandedPermission, ObjectTypeOrdinal, AppObject."Object ID");
        ExpandedPermission.SetRange("Execute Permission", ExpandedPermission."Execute Permission"::Yes);
        exit(not ExpandedPermission.IsEmpty());
    end;

    local procedure HasFullTableDataPermission(TableId: Integer): Boolean
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        SetExpandedPermissionFilter(ExpandedPermission, ExpandedPermission."Object Type"::"Table Data", TableId);
        ExpandedPermission.SetRange("Read Permission", ExpandedPermission."Read Permission"::Yes);
        ExpandedPermission.SetRange("Insert Permission", ExpandedPermission."Insert Permission"::Yes);
        ExpandedPermission.SetRange("Modify Permission", ExpandedPermission."Modify Permission"::Yes);
        ExpandedPermission.SetRange("Delete Permission", ExpandedPermission."Delete Permission"::Yes);
        exit(not ExpandedPermission.IsEmpty());
    end;

    local procedure AddMissingObject(var MissingObjects: Text; ObjectType: Text; ObjectId: Integer)
    begin
        if MissingObjects <> '' then
            MissingObjects += ', ';
        MissingObjects += StrSubstNo(ObjectEntryTxt, ObjectType, ObjectId);
    end;
}
