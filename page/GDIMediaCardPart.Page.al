page 50112 "GDI Media Card Part"
{
    ApplicationArea = All;
    DeleteAllowed = false;
    Editable = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "GDI Media";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group("Image")
            {
                ShowCaption = false;
                field("Media"; Rec.FileContent)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    DrillDownPageId = "GDI Media Card";
                }
            }
        }
    }
}