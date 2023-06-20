codeunit 50116 "Google Drive Error Handler"
{
    Description = 'Handles runtime errors. ';

    procedure HandleErrors(Method: enum GDMethod; ResponseText: Text): Boolean
    var
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        ErrorValue: Text;
        ErrorText: Text;
    begin
        if not ResponseJson.ReadFrom(ResponseText) then begin
            // TODO log JSON parsing warning
            if StrPos(ResponseText, Tokens.ErrorTok) > 0 then begin
                // TODO log error
                Error('%1 %2', Format(Method), ResponseText);
            end else
                exit(true);
        end;
        case (Method) of
            Method::Authorize, Method::PostFile, Method::PatchMetadata:
                ErrorValue := GoogleDriveJsonHelper.GetTextValueFromJson(responseJson, Tokens.ErrorTok); // can also fail
            Method::DeleteFile, Method::PatchFile:
                ErrorText := GoogleDriveJsonHelper.GetObjectValueFromJson(responseJson, Tokens.ErrorTok); // can also fail
            else
                ThrowNotImplementedErr();
        end;
        if (ErrorValue <> '') or (ErrorText <> '') then begin
            // TODO
            // parse and log error
            // make decision: to throw or to proceed
            Error('%1 %2', Format(Method), ResponseText);
        end;
        if Method = Method::PostFile then
            if GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.IdTok) = '' then
                Error('%1 %2', Format(Method), APICreateErr);

        exit(true);
    end;

    procedure ThrowAPICreateErr()
    begin
        Error(APICreateErr);
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
        APICreateErr: Label 'Unexpected error: response JSON does not contain a field "id". Please check recent Google Drive API updates.';
        JsonReadErr: Label 'Cannot read file %1 as json.';
        JsonStructureErr: Label 'Wrong json structure in %1. Please, check recent Google Drive API updates.';
        EvaluateFailErr: Label 'Failed to evaluate %1=%2 into %3 type.';
        FileNameMissingErr: Label 'File name was not specified.';
        FileIDMissingErr: Label 'File ID was not specified.';
        FileUploadErr: Label 'Cannot upload file %1 into stream.';
        NotImplementedErr: Label 'Not implemented.';
        ValueOutOfRangeErr: Label '%1 %2 is out of range [%3 .. %4]';
}