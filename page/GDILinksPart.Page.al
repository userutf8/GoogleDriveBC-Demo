page 50117 "GDI Links Part"
{
    ApplicationArea = All;
    CardPageId = "GDI Link Card";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "GDI Link";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Default)
            {
                ShowCaption = false;
                field(EntityTypeID; Rec.EntityTypeID)
                {
                    ApplicationArea = All;
                    Tooltip = 'Identifier of the entity type. Table number by default.';
                }
                field(EntityID; Rec.EntityID)
                {
                    ApplicationArea = All;
                    Tooltip = 'Identifier of the entity. Record code by default.';
                }
            }
        }
    }
}