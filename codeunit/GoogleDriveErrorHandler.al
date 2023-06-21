codeunit 50111 "Google Drive Error Handler"
{
    Description = 'Handles runtime errors and queue. ';

    procedure GetError(var Method: enum GDMethod; var Problem: enum GDProblem; var ErrorValue: Text)
    begin
        Method := CurrentMethod;
        Problem := CurrentProblem;
        ErrorValue := CurrentErrorValue;
    end;

    procedure ResponseHasError(Method: enum GDMethod; ResponseText: Text): Boolean
    var
        GoogleDriveQueue: Record "Google Drive Queue";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        Problem: Enum GDProblem;
        ErrorValue: Text;
        ErrorText: Text;
    begin
        ClearError();
        ClearLastError();
        If ResponseText = '' then
            exit(false); // no errors

        if not ResponseJson.ReadFrom(ResponseText) then begin
            LogError(Problem::JsonRead, Method, ResponseText);
            ClearLastError();
            exit(true); // json parsing is an error
        end;


        if GoogleDriveJsonHelper.GetErrorValueFromJson(ErrorValue, ResponseJson) then begin
            ClearLastError();
            if Method = Method::Authorize then
                Error('%1 Error: %2', Format(Method), ErrorValue);

            case (ErrorValue) of
                '0':
                    Problem := Problem::Timeout;
                Format(Problem::JsonRead):
                    Problem := Problem::JsonRead;
                Format(Problem::MissingFileID):
                    Problem := Problem::MissingFileID;
                else
                    Problem := Problem::Undefined;
            end;
            if Problem = Problem::Undefined then
                ErrorValue := ResponseText;
            LogError(Problem, Method, ErrorValue);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ClearError()
    begin
        CurrentProblem := CurrentProblem::Undefined;
        CurrentMethod := CurrentMethod::Undefined;
        Clear(CurrentErrorValue);
    end;

    local procedure LogError(Problem: enum GDProblem; Method: Enum GDMethod; ErrorValue: Text)
    begin
        ClearError();
        CurrentProblem := Problem;
        CurrentMethod := Method;
        CurrentErrorValue := ErrorValue;
    end;

    procedure FinalizeHandleErrors(Method: enum GDMethod; MediaID: Integer; FileID: Text): Boolean
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin



        // TODO bad function name (bad design)
        If MediaID = 0 then
            Error(ParameterMissingErr, GoogleDriveQueue.FieldName(MediaID));

        // TODO: redo all, as there can be several records like that
        GoogleDriveQueue.SetRange(Status, GoogleDriveQueue.Status::New);
        GoogleDriveQueue.SetRange(Method, Method);
        if GoogleDriveQueue.IsEmpty then
            exit(true); // no tracked problems

        GoogleDriveQueue.FindFirst();
        // TODO: here the top problem will be that with new approach we can lose info about FileID.
        // so we need to store FileID in Queue
        if Method = Method::DeleteFile then
            GoogleDriveQueue.MediaID := MediaID
        else
            GoogleDriveQueue.Validate(MediaID, MediaID);
        GoogleDriveQueue.Validate(FileID, FileID);
        GoogleDriveQueue.Validate(Status, GoogleDriveQueue.Status::"To Handle");
        GoogleDriveQueue.Modify(true);
        Commit();

        exit(false); // problem is tracked
    end;

    procedure ThrowJsonReadErr(FileName: Text)
    begin
        Error(JsonReadErr, FileName);
    end;

    procedure ThrowJsonStructureErr(FileName: Text)
    begin
        Error(JsonStructureErr, FileName);
    end;

    procedure ThrowEvaluateError(StringName: Text; StringValue: Text; ToTypeName: Text)
    begin
        Error(EvaluateFailErr, StringName, StringValue, ToTypeName);
    end;

    procedure ThrowFileNameMissingErr()
    begin
        Error(FileNameMissingErr);
    end;

    procedure ThrowFileIDMissingErr()
    begin
        Error(FileIDMissingErr);
    end;

    procedure ThrowFileUploadErr(FileName: Text)
    begin
        Error(FileUploadErr, FileName);
    end;

    procedure ThrowNotImplementedErr()
    begin
        Error(NotImplementedErr);
    end;

    procedure ThrowValueOutOfRange(Name: Text; Val: Text; LowMargin: Text; HighMargin: Text)
    begin
        Error(ValueOutOfRangeErr, Name, Val, LowMargin, HighMargin);
    end;

    var
        JsonReadErr: Label 'Cannot read file %1 as json.';
        JsonStructureErr: Label 'Wrong json structure in %1. Please, check recent Google Drive API updates.';
        EvaluateFailErr: Label 'Failed to evaluate %1=%2 into %3 type.';
        FileNameMissingErr: Label 'File name was not specified.';
        FileIDMissingErr: Label 'File ID was not specified.';
        FileUploadErr: Label 'Cannot upload file %1 into stream.';
        NotImplementedErr: Label 'Not implemented.';
        ParameterMissingErr: Label '%1 must be specified.';
        ValueOutOfRangeErr: Label '%1 %2 is out of range [%3 .. %4]';
        CurrentProblem: enum GDProblem;
        CurrentMethod: enum GDMethod;
        CurrentErrorValue: text;
}