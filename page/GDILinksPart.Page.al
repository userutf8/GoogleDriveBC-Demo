page 50117 "GDI Links Part"
{
    ApplicationArea = All;
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
                    Caption = 'Type';
                    Tooltip = 'Identifier of the entity type. Table number by default.';
                    Width = 6;
                }
                field(EntityID; Rec.EntityID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    Tooltip = 'Identifier of the entity. Record code by default.';
                    Width = 10;
                }
            }
        }
    }
}