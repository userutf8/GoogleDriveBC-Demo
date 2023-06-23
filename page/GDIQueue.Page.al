Page 50120 "GDI Queue"
{
    ApplicationArea = all;
    Caption = 'Google Drive Queue Entries';
    // CardPageId
    Editable = true;
    PageType = List;
    SourceTable = "GDI Queue";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = all;
                    Editable = false;
                    Tooltip = 'Unique identifier of the record.';
                }
                field(MediaID; Rec.MediaID)
                {
                    ApplicationArea = all;
                    Editable = false;
                    Tooltip = 'The unique identifier of the related media.';
                }
                field(FileID; Rec.FileID)
                {
                    ApplicationArea = all;
                    Editable = false;
                    ToolTip = 'Unique Google Drive file identifier. Empty value means that the file was not synced with Google Drive.';
                }

                field(Method; Rec.Method)
                {
                    ApplicationArea = all;
                    Editable = false;
                    ToolTip = 'The caller method.';
                }
                field(Problem; Rec.Problem)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'The problem that occurred during the call. Undefined problem with handled status means no problems.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'The status of the problem that occurred during the call. Undefined problem with handled status means no problems.';
                }
                field(TempErrorValue; Rec.TempErrorValue)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'The description of the problem.';
                }
            }
        }
    }
}