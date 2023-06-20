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
                    ApplicationArea = All;
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
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Message('Download');
                end;
            }
            action(Replace)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Message('Replace');
                end;
            }
            action(Delete)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Message('Delete');
                end;
            }
        }
    }
}