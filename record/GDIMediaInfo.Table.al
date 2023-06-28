table 50113 "GDI Media Info"
{

    Caption = 'Google Drive Media Info';
    Description = 'Statistics for Google Drive Media. Required for maintaining the cache.';
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
        field(3; ViewedByEntity; Integer)
        {
            Caption = 'Viewed (by entity)';
            Description = 'Specifies how many times the media was viewed for an entity.';
            InitValue = 0;
            MinValue = 0;
        }
        field(4; Stars; Integer)
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
        field(10; Qty; Integer)
        {
            Description = 'Field to be able to use calcsums instead of count';
            InitValue = 1;
            MinValue = 1;
            MaxValue = 1;
        }
    }

    keys
    {
        key(PK; MediaID)
        {
            Clustered = true;
            SumIndexFields = FileSize, ViewedByEntity, Stars, Qty;
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