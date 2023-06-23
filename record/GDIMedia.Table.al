table 50110 "GDI Media"
{
    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Description = 'Unique identifier generated on record insert.';
        }
        field(2; FileID; Text[128])
        {
            Caption = 'File ID';
            Description = 'Unique Google Drive file identifier. Max length is 44 (not documented).';
        }
        field(3; FileName; Text[1024])
        {
            Caption = 'File Name';
            Description = 'Name of the file uploaded to BC from user device.';
        }

        field(4; FileContent; Media)
        {
            Caption = 'File';
            Description = 'File media itself. Contains link to Tenant Media record.';
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
        GDIMedia: Record "GDI Media";
    begin
        if ID = 0 then
            if GDIMedia.FindLast() then
                ID := GDIMedia.ID + 1
            else
                ID := 1;
    end;

    trigger OnModify()
    begin
        if FileID <> xRec.FileID then
            Error(FileIDModifyErr);
    end;

    trigger OnDelete()
    var
        GDILink: Record "GDI Link";
    begin
        GDILink.SetRange(MediaID, ID);
        GDILink.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(RenameErr);
    end;

    var
        RenameErr: Label 'Cannot rename the record.';
        FileIDModifyErr: Label 'Cannot modify File ID.';
}