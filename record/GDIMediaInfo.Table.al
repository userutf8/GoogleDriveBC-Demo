table 50113 "GDI Media Info"
{
    Caption = 'Google Drive Media Info';
    Description = 'Statistics for Google Drive Media. Required for maintaining the cache.';
    DataClassification = CustomerContent;
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
            MinValue = 0.0;
            // MaxValue = 350.0;
        }
        field(3; ViewedByEntity; BigInteger)
        {
            Caption = 'Viewed (by entity)';
            Description = 'Specifies how many times the media was viewed for an entity.';
            InitValue = 0L;
            MinValue = 0L;
        }
        field(4; Stars; BigInteger)
        {
            Caption = 'Stars';
            Description = 'User ranked rating.';
            InitValue = 0;
            MinValue = 0;
            MaxValue = 5;
        }
        field(5; Rank; Integer)
        {
            Caption = 'Rank';
            Description = 'Rank for cache cleaning';
            InitValue = 0;
            MinValue = 0;
            MaxValue = 100;
        }
        field(6; LastViewedByEntity; DateTime)
        {
            Caption = 'Last viewed (by entity)';
        }
    }

    keys
    {
        key(PK; MediaID)
        {
            Clustered = true;
            SumIndexFields = FileSize, ViewedByEntity, Stars;
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