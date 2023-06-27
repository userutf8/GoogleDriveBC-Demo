page 50111 "GDI Media Card"
{
    ApplicationArea = All;
    DeleteAllowed = false;
    ModifyAllowed = true;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "GDI Media";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group("Details")
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    Editable = false;
                    ToolTip = 'Unique identifier of the record.';
                }
                field(FileName; Rec.FileName)
                {
                    ApplicationArea = All;
                    Caption = 'File Name';
                    Style = Attention;
                    StyleExpr = Rec.FileID = '';
                    Tooltip = 'Name of the file.';
                }
                field(FileID; Rec.FileID)
                {
                    ApplicationArea = All;
                    Caption = 'File ID';
                    Editable = false;
                    ToolTip = 'Unique Google Drive file identifier.';
                }
                field(FileSize; Rec.FileSize)
                {
                    ApplicationArea = All;
                    Caption = 'File Size (MB)';
                    Editable = false;
                    ToolTip = 'File size in megabytes.';
                }
            }
        }
        area(FactBoxes)
        {
            part(Image; "GDI Media Card Part")
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
                ToolTip = 'Download the file to your device.';

                trigger OnAction()
                var
                    GDIMediaMgt: Codeunit "GDI Media Mgt.";
                begin
                    GDIMediaMgt.Download(Rec.ID);
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