table 50122 "Google Drive Queue"
{
    Description = 'Entries for the job queue.';
    fields
    {
        field(1; ID; Integer)
        {

        }
        field(2; MediaID; Integer)
        {
            TableRelation = "Google Drive Media";
        }
        field(3; Method; enum GDMethod)
        {
            InitValue = Undefined;
        }
        field(4; Problem; enum GDProblem)
        {
            InitValue = Undefined;
        }
        field(5; Status; enum GDQueueStatus)
        {
            InitValue = New;
        }
        field(6; Iteration; Integer)
        {
            InitValue = 0;
        }
    }

    keys
    {
        key(PK; ID)
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