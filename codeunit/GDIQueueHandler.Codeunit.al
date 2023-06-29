codeunit 50112 "GDI Queue Handler"
{
    trigger OnRun()
    begin
        HandleQueue();
    end;

    procedure Create(GDIStatus: Enum "GDI Status"; GDIMethod: Enum "GDI Method"; GDIProblem: Enum "GDI Problem";
        MediaID: Integer; FileID: Text): Integer
    var
        GDIQueue: Record "GDI Queue";
    begin
        GDIQueue.Get(Create(GDIMethod, GDIProblem, MediaID, FileID));
        GDIQueue.Validate(Status, GDIStatus);
        GDIQueue.Modify(true);
    end;

    procedure Create(GDIMethod: Enum "GDI Method"; GDIProblem: Enum "GDI Problem";
        MediaID: Integer; FileID: Text): Integer
    var
        GDIQueue: Record "GDI Queue";
    begin
        GDIQueue.Init();
        GDIQueue.Validate(Method, GDIMethod);
        GDIQueue.Validate(Problem, GDIProblem);
        GDIQueue.Validate(Status, GDIQueue.Status::New);
        GDIQueue.MediaID := MediaID; // validation will fail when DeleteFile is called
        GDIQueue.Validate(FileID, FileID);
        GDIQueue.Validate(Iteration, 0);
        GDIQueue.Validate(TempErrorValue, '');
        GDIQueue.Insert(true);
        exit(GDIQueue.ID);
    end;

    procedure HandleQueue()
    var
        GDIQueue: Record "GDI Queue";
        GDIMediaMgt: Codeunit "GDI Media Mgt.";
        ExcludeFilter: Text;
        StartDateTime: DateTime;
        MaxDuration: Duration;
    begin
        if GDIQueue.IsEmpty then
            exit;

        DeleteAllHandled();
        Commit();

        StartDateTime := CurrentDateTime;
        MaxDuration := 100000; // 100 seconds
        ExcludeFilter := '';
        repeat
            GDIQueue.Reset();
            GDIQueue.SetRange(Status, GDIQueue.Status::"To Handle");
            GDIQueue.SetFilter(MediaID, ExcludeFilter); // exclude all processed once
            if GDIQueue.IsEmpty() then
                break;

            GDIQueue.FindLast();
            GDIQueue.SetRange(MediaID, GDIQueue.MediaID);
            GDIQueue.SetRange(FileID, GDIQueue.FileID);
            GDIQueue.ModifyAll(Status, GDIQueue.Status::Handled);
            UpdateExcludeFilter(ExcludeFilter, GDIQueue.MediaID);
            // If file was not yet uploaded to Google Drive or was deleted from Google Drive manually by user
            if (GDIQueue.FileID = '') or (GDIQueue.Problem = GDIQueue.Problem::NotFound) then begin
                if GDIQueue.Method in [GDIQueue.Method::PatchFile, GDIQueue.Method::PatchMetadata] then
                    GDIQueue.Method := GDIQueue.Method::PostFile;
                if GDIQueue.Method = GDIQueue.Method::DeleteFile then
                    GDIQueue.Status := GDIQueue.Status::Handled;
            end;

            if GDIQueue.Status <> GDIQueue.Status::Handled then
                case GDIQueue.Method of
                    GDIQueue.Method::DeleteFile:
                        GDIMediaMgt.DeleteFromGoogleDrive(GDIQueue.MediaID, GDIQueue.FileID);
                    GDIQueue.Method::PatchMetadata:
                        GDIMediaMgt.PatchMetadata('TODO', GDIQueue.FileID); //todo: patch metadata doesn't know how to create queue yet
                    GDIQueue.Method::PatchFile:
                        GDIMediaMgt.UpdateOnGoogleDrive(GDIQueue.MediaID);
                    GDIQueue.Method::PostFile:
                        GDIMediaMgt.CreateOnGoogleDrive(GDIQueue.MediaID);
                end;
            Commit();

        until CurrentDateTime - StartDateTime >= MaxDuration;
    end;

    procedure Update(QueueID: Integer; GDIStatus: Enum "GDI Status"; GDIMethod: Enum "GDI Method"; GDIProblem: Enum "GDI Problem";
        MediaID: Integer; FileID: Text; ErrorValue: Text)
    var
        GDIQueue: Record "GDI Queue";
    begin
        GDIQueue.Get(QueueID);
        GDIQueue.Validate(Method, GDIMethod);
        GDIQueue.Validate(Problem, GDIProblem);
        GDIQueue.Validate(Status, GDIStatus);
        GDIQueue.MediaID := MediaID; // validation will fail when DeleteFile is called
        GDIQueue.Validate(FileID, FileID);
        GDIQueue.Validate(Iteration, 0);
        GDIQueue.Validate(TempErrorValue, ErrorValue);
        GDIQueue.Modify(true);
    end;

    local procedure DeleteAllHandled()
    var
        GDIQueue: Record "GDI Queue";
    begin
        GDIQueue.SetRange(Status, GDIQueue.Status::Handled);
        GDIQueue.DeleteAll();
    end;

    local procedure UpdateExcludeFilter(var ExcludeFilter: Text; MediaID: Integer)
    begin
        if ExcludeFilter = '' then
            ExcludeFilter := '<>'
        else
            ExcludeFilter += '&<>';
        ExcludeFilter += Format(MediaID);
    end;

}