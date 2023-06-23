codeunit 50112 "GDI Queue Handler"
{

    procedure Create(GDIStatus: Enum "GDI Status"; GDIMethod: Enum "GDI Method"; GDIProblem: Enum "GDI Problem"; MediaID: Integer; FileID: Text): Integer
    var
        GDIQueue: Record "GDI Queue";
    begin
        GDIQueue.Get(Create(GDIMethod, GDIProblem, MediaID, FileID));
        GDIQueue.Validate(Status, GDIStatus);
        GDIQueue.Modify(true);
    end;

    procedure Create(GDIMethod: Enum "GDI Method"; GDIProblem: Enum "GDI Problem"; MediaID: Integer; FileID: Text): Integer
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

    procedure Update(QueueID: Integer; GDIStatus: Enum "GDI Status"; GDIMethod: Enum "GDI Method"; GDIProblem: Enum "GDI Problem"; MediaID: Integer; FileID: Text; ErrorValue: Text)
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

}