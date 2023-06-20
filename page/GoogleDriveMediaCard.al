page 50111 "Google Drive Media Card"
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
                    ApplicationArea = All;
                }
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                }
                field(FileID; Rec.FileID)
                {
                    ApplicationArea = All;
                }
                field("Media"; Rec.FileContent)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(Image; "Google Drive Media Card Part")
            {
                ApplicationArea = All;
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
                ApplicationArea = All;
                Image = Download;

                trigger OnAction()
                begin
                    Message('Download');
                end;
            }
            action("Replace")
            {
                ApplicationArea = All;
                Image = Change;

                trigger OnAction()
                var
                    GoogleDriveMgt: Codeunit "Google Drive Mgt.";
                begin
                    GoogleDriveMgt.Update(Rec.ID);
                end;
            }
            action("Delete")
            {
                ApplicationArea = All;
                Image = Delete;

                trigger OnAction()
                var
                    GoogleDriveMgt: Codeunit "Google Drive Mgt.";
                begin
                    GoogleDriveMgt.Delete(Rec.ID);
                end;
            }
        }
        area(Navigation)
        {
            action("Links")
            {
                ApplicationArea = All;
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