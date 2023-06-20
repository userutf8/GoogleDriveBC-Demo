page 50110 Gallery
{
    AboutText = 'You can view and edit images.';
    AboutTitle = 'Gallery';
    AdditionalSearchTerms = 'Gallery, Google, Drive, Image, Media, Picture';
    ApplicationArea = All;
    Caption = 'Gallery';
    CardPageId = "Google Drive Media Card";
    DeleteAllowed = false;
    Description = 'View and edit media.';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Google Drive Media";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {

            repeater("Images")
            {
                field(FileName; Rec.FileName)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
        }
        area(FactBoxes)
        {
            part("Selected"; "Google Drive Media Card Part")
            {
                ApplicationArea = All;
                Caption = 'Image';
                SubPageLink = ID = field(ID);
            }
            part("Selected Links"; "Google Drive Links Part")
            {
                ApplicationArea = All;
                Caption = 'Links';
                SubPageLink = MediaID = field(ID);
            }
        }
    }
    actions
    {
        area(Creation)
        {
            action("Add")
            {
                ApplicationArea = All;
                Image = Add;

                trigger OnAction()
                var
                    GoogleDriveMgt: Codeunit "Google Drive Mgt.";
                begin
                    GoogleDriveMgt.Create();
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

            action("Download")
            {
                ApplicationArea = All;
                Image = Download;

                trigger OnAction()
                begin
                    Message('Download');
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
            action("All Links")
            {
                ApplicationArea = All;
                Caption = 'All Links';
                Image = Links;
                RunObject = page "Google Drive Links";
            }
            action("Problems")
            {
                ApplicationArea = All;
                Caption = 'Problems';
                Image = ErrorLog;
                RunObject = page "Google Drive Queue";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Add_Promoted; "Add")
                {

                }
                actionref(Replace_Promoted; "Replace")
                {

                }
                actionref(Delete_Promoted; "Delete")
                {

                }
                actionref(Download_Promoted; "Download")
                {

                }
                actionref(Links_Promoted; "Links")
                {

                }
                actionref(AllLinks_Promoted; "All Links")
                {

                }
                actionref(Problems_Promoted; Problems)
                {

                }
            }
        }
    }
}