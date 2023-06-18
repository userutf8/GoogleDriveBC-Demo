codeunit 50116 "Google Drive Error Handler"
{
    Description = 'Handles runtime errors. ';

    procedure HandleErrors(Caller: Text; ResponseText: Text): Boolean
    var
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        ErrorValue: Text;
        ErrorText: Text;
    begin
        if not ResponseJson.ReadFrom(ResponseText) then begin
            // TODO log JSON parsing warning
            if StrPos(ResponseText, 'error') > 0 then begin
                // TODO log error
                Error('%1 %2', Caller, ResponseText);
            end else
                exit(true);
        end;
        case (Caller) of
            Tokens.AuthorizeLbl, Tokens.PostFileLbl, Tokens.PatchMetadataLbl:
                ErrorValue := GoogleDriveJsonHelper.GetTextValueFromJson(responseJson, Tokens.ErrorTok); // can also fail
            Tokens.DeleteFileLbl, Tokens.PatchFileLbl:
                ErrorText := GoogleDriveJsonHelper.GetObjectValueFromJson(responseJson, Tokens.ErrorTok); // can also fail
            else
                Error(NotImplementedErr);
        end;
        if (ErrorValue <> '') or (ErrorText <> '') then begin
            // TODO
            // log error
            // parse error
            // make decision to throw error or to proceed
            // for example if create returns error, then cannot proceed and have to check garbage in case of timeouts
            // if delete cannot find file, then can safely proceed
            // if get returns not found then it's also okay for get
            Error('%1 %2', Caller, ResponseText);
        end;
        if Caller = Tokens.PostFileLbl then
            if GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.IdTok) = '' then
                Error('%1 %2', Caller, APICreateErr);

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


    var
        APICreateErr: Label 'Unexpected error: response JSON does not contain a field "id". Please check recent Google Drive API updates.';
        JsonReadErr: Label 'Cannot read file %1 as json.';
        JsonStructureErr: Label 'Wrong json structure in %1. Please, check recent Google Drive API updates.';
        FileNameMissingErr: Label 'File name was not specified.';
        FileIDMissingErr: Label 'File ID was not specified.';
        FileUploadErr: Label 'Cannot upload file %1 into stream.';
        NotImplementedErr: Label 'Not implemented.';
}