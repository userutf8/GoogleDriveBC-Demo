table 50115 "GDI Link"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Description = 'Unique identifier.';
        }
        field(2; EntityTypeID; Enum "GDI Entity Type")
        {
            Caption = 'Entity Type';
            Description = 'Identifier of the entity type. Table number by default.';
        }
        field(3; EntityID; Text[100])
        {
            Caption = 'Entity ID';
            Description = 'Identifier of the entity. Record code by default.';
        }
        field(4; MediaID; Integer)
        {
            Caption = 'Media ID';
            TableRelation = "GDI Media";
            ValidateTableRelation = true;
        }
        field(5; EntryNo; Integer)
        {
            Caption = 'No.';
            Description = 'Number of the current media in the collection for the current entity.';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(EntityKey; EntityTypeID, EntityID, EntryNo)
        {
            Description = 'Required for collection pickups.';
        }
    }

    trigger OnInsert()
    var
        GDILink: Record "GDI Link";
    begin
        if ID = 0 then
            if GDILink.FindLast() then
                ID := GDILink.ID + 1
            else
                ID := 1;
    end;

    trigger OnModify()
    begin
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
    end;
}