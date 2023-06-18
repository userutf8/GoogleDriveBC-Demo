page 50124 "Google Drive Media Card"
{
    ApplicationArea = All;
    DeleteAllowed = false;
    Editable = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Google Drive Media";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group("Details")
            {
                field(FileName; Rec.FileName)
                {
                }
                field(ID; Rec.ID)
                {
                }
                field(FileID; Rec.FileID)
                {
                }
                field("Media"; Rec.FileContent)
                {
                    ShowCaption = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(Image; "Google Drive Media Card Part")
            {
                Caption = 'Image';
                SubPageLink = ID = field(ID);
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Download")
            {
                Image = Download;

                trigger OnAction()
                begin
                    Message('Download');
                end;
            }
            action("Replace")
            {
                Image = Change;

                trigger OnAction()
                var
                    GoogleDriveMgt: Codeunit "Google Drive Mgt.";
                begin
                    GoogleDriveMgt.Update(Rec.FileID);
                end;
            }
            action("Delete")
            {
                Image = Delete;

                trigger OnAction()
                var
                    GoogleDriveMgt: Codeunit "Google Drive Mgt.";
                begin
                    GoogleDriveMgt.Delete(Rec.FileID);
                end;
            }
        }
        area(Navigation)
        {
            action("Links")
            {
                Caption = 'Links...';
                Image = Links;
                RunObject = page "Google Drive Links";
                RunPageLink = MediaID = field(ID);
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Replace_Promoted; "Replace")
                {

                }
                actionref(Delete_Promoted; "Delete")
                {

                }
                actionref(Download_Promoted; "Download")
                {

                }
                actionref(Links_Promoted; Links)
                {

                }
            }
        }
    }
}