codeunit 50101 "Google Drive Mgt."
{
    Description = 'Manages Google Drive API calls and handles Google Drive Media.';

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
        SetupMgt: Codeunit "Google Drive Setup Mgt.";
        RequestHandler: Codeunit "Google Drive Request Handler";
        ErrorHandler: Codeunit "Google Drive Error Handler";
        QueueHandler: Codeunit "Google Drive Queue Handler";
        JsonHelper: Codeunit "Google Drive Json Helper";
        GDITokens: Codeunit "GDI Tokens";
        ResponseJson: JsonObject;
        Method: enum GDMethod;
        Problem: enum GDProblem;
        Status: enum GDQueueStatus;
        ResponseText: Text;
        ErrorValue: Text;
        FileID: Text;
        MediaID: Integer;
        QueueID: Integer;
    begin
        if FileName = '' then
            ErrorHandler.ThrowFileNameMissingErr();

        MediaID := CreateGoogleDriveMedia(IStream, FileName, '');
        QueueID := QueueHandler.CreateGoogleDriveQueue(Method::PostFile, Problem::Undefined, MediaID, '');
        Commit();

        SetupMgt.Authorize(Method::PostFile);
        SetupMgt.GetError(Method, Problem, ErrorValue);
        if ErrorValue <> '' then begin
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, '', ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := RequestHandler.PostFile(IStream);
        if ErrorHandler.ResponseHasError(Method::PostFile, ResponseText) then begin
            ErrorHandler.GetError(Method, Problem, ErrorValue);
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, '', ErrorValue);
            Commit();
            exit;
        end;

        ResponseJson.ReadFrom(ResponseText);
        JsonHelper.TryGetTextValueFromJson(FileID, ResponseJson, GDITokens.IdTok());
        if FileID = '' then begin
            QueueHandler.UpdateGoogleDriveQueue(
                QueueID, Status::"To Handle", Method::PostFile, Problem::MissingFileID, MediaID, '', ResponseText);
            Commit();
            exit;
        end;

        UpdateGoogleDriveMediaFileID(MediaID, FileID);
        QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::New, Method::PostFile, Problem::Undefined, MediaID, FileID, '');
        Commit();

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        if ErrorHandler.ResponseHasError(Method::PatchMetadata, ResponseText) then begin
            ErrorHandler.GetError(Method, Problem, ErrorValue);
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::Handled, Method::PostFile, Problem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    procedure Delete(MediaID: Integer)
    var
        GoogleDriveMedia: Record "Google Drive Media";
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        ErrorHandler: Codeunit "Google Drive Error Handler";
        QueueHandler: Codeunit "Google Drive Queue Handler";
        Method: enum GDMethod;
        Problem: enum GDProblem;
        Status: enum GDQueueStatus;
        ResponseText: Text;
        ErrorValue: Text;
        FileID: Text;
        QueueID: Integer;
    begin
        GoogleDriveMedia.Get(MediaID);
        FileID := GoogleDriveMedia.FileID;
        GoogleDriveMedia.Delete(true);
        if FileID = '' then begin
            QueueHandler.CreateGoogleDriveQueue(Status::"To Handle", Method::DeleteFile, Problem::MissingFileID, MediaID, '');
            Commit();
            exit;
        end;
        QueueID := QueueHandler.CreateGoogleDriveQueue(Method::DeleteFile, Problem::Undefined, MediaID, FileID);
        Commit();

        GoogleDriveSetupMgt.Authorize(Method::DeleteFile);
        GoogleDriveSetupMgt.GetError(Method, Problem, ErrorValue);
        if ErrorValue <> '' then begin
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := GoogleDriveRequestHandler.DeleteFile(FileID);
        if ErrorHandler.ResponseHasError(Method::DeleteFile, ResponseText) then begin
            ErrorHandler.GetError(Method, Problem, ErrorValue);
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::Handled, Method::DeleteFile, Problem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    procedure Get(var IStream: InStream; var ErrorText: Text; FileID: Text)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Method: enum GDMethod;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

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
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

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
        SetupMgt: Codeunit "Google Drive Setup Mgt.";
        RequestHandler: Codeunit "Google Drive Request Handler";
        ErrorHandler: Codeunit "Google Drive Error Handler";
        QueueHandler: Codeunit "Google Drive Queue Handler";
        Method: enum GDMethod;
        Problem: enum GDProblem;
        Status: enum GDQueueStatus;
        ResponseText: Text;
        ErrorValue: Text;
        FileID: Text;
        QueueID: Integer;
    begin
        if FileName = '' then
            ErrorHandler.ThrowFileNameMissingErr();

        if MediaID = 0 then
            ErrorHandler.ThrowFileIDMissingErr();

        UpdateGoogleDriveMedia(IStream, FileName, MediaID);
        FileID := GetGoogleDriveMediaFileID(MediaID);
        if FileID = '' then begin
            QueueHandler.CreateGoogleDriveQueue(Status::"To Handle", Method::PatchFile, Problem::MissingFileID, MediaID, '');
            Commit();
            exit;
        end;
        QueueID := QueueHandler.CreateGoogleDriveQueue(Method::PatchFile, Problem::Undefined, MediaID, FileID);
        Commit();

        SetupMgt.Authorize(Method::PatchFile);
        SetupMgt.GetError(Method, Problem, ErrorValue);
        if ErrorValue <> '' then begin
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := RequestHandler.PatchFile(IStream, FileID);
        if ErrorHandler.ResponseHasError(Method::PatchFile, ResponseText) then begin
            ErrorHandler.GetError(Method, Problem, ErrorValue);
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        if ErrorHandler.ResponseHasError(Method::PatchMetadata, ResponseText) then begin
            ErrorHandler.GetError(Method, Problem, ErrorValue);
            QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::"To Handle", Method, Problem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        QueueHandler.UpdateGoogleDriveQueue(QueueID, Status::Handled, Method::PatchFile, Problem::Undefined, MediaID, FileID, '');
        Commit();
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
        GDITokens: Codeunit "GDI Tokens";
    begin
        GoogleDriveMedia.Init();
        GoogleDriveMedia.Validate(FileID, FileID);
        GoogleDriveMedia.Validate(FileName, FileName);
        GoogleDriveMedia.FileContent.ImportStream(IStream, 'default', GDITokens.MimeTypeJpeg()); // TODO remove hardcode
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
        GDITokens: Codeunit "GDI Tokens";
    begin
        GoogleDriveMedia.Get(ID);
        GoogleDriveMedia.Validate(FileName, FileName);
        GoogleDriveMedia.FileContent.ImportStream(IStream, 'default', GDITokens.MimeTypeJpeg()); // TODO remove hardcode
        GoogleDriveMedia.Modify(true);
    end;

    var
        DialogTitleUploadTxt: Label 'File Upload';
}