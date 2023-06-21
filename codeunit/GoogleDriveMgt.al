codeunit 50101 "Google Drive Mgt."
{
    Description = 'Manages operations with Google Drive and related records.';

    procedure Create()
    var
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        IStream: InStream;
        ClientFileName: Text;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GoogleDriveErrorHandler.ThrowFileUploadErr(ClientFileName);

        Create(IStream, ClientFileName);
    end;

    procedure Create(var IStream: InStream; FileName: Text)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        Method: enum GDMethod;
        Problem: enum GDProblem;
        Status: enum GDQueueStatus;
        ErrorValue: Text;
        ResponseText: Text;
        FileID: Text;
        MediaID: Integer;
        QueueID: Integer;
    begin
        // TODO check Istream also (Length is available in runtime 11.0)
        if FileName = '' then
            GoogleDriveErrorHandler.ThrowFileNameMissingErr();

        MediaID := CreateGoogleDriveMedia(IStream, FileName, '');
        QueueID := CreateGoogleDriveQueue(Method::PostFile, Problem::Undefined, MediaID, '');
        Commit();

        GoogleDriveSetupMgt.Authorize(Method);
        GoogleDriveSetupMgt.GetError(Method, Problem, ErrorValue);
        if ErrorValue <> '' then begin
            UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, '', ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := GoogleDriveRequestHandler.PostFile(IStream);
        if GoogleDriveErrorHandler.ResponseHasError(Method::PostFile, ResponseText) then begin
            GoogleDriveErrorHandler.GetError(Method, Problem, ErrorValue);
            UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, '', ErrorValue);
            Commit();
            exit;
        end;

        ResponseJson.ReadFrom(ResponseText);
        GoogleDriveJsonHelper.TryGetTextValueFromJson(FileID, ResponseJson, Tokens.IdTok);
        if FileID = '' then begin
            UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method::PostFile, Problem::MissingFileID, MediaID, '', ResponseText);
            Commit();
            exit;
        end;
        UpdateGoogleDriveMediaFileID(MediaID, FileID);
        UpdateGoogleDriveQueue(QueueID, Status::New, Method::PostFile, Problem::Undefined, MediaID, FileID, '');
        Commit();

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        if GoogleDriveErrorHandler.ResponseHasError(Method::PatchMetadata, ResponseText) then begin
            GoogleDriveErrorHandler.GetError(Method, Problem, ErrorValue);
            UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;
        UpdateGoogleDriveQueue(QueueID, Status::Handled, Method::PostFile, Problem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    local procedure CreateGoogleDriveQueue(Method: enum GDMethod; Problem: enum GDProblem; MediaID: Integer; FileID: Text): Integer
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin
        GoogleDriveQueue.Init();
        GoogleDriveQueue.Validate(Method, Method);
        GoogleDriveQueue.Validate(Problem, Problem);
        GoogleDriveQueue.Validate(Status, GoogleDriveQueue.Status::New);
        GoogleDriveQueue.Validate(MediaID, MediaID);
        GoogleDriveQueue.Validate(FileID, FileID);
        GoogleDriveQueue.Validate(Iteration, 0);
        GoogleDriveQueue.Validate(TempErrorValue, '');
        GoogleDriveQueue.Insert(true);
        exit(GoogleDriveQueue.ID);
    end;

    local procedure UpdateGoogleDriveQueue(QueueID: Integer; Status: enum GDQueueStatus; Method: enum GDMethod; Problem: enum GDProblem; MediaID: Integer; FileID: Text; ErrorValue: Text)
    var
        GoogleDriveQueue: Record "Google Drive Queue";
    begin
        GoogleDriveQueue.Get(QueueID);
        GoogleDriveQueue.Validate(Method, Method);
        GoogleDriveQueue.Validate(Problem, Problem);
        GoogleDriveQueue.Validate(Status, Status);
        GoogleDriveQueue.Validate(MediaID, MediaID);
        GoogleDriveQueue.Validate(FileID, FileID);
        GoogleDriveQueue.Validate(Iteration, 0);
        GoogleDriveQueue.Validate(TempErrorValue, ErrorValue);
        GoogleDriveQueue.Modify(true);
    end;

    procedure Delete(MediaID: Integer)
    var
        GoogleDriveMedia: Record "Google Drive Media";
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        Method: enum GDMethod;
        ResponseJson: JsonObject;
        ResponseText: Text;
        ErrorText: Text;
        FileID: Text;
    begin
        GoogleDriveMedia.Get(MediaID);
        FileID := GoogleDriveMedia.FileID;
        GoogleDriveMedia.Delete(true); // delete record and all links
        Commit();

        if FileID = '' then begin // TODO add queue
            // GoogleDriveErrorHandler.HandleErrors(Method::DeleteFile, StrSubstNo('{"%1": {"%1": "%2"}}', Tokens.ErrorTok, 'MissingFileID'));
            GoogleDriveErrorHandler.FinalizeHandleErrors(Method::DeleteFile, MediaID, '');
            exit;
        end;

        GoogleDriveSetupMgt.Authorize(Method::DeleteFile);
        if not GoogleDriveErrorHandler.FinalizeHandleErrors(Method::DeleteFile, MediaID, FileID) then
            exit;
        ResponseText := GoogleDriveRequestHandler.DeleteFile(FileID);
        // GoogleDriveErrorHandler.HandleErrors(Method::DeleteFile, ResponseText);
    end;

    procedure Get(var IStream: InStream; var ErrorText: Text; FileID: Text)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Method: enum GDMethod;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr;

        GoogleDriveSetupMgt.Authorize(Method::GetFile);
        GoogleDriveRequestHandler.GetMedia(IStream, FileID);
        ErrorText := GoogleDriveRequestHandler.GetErrorText();
    end;

    procedure GetMetadata(FileID: Text): Text
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Method: enum GDMethod;
        ResponseText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr;

        GoogleDriveSetupMgt.Authorize(Method::GetMetadata);
        ResponseText := GoogleDriveRequestHandler.GetMetadata(FileID);
        exit(ResponseText);
        // TODO check ResponseText?
    end;

    procedure Update(MediaID: Integer)
    var
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        IStream: InStream;
        ClientFileName: Text;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GoogleDriveErrorHandler.ThrowFileUploadErr(ClientFileName);

        Update(IStream, ClientFileName, MediaID);
    end;

    procedure Update(var IStream: InStream; FileName: Text; MediaID: Integer)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        Method: enum GDMethod;
        ResponseJson: JsonObject;
        ResponseText: Text;
        FileID: Text;
    begin
        if MediaID = 0 then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        if FileName = '' then
            GoogleDriveErrorHandler.ThrowFileNameMissingErr();

        UpdateGoogleDriveMedia(IStream, FileName, MediaID);
        Commit();

        FileID := GetGoogleDriveMediaFileID(MediaID);
        if FileID = '' then begin
            // GoogleDriveErrorHandler.HandleErrors(Method::PatchFile, StrSubstNo('{"%1": {"%1": "%2"}}', Tokens.ErrorTok, 'MissingFileID'));
            GoogleDriveErrorHandler.FinalizeHandleErrors(Method::PatchFile, MediaID, '');
            exit;
        end;

        GoogleDriveSetupMgt.Authorize(Method::PatchFile);
        if not GoogleDriveErrorHandler.FinalizeHandleErrors(Method::PatchFile, MediaID, FileID) then
            exit;

        ResponseText := GoogleDriveRequestHandler.PatchFile(IStream, FileID);
        // GoogleDriveErrorHandler.HandleErrors(Method::PatchFile, ResponseText);

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        // GoogleDriveErrorHandler.HandleErrors(Method::PatchMetadata, ResponseText);
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Method: enum GDMethod;
        ResponseText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        // TODO check NewMetadata
        GoogleDriveSetupMgt.Authorize(Method::PatchMetadata);
        ResponseText := GoogleDriveRequestHandler.PatchMetadata(NewMetadata, FileID);
        exit(ResponseText);
        // TODO check ResponseText?
    end;

    local procedure CreateGoogleDriveMedia(IStream: InStream; FileName: Text; FileID: Text): Integer
    var
        GoogleDriveMedia: Record "Google Drive Media";
        Tokens: Codeunit "Google Drive API Tokens";
    begin
        GoogleDriveMedia.Init();
        GoogleDriveMedia.Validate(FileID, FileID);
        GoogleDriveMedia.Validate(FileName, FileName);
        GoogleDriveMedia.FileContent.ImportStream(IStream, 'default', Tokens.MimeTypeJpeg); // TODO remove hardcode
        GoogleDriveMedia.Insert(true);
        exit(GoogleDriveMedia.ID);
    end;

    local procedure GetGoogleDriveMediaFileID(MediaID: Integer): Text
    var
        GoogleDriveMedia: Record "Google Drive Media";
    begin
        if GoogleDriveMedia.Get(MediaID) then
            exit(GoogleDriveMedia.FileID);
        exit('');
    end;

    local procedure UpdateGoogleDriveMediaFileID(MediaID: Integer; FileID: Text)
    var
        GoogleDriveMedia: Record "Google Drive Media";
    begin
        GoogleDriveMedia.Get(MediaID);
        GoogleDriveMedia.Validate(FileID, FileID);
        GoogleDriveMedia.Modify(true);
    end;

    local procedure UpdateGoogleDriveMedia(IStream: InStream; FileName: Text; ID: Integer)
    var
        GoogleDriveMedia: Record "Google Drive Media";
        Tokens: Codeunit "Google Drive API Tokens";
    begin
        GoogleDriveMedia.Get(ID);
        GoogleDriveMedia.Validate(FileName, FileName);
        GoogleDriveMedia.FileContent.ImportStream(IStream, 'default', Tokens.MimeTypeJpeg); // TODO remove hardcode
        GoogleDriveMedia.Modify(true);
    end;

    var
        DialogTitleUploadTxt: Label 'File Upload';
}