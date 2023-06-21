table 50115 "Google Drive Link"
{
    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Description = 'Unique identifier.';
        }
        field(2; EntityTypeID; Integer)
        {
            Caption = 'Entity Type';
            Description = 'Identifier of the entity type. Table number by default.';
        }
        field(3; EntityID; Text[100])
        {
            Caption = 'Entity ID';
            Description = 'Identifier of the entity. Table entry code by default.';
        }
        field(4; MediaID; Integer)
        {
            Caption = 'Media ID';
            TableRelation = "Google Drive Media";
            ValidateTableRelation = true;
        }
        field(5; EntryNo; Integer)
        {
            Caption = 'No.';
            Description = 'Number of current media in collection for the current entity.';
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
        Link: Record "Google Drive Link";
    begin
        if ID = 0 then
            if Link.FindLast() then
                ID := Link.ID + 1
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