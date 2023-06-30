codeunit 50130 "GDI Links Handler"
{
    procedure CreateLink(MediaID: Integer; EntityTypeID: Integer; EntityID: Text)
    var
        GDILink: Record "GDI Link";
        EntryNo: Integer;
    begin
        GDILink.SetCurrentKey(EntityTypeID, EntityID, EntryNo);
        GDILink.SetRange(EntityTypeID, EntityTypeID);
        GDILink.SetRange(EntityID, EntityID);
        if GDILink.FindLast() then
            EntryNo := GDILink.EntryNo + 1
        else
            EntryNo := 1;

        Clear(GDILink);
        GDILink.Init();
        GDILink.ID := 0;
        GDILink.Validate(EntityID, EntityID);
        GDILink.Validate(EntityTypeID, EntityTypeID);
        GDILink.Validate(EntryNo, EntryNo);
        GDILink.Validate(MediaID, MediaID);
        GDILink.Insert(true);
    end;

    procedure CreateSelectionFilter(EntityTypeID: Integer; EntityID: Text): Text
    var
        GDILink: Record "GDI Link";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        SelectionFilter: Text;
    begin
        if not (EntityTypeID in [0, Database::Item, Database::Customer, Database::Vendor, Database::Employee]) then
            GDIErrorHandler.ThrowNotImplementedErr();

        if EntityTypeID = 0 then
            exit(''); // no filter

        GDILink.SetCurrentKey(EntityTypeID, EntityID, EntryNo);
        GDILink.SetRange(EntityTypeID, EntityTypeID);
        GDILink.SetRange(EntityID, EntityID);
        if GDILink.FindSet() then begin
            repeat
                SelectionFilter += Format(GDILink.MediaID) + '|';
            until GDILink.Next() = 0;
            SelectionFilter := SelectionFilter.Substring(1, StrLen(SelectionFilter) - 1);
        end;
        if SelectionFilter = '' then
            SelectionFilter := '0';
        exit(SelectionFilter);
    end;

    procedure DeleteLink(MediaID: Integer; EntityTypeID: Integer; EntityID: Text)
    var
        GDILink: Record "GDI Link";
    begin
        GDILink.SetRange(MediaID, MediaID);
        GDILink.SetRange(EntityTypeID, EntityTypeID);
        GDILink.SetRange(EntityID, EntityID);
        GDILink.DeleteAll();
    end;

    procedure MediaHasSeveralLinks(MediaID: Integer; EntityTypeID: Integer; EntityID: Text): Boolean
    var
        GDILink: Record "GDI Link";
        AnotherEntityTypeHasLink: Boolean;
    begin
        // A and not (B and C) = A and not A or A and not B
        GDILink.SetRange(MediaID, MediaID);
        GDILink.SetFilter(EntityTypeID, '<>%1', EntityTypeID);
        AnotherEntityTypeHasLink := not GDILink.IsEmpty();
        GDILink.SetRange(EntityTypeID);
        GDILink.SetFilter(EntityID, '<>%1', EntityID);
        exit(AnotherEntityTypeHasLink or not GDILink.IsEmpty());
    end;
}