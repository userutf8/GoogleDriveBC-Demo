page 50117 "Google Drive Links Part"
{
    ApplicationArea = All;
    CardPageId = "Google Drive Link Card";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Google Drive Link";
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
                }
                field(EntityID; Rec.EntityID)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}