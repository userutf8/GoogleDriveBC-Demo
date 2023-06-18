page 50122 "Google Drive Link Card"
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

                }
                field(EntityID; Rec.EntityID)
                {

                }
                field(EntryNo; Rec.EntryNo)
                {

                }
                field(MediaID; Rec.MediaID)
                {

                }
            }
        }
        area(Factboxes)
        {
            part(Picture; "Google Drive Media Card Part")
            {
                Caption = 'Picture';
                SubPageLink = ID = field(MediaID);
            }
        }
    }
}