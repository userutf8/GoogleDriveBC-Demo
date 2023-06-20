page 50115 "Google Drive Links"
{
    AboutText = 'You can add, modify and delete links between Business Central entities and Google Drive files.';
    AboutTitle = 'Google Drive Media Links';
    AdditionalSearchTerms = 'Gallery, Google, Drive, Image, Media, Picture';
    ApplicationArea = All;
    Caption = 'Google Drive Media Links';
    CardPageId = "Google Drive Link Card";
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    MultipleNewLines = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Google Drive Link";
    UsageCategory = Lists;

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
                    Width = 10;
                }
                field(EntityID; Rec.EntityID)
                {
                    ApplicationArea = All;
                    Width = 40;
                }
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                }
                field(MediaID; Rec.MediaID)
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GoogleDriveMedia: Record "Google Drive Media";
                        Gallery: Page Gallery;
                    begin
                        Gallery.SetRecord(GoogleDriveMedia);
                        Gallery.RunModal();
                        Gallery.GetRecord(GoogleDriveMedia);
                        Rec.MediaID := GoogleDriveMedia.ID;
                    end;

                }
            }
        }
        area(Factboxes)
        {
            part(Picture; "Google Drive Media Card Part")
            {
                ApplicationArea = All;
                Caption = 'Image';
                Visible = true;
                SubPageLink = ID = field(MediaID);
            }
        }
    }
}