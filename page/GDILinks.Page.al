page 50115 "GDI Links"
{
    AboutText = 'You can add, modify and delete links between Business Central entities and Google Drive files.';
    AboutTitle = 'Google Drive Media Links';
    AdditionalSearchTerms = 'Gallery, Google, Drive, Image, Media, Picture';
    ApplicationArea = All;
    Caption = 'Google Drive Media Links';
    CardPageId = "GDI Link Card";
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    MultipleNewLines = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "GDI Link";
    UsageCategory = Lists;

    layout
    {

        area(Content)
        {
            repeater(Default)
            {
                ShowCaption = false;

                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifier of the record.';
                    Editable = false;
                }

                field(EntityTypeID; Rec.EntityTypeID)
                {
                    ApplicationArea = All;
                    Tooltip = 'Identifier of the entity type. Table number by default.';
                    Width = 10;
                }
                field(EntityID; Rec.EntityID)
                {
                    ApplicationArea = All;
                    Tooltip = 'Identifier of the entity. Record code by default.';
                    Width = 40;
                }
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of the current media in the collection for the current entity.';
                }
                field(MediaID; Rec.MediaID)
                {
                    ApplicationArea = All;
                    Tooltip = 'Identifier of the related media.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GDIMedia: Record "GDI Media";
                        GDIMediaPage: Page "GDI Media";
                    begin
                        GDIMediaPage.SetRecord(GDIMedia);
                        GDIMediaPage.RunModal();
                        GDIMediaPage.GetRecord(GDIMedia);
                        Rec.MediaID := GDIMedia.ID;
                    end;

                }
            }
        }
        area(Factboxes)
        {
            part(Picture; "GDI Media Card Part")
            {
                ApplicationArea = All;
                Caption = 'Image';
                Visible = true;
                SubPageLink = ID = field(MediaID);
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.EntityTypeID := Enum::"GDI Entity Type".FromInteger(CurrentEntityTypeID);
        Rec.EntityID := CopyStr(CurrentEntityID, 1, MaxStrLen(Rec.EntityID));
    end;

    procedure SetEntity(NewEntityTypeID: Integer; NewEntityID: Text)
    begin
        // required for making new links
        CurrentEntityTypeID := NewEntityTypeID;
        CurrentEntityID := NewEntityID;
    end;

    var
        // required for making new links
        CurrentEntityTypeID: Integer;
        CurrentEntityID: Text;
}