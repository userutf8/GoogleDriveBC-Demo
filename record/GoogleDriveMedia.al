table 50120 "Google Drive Media"
{
    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Description = 'Unique Identifier.';
        }
        field(2; FileID; Text[128])
        {
            Caption = 'File ID';
            Description = 'Unique Google Drive file identifier. Max length is said to be 44.';
        }
        field(3; FileName; Text[1024])
        {
            Caption = 'File Name';
            Description = 'Name of the file. Matches file name on disk.';
        }

        field(4; FileContent; Media)
        {
            Caption = 'File';
            Description = 'File media.';
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
        GoogleDriveMedia: Record "Google Drive Media";
    begin
        if ID = 0 then begin
            if GoogleDriveMedia.FindLast() then
                ID := GoogleDriveMedia.ID + 1
            else
                ID := 1;
        end;
    end;

    trigger OnModify()
    begin
        if FileID <> xRec.FileID then
            Error(FileIDModifyErr);
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin
        Error(RenameErr);
    end;

    var
        RenameErr: Label 'Cannot rename the record.';
        FileIDModifyErr: Label 'Cannot modify File ID.';
}