table 50120 "Google Drive Queue"
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
        field(7; TempErrorValue; Text[2048])
        {
            Description = 'Temporary field till log is implemented';
        }
        field(8; FileID; Text[128])
        {
            Description = 'File ID copied from Google Drive Media';
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
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin
        if ID = 0 then
            if GoogleDriveQueue.FindLast() then
                ID := GoogleDriveQueue.ID + 1
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