page 50110 "GDI Media"
{
    AboutText = 'You can view and edit images.';
    AboutTitle = 'Gallery';
    AdditionalSearchTerms = 'Gallery, Google, Drive, Image, Media, Picture';
    ApplicationArea = All;
    Caption = 'Gallery';
    CardPageId = "GDI Media Card";
    DeleteAllowed = false;
    Description = 'View and edit media.';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "GDI Media";
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
                    Style = Attention;
                    StyleExpr = Rec.FileID = '';
                    ShowCaption = false;
                }
            }
        }
        area(FactBoxes)
        {
            part("Selected"; "GDI Media Card Part")
            {
                ApplicationArea = All;
                Caption = 'Image';
                SubPageLink = ID = field(ID);
            }
            part("Selected Links"; "GDI Links Part")
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
                ToolTip = 'Upload a new file and sync it with Google Drive.';

                trigger OnAction()
                var
                    GDIMediaMgt: Codeunit "GDI Media Mgt.";
                begin
                    GDIMediaMgt.Create();
                end;

            }

            action("Replace")
            {
                ApplicationArea = All;
                Image = Change;
                ToolTip = 'Replace the existing file by a new file and sync it with Google Drive.';

                trigger OnAction()
                var
                    GDIMediaMgt: Codeunit "GDI Media Mgt.";
                begin
                    GDIMediaMgt.Update(Rec.ID);
                end;
            }
            action("Delete")
            {
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Delete the existing file from the database and Google Drive.';

                trigger OnAction()
                var
                    GDIMediaMgt: Codeunit "GDI Media Mgt.";
                begin
                    GDIMediaMgt.Delete(Rec.ID);
                end;
            }

            action("Download")
            {
                ApplicationArea = All;
                Image = Download;
                ToolTip = 'Download the file to your device.';

                trigger OnAction()
                var
                    GDIMediaMgt: Codeunit "GDI Media Mgt.";
                begin
                    GDIMediaMgt.Download(Rec.ID);
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
                RunObject = page "GDI Links";
                RunPageLink = MediaID = field(ID);
                ToolTip = 'Open links page for the current media.';
            }
            action("All Links")
            {
                ApplicationArea = All;
                Caption = 'All Links';
                Image = Links;
                RunObject = page "GDI Links";
                ToolTip = 'Open links page to view and edit all existing links.';
            }
            action("Queue")
            {
                ApplicationArea = All;
                Caption = 'Queue';
                Image = ErrorLog;
                RunObject = page "GDI Queue";
                ToolTip = 'Open sync queue page to view all existing queue entries.';
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
                actionref(Problems_Promoted; Queue)
                {

                }
            }
        }
    }
}