table 50113 "GDI Media Stat"
{

    fields
    {
        field(1; MediaID; Integer)
        {
            Caption = 'Media ID';
            TableRelation = "GDI Media";
        }
        field(2; FileSize; Decimal)
        {
            Caption = 'File Size (MB)';
            Description = 'Specifies the file size in megabytes.';
            InitValue = 0.0;
        }
        field(3; ViewedByEntity; Integer)
        {
            Caption = 'Viewed (by entity)';
            Description = 'Specifies how many times the media was viewed for an entity.';
            InitValue = 0;
        }
        field(4; Stars; Integer)
        {
            Caption = 'Stars';
            Description = 'User ranked rating.';
            InitValue = 0;
        }
    }

    keys
    {
        key(PK; MediaID)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

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