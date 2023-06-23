table 50120 "GDI Queue"
{
    Description = 'Entries for the job queue.';
    fields
    {
        field(1; ID; Integer)
        {

        }
        field(2; MediaID; Integer)
        {
            TableRelation = "GDI Media";
        }
        field(3; Method; enum "GDI Method")
        {
            InitValue = Undefined;
        }
        field(4; Problem; enum "GDI Problem")
        {
            InitValue = Undefined;
        }
        field(5; Status; enum "GDI Status")
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
        GDIQueue: Record "GDI Queue";
    begin
        if ID = 0 then
            if GDIQueue.FindLast() then
                ID := GDIQueue.ID + 1
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