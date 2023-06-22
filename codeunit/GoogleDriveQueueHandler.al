codeunit 50112 "Google Drive Queue Handler"
{

    procedure CreateGoogleDriveQueue(Status: enum GDQueueStatus; Method: enum GDMethod; Problem: enum GDProblem; MediaID: Integer; FileID: Text): Integer
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin
        GoogleDriveQueue.Get(CreateGoogleDriveQueue(Method, Problem, MediaID, FileID));
        GoogleDriveQueue.Validate(Status, Status);
        GoogleDriveQueue.Modify(true);
    end;

    procedure CreateGoogleDriveQueue(Method: enum GDMethod; Problem: enum GDProblem; MediaID: Integer; FileID: Text): Integer
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin
        GoogleDriveQueue.Init();
        GoogleDriveQueue.Validate(Method, Method);
        GoogleDriveQueue.Validate(Problem, Problem);
        GoogleDriveQueue.Validate(Status, GoogleDriveQueue.Status::New);
        GoogleDriveQueue.MediaID := MediaID; // validation will fail when DeleteFile is called
        GoogleDriveQueue.Validate(FileID, FileID);
        GoogleDriveQueue.Validate(Iteration, 0);
        GoogleDriveQueue.Validate(TempErrorValue, '');
        GoogleDriveQueue.Insert(true);
        exit(GoogleDriveQueue.ID);
    end;

    procedure UpdateGoogleDriveQueue(QueueID: Integer; Status: enum GDQueueStatus; Method: enum GDMethod; Problem: enum GDProblem; MediaID: Integer; FileID: Text; ErrorValue: Text)
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin
        GoogleDriveQueue.Get(QueueID);
        GoogleDriveQueue.Validate(Method, Method);
        GoogleDriveQueue.Validate(Problem, Problem);
        GoogleDriveQueue.Validate(Status, Status);
        GoogleDriveQueue.MediaID := MediaID; // validation will fail when DeleteFile is called
        GoogleDriveQueue.Validate(FileID, FileID);
        GoogleDriveQueue.Validate(Iteration, 0);
        GoogleDriveQueue.Validate(TempErrorValue, ErrorValue);
        GoogleDriveQueue.Modify(true);
    end;

}