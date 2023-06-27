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

            part("Statistics"; "GDI Media Stat Card Part")
            {
                ApplicationArea = All;
                Caption = 'Stats';
                SubPageLink = MediaID = field(ID);
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
                    NewMediaID: Integer;
                begin
                    GDIMediaMgt.CreateWithLink(NewMediaID, CurrentEntityTypeID, CurrentEntityID);
                    UpdateFilter();
                end;

            }
        }
        area(Processing)
        {
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
                    GDIMediaMgt.Delete(Rec.ID, CurrentEntityTypeID, CurrentEntityID);
                    UpdateFilter(); // to prevent the case when another record linked to another entity appears on page
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

            action("Add Links")
            {
                ApplicationArea = All;
                Caption = 'Add Links...';
                Image = Links;
                ToolTip = 'Open links page for the current entity.';
                Visible = CurrentEntityTypeID <> 0;

                trigger OnAction()
                var
                    GDILink: Record "GDI Link";
                    GDILinks: Page "GDI Links";
                begin
                    GDILink.SetRange(EntityTypeID, CurrentEntityTypeID);
                    GDILink.SetRange(EntityID, CurrentEntityID);
                    GDILinks.SetEntity(CurrentEntityTypeID, CurrentEntityID);
                    GDILinks.SetTableView(GDILink);
                    GDILinks.Run();
                    UpdateFilter(); // TODO: not WAI
                end;
            }

            action("Media Links")
            {
                ApplicationArea = All;
                Caption = 'Media Links';
                Image = Links;
                ToolTip = 'Open links page for the current media.';

                trigger OnAction()
                var
                    GDILink: Record "GDI Link";
                    GDILinks: Page "GDI Links";
                begin
                    GDILink.SetRange(MediaID, Rec.ID);
                    GDILinks.SetEntity(CurrentEntityTypeID, CurrentEntityID);
                    GDILinks.SetTableView(GDILink);
                    GDILinks.Run();
                    UpdateFilter(); // TODO: not WAI
                end;
            }
            action("All Links")
            {
                ApplicationArea = All;
                Caption = 'All Links';
                Image = Links;
                ToolTip = 'Open links page to view and edit all existing links.';

                trigger OnAction()
                var
                    GDILinks: Page "GDI Links";
                begin
                    GDILinks.SetEntity(CurrentEntityTypeID, CurrentEntityID);
                    GDILinks.Run();
                    UpdateFilter(); // TODO: not WAI
                end;
            }
            action("Refresh")
            {
                ApplicationArea = all;
                Caption = 'Refresh';
                Image = Refresh;
                Tooltip = 'Refreshes the page. Use it when some changes are not applied.';

                trigger OnAction()
                begin
                    UpdateFilter();
                end;
            }
        }
        area(Navigation)
        {
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

                actionref(AddLinks_Promoted; "Add Links")
                {

                }


                actionref(Delete_Promoted; "Delete")
                {

                }

                actionref(Refresh_Promoted; "Refresh")
                {

                }

                actionref(Replace_Promoted; "Replace")
                {

                }

                actionref(Download_Promoted; "Download")
                {

                }

                actionref(MediaLinks_Promoted; "Media Links")
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

    procedure SetEntity(EntityTypeID: Integer; EntityID: Text)
    begin
        // required for making new links
        CurrentEntityTypeID := EntityTypeID;
        CurrentEntityID := EntityID;
    end;

    local procedure UpdateFilter()
    var
        GDILinksHandler: Codeunit "GDI Links Handler";
    begin
        Rec.FilterGroup(0);
        if CurrentEntityTypeID <> 0 then
            Rec.SetFilter(ID, GDILinksHandler.CreateSelectionFilter(CurrentEntityTypeID, CurrentEntityID));
    end;

    var
        // required for making new links
        CurrentEntityTypeID: Integer;
        CurrentEntityID: Text;
}