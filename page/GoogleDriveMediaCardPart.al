page 50123 "Google Drive Media Card Part"
{
    ApplicationArea = All;
    DeleteAllowed = false;
    Editable = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Google Drive Media";
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
                    ShowCaption = false;
                    DrillDownPageId = "Google Drive Media Card";
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Download)
            {
                trigger OnAction()
                begin
                    Message('Download');
                end;
            }
            action(Replace)
            {
                trigger OnAction()
                begin
                    Message('Replace');
                end;
            }
            action(Delete)
            {
                trigger OnAction()
                begin
                    Message('Delete');
                end;
            }
        }
    }
}