Page 50120 "Google Drive Queue"
{
    ApplicationArea = all;
    Caption = 'Google Drive Queue Entries';
    // CardPageId
    Editable = true;
    PageType = List;
    SourceTable = "Google Drive Queue";
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
                }
                field(MediaID; Rec.MediaID)
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field(FileID; Rec.FileID)
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field(Method; Rec.Method)
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field(Problem; Rec.Problem)
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field(Iteration; Rec.Iteration)
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field(TempErrorValue; Rec.TempErrorValue)
                {
                    ApplicationArea = all;
                    Editable = true;
                }
            }
        }
    }
}