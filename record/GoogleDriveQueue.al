table 50122 "Google Drive Queue"
{
    Description = 'Entries for job queue.';
    fields
    {
        field(1; ID; Integer)
        {

        }
        field(2; MediaID; Integer)
        {
            TableRelation = "Google Drive Media";
        }
        field(3; ProblemType; enum ProblemType)
        {

        }
        field(4; ProblemStatus; enum ProblemStatus)
        {

        }
        field(5; ErrorText; Text[2048])
        {

        }

    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

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