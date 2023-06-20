page 50116 "Google Drive Link Card"
{
    ApplicationArea = All;
    Caption = 'Google Drive Media Link';
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Google Drive Link";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Default)
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
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                }
                field(MediaID; Rec.MediaID)
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {
            part(Picture; "Google Drive Media Card Part")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = ID = field(MediaID);
            }
        }
    }
}