page 50116 "GDI Link Card"
{
    ApplicationArea = All;
    Caption = 'Google Drive Media Link';
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "GDI Link";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Default)
            {
                ShowCaption = false;

                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifier of the record.';
                    Editable = false;
                }

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
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of the current media in the collection for the current entity.';
                }
                field(MediaID; Rec.MediaID)
                {
                    ApplicationArea = All;
                    Tooltip = 'Identifier of the related media.';
                }
            }
        }
        area(Factboxes)
        {
            part(Picture; "GDI Media Card Part")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = ID = field(MediaID);
            }
        }
    }
}