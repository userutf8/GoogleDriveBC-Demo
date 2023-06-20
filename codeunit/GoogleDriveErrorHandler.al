codeunit 50111 "Google Drive Error Handler"
{
    Description = 'Handles runtime errors and queue. ';

    procedure HandleErrors(Method: enum GDMethod; ResponseText: Text): Boolean
    var
        GoogleDriveQueue: Record "Google Drive Queue";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        ErrorValue: Text;
        ErrorText: Text;
    begin
        // TODO bad function name (bad design)
        if not ResponseJson.ReadFrom(ResponseText) then begin
            if StrPos(ResponseText, Tokens.ErrorTok) > 0 then // TODO add warning
                Error('%1 %2', Format(Method), ResponseText);
            exit(true); // TODO questionable: we got weird input, should we procced?
        end;
        case (Method) of
            Method::Authorize, Method::PostFile, Method::PatchMetadata:
                ErrorValue := GoogleDriveJsonHelper.GetTextValueFromJson(responseJson, Tokens.ErrorTok); // can also fail
            Method::DeleteFile, Method::PatchFile: // TODO: authorize can be called from patch and delete, so this approach is meh
                ErrorText := GoogleDriveJsonHelper.GetObjectValueFromJson(responseJson, Tokens.ErrorTok); // can also fail
            else
                ThrowNotImplementedErr();
        end;
        ErrorValue := CalcErrorValue(ErrorValue, ErrorText);
        if ErrorValue = '' then
            exit(true);

        if Method = Method::Authorize then
            Error('%1 Error: %2', Format(Method), ErrorValue);

        GoogleDriveQueue.Init();
        GoogleDriveQueue.Validate(Method, Method);
        GoogleDriveQueue.Validate(Problem, CalcProblem(Method, ErrorValue));
        GoogleDriveQueue.Validate(Status, GoogleDriveQueue.Status::New);
        GoogleDriveQueue.Validate(MediaID, 0);
        GoogleDriveQueue.Validate(Iteration, 0);
        GoogleDriveQueue.Validate(TempErrorValue, ErrorValue);
        GoogleDriveQueue.Insert(true);
        Commit();

        exit(false);
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

    local procedure CalcErrorValue(ErrorValue: Text; ErrorText: Text): Text
    begin
        // TODO process error text, extract error value >
        if ErrorValue = '' then
            exit(ErrorText);
        exit(ErrorValue);
    end;

    local procedure CalcProblem(Method: enum GDMethod; ErrorValue: Text): enum GDProblem
    var
        Problem: enum GDProblem;
    begin
        case (ErrorValue) of
            '0':
                exit(Problem::Timeout);
            Format(Problem::MissingFileID):
                exit(Problem::MissingFileID);
        end;
        exit(Problem::Undefined);
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
}