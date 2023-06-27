page 50113 "GDI Media Info Card Part"
{
    ApplicationArea = All;
    Editable = false;
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
                    Editable = false;
                    ToolTip = 'You can set star rank of the media.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AssignStar)
            {
                ApplicationArea = all;
                Caption = 'Rate this Image';
                Image = "Action";
                ToolTip = 'Assign the star rating from 1 to 5 to the media.';

                trigger OnAction()
                var
                    SelectedOption: Integer;
                begin
                    SelectedOption := StrMenu(AssignStarStrMenuOptionsTxt, 1, AssignStarStrMenuTxt);
                    if SelectedOption <> 0 then begin
                        Rec.Validate(Stars, 6 - SelectedOption);
                        Rec.Modify(true);
                    end;
                end;
            }

        }
    }
    var
        AssignStarStrMenuTxt: Label 'Assign the star rating to the media.';
        AssignStarStrMenuOptionsTxt: Label '5,4,3,2,1';
}