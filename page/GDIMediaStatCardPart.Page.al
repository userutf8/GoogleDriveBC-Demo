page 50113 "GDI Media Stat Card Part"
{
    ApplicationArea = All;
    PageType = CardPart;
    SourceTable = "GDI Media Info";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Default)
            {
                ShowCaption = false;
                field(FileSize; Rec.FileSize)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'File size in megabytes.';
                }
                field(Viewed; Rec.ViewedByEntity)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many times the media was viewed for an entity.';
                }
                field(Stars; Rec.Stars)
                {
                    ApplicationArea = All;
                    ToolTip = 'You can set star rank of the media.';
                }
            }
        }
    }
}