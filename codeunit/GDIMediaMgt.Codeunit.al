codeunit 50101 "GDI Media Mgt."
{
    Description = 'Manages Google Drive API calls and handles Google Drive Media.';

    procedure Create()
    var
        GDIErrorHandler: Codeunit "GDI Error Handler";
        IStream: InStream;
        ClientFileName: Text;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GDIErrorHandler.ThrowFileUploadErr(ClientFileName);

        Create(IStream, ClientFileName);
    end;

    procedure Create(var IStream: InStream; FileName: Text)
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIQueueHandler: Codeunit "GDI Queue Handler";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDITokens: Codeunit "GDI Tokens";
        ResponseJson: JsonObject;
        GDIMethod: Enum "GDI Method";
        GDIProblem: Enum "GDI Problem";
        GDIStatus: Enum "GDI Status";
        ResponseText: Text;
        ErrorValue: Text;
        FileID: Text;
        MediaID: Integer;
        QueueID: Integer;
    begin
        if FileName = '' then
            GDIErrorHandler.ThrowFileNameMissingErr();

        MediaID := CreateGoogleDriveMedia(IStream, FileName, '');
        QueueID := GDIQueueHandler.Create(GDIMethod::PostFile, GDIProblem::Undefined, MediaID, '');
        Commit();

        GDISetupMgt.Authorize(GDIMethod::PostFile);
        GDISetupMgt.GetError(GDIMethod, GDIProblem, ErrorValue);
        if ErrorValue <> '' then begin
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, '', ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := GDIRequestHandler.PostFile(IStream);
        if GDIErrorHandler.ResponseHasError(GDIMethod::PostFile, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, '', ErrorValue);
            Commit();
            exit;
        end;

        ResponseJson.ReadFrom(ResponseText);
        GDIJsonHelper.TryGetTextValueFromJson(FileID, ResponseJson, GDITokens.IdTok());
        if FileID = '' then begin
            GDIQueueHandler.Update(
                QueueID, GDIStatus::"To Handle", GDIMethod::PostFile, GDIProblem::MissingFileID, MediaID, '', ResponseText);
            Commit();
            exit;
        end;

        UpdateGoogleDriveMediaFileID(MediaID, FileID);
        GDIQueueHandler.Update(QueueID, GDIStatus::New, GDIMethod::PostFile, GDIProblem::Undefined, MediaID, FileID, '');
        Commit();

        ResponseText := PatchMetadata(StrSubstNo(SimpleJsonTxt, GDITokens.Name(), FileName), FileID);
        if GDIErrorHandler.ResponseHasError(GDIMethod::PatchMetadata, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        GDIQueueHandler.Update(
            QueueID, GDIStatus::Handled, GDIMethod::PostFile, GDIProblem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    procedure Delete(MediaID: Integer)
    var
        GDIMedia: Record "GDI Media";
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIQueueHandler: Codeunit "GDI Queue Handler";
        GDIMethod: Enum "GDI Method";
        GDIProblem: Enum "GDI Problem";
        GDIStatus: Enum "GDI Status";
        ResponseText: Text;
        ErrorValue: Text;
        FileID: Text;
        QueueID: Integer;
    begin
        GDIMedia.Get(MediaID);
        FileID := GDIMedia.FileID;
        GDIMedia.Delete(true);
        if FileID = '' then begin
            GDIQueueHandler.Create(GDIStatus::Handled, GDIMethod::DeleteFile, GDIProblem::MissingFileID, MediaID, '');
            Commit();
            exit;
        end;
        QueueID := GDIQueueHandler.Create(GDIMethod::DeleteFile, GDIProblem::Undefined, MediaID, FileID);
        Commit();

        GDISetupMgt.Authorize(GDIMethod::DeleteFile);
        GDISetupMgt.GetError(GDIMethod, GDIProblem, ErrorValue);
        if ErrorValue <> '' then begin
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := GDIRequestHandler.DeleteFile(FileID);
        if GDIErrorHandler.ResponseHasError(GDIMethod::DeleteFile, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        GDIQueueHandler.Update(QueueID, GDIStatus::Handled, GDIMethod::DeleteFile, GDIProblem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    procedure Get(var IStream: InStream; var ErrorText: Text; FileID: Text)
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIMethod: Enum "GDI Method";
    begin
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        GDISetupMgt.Authorize(GDIMethod::GetFile);
        GDIRequestHandler.GetMedia(IStream, FileID);
        ErrorText := GDIRequestHandler.GetErrorText();
    end;

    procedure GetMetadata(FileID: Text): Text
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIMethod: Enum "GDI Method";
        ResponseText: Text;
    begin
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        GDISetupMgt.Authorize(GDIMethod::GetMetadata);
        ResponseText := GDIRequestHandler.GetMetadata(FileID);
        exit(ResponseText);
        // TODO check ResponseText?
    end;

    procedure Update(MediaID: Integer)
    var
        GDIErrorHandler: Codeunit "GDI Error Handler";
        IStream: InStream;
        ClientFileName: Text;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GDIErrorHandler.ThrowFileUploadErr(ClientFileName);

        Update(IStream, ClientFileName, MediaID);
    end;

    procedure Update(var IStream: InStream; FileName: Text; MediaID: Integer)
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIQueueHandler: Codeunit "GDI Queue Handler";
        GDITokens: Codeunit "GDI Tokens";
        GDIMethod: Enum "GDI Method";
        GDIProblem: Enum "GDI Problem";
        GDIStatus: Enum "GDI Status";
        ResponseText: Text;
        ErrorValue: Text;
        FileID: Text;
        QueueID: Integer;
    begin
        if FileName = '' then
            GDIErrorHandler.ThrowFileNameMissingErr();

        if MediaID = 0 then
            GDIErrorHandler.ThrowFileIDMissingErr();

        UpdateGoogleDriveMedia(IStream, FileName, MediaID);
        FileID := GetGoogleDriveMediaFileID(MediaID);
        if FileID = '' then begin
            GDIQueueHandler.Create(GDIStatus::"To Handle", GDIMethod::PatchFile, GDIProblem::MissingFileID, MediaID, '');
            Commit();
            exit;
        end;
        QueueID := GDIQueueHandler.Create(GDIMethod::PatchFile, GDIProblem::Undefined, MediaID, FileID);
        Commit();

        GDISetupMgt.Authorize(GDIMethod::PatchFile);
        GDISetupMgt.GetError(GDIMethod, GDIProblem, ErrorValue);
        if ErrorValue <> '' then begin
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := GDIRequestHandler.PatchFile(IStream, FileID);
        if GDIErrorHandler.ResponseHasError(GDIMethod::PatchFile, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        ResponseText := PatchMetadata(StrSubstNo(SimpleJsonTxt, GDITokens.Name(), FileName), FileID);
        if GDIErrorHandler.ResponseHasError(GDIMethod::PatchMetadata, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        GDIQueueHandler.Update(QueueID, GDIStatus::Handled, GDIMethod::PatchFile, GDIProblem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIMethod: Enum "GDI Method";
        ResponseText: Text;
    begin
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        // TODO check NewMetadata
        GDISetupMgt.Authorize(GDIMethod::PatchMetadata);
        ResponseText := GDIRequestHandler.PatchMetadata(NewMetadata, FileID);
        exit(ResponseText);
        // TODO check ResponseText?
    end;

    local procedure CreateGoogleDriveMedia(IStream: InStream; FileName: Text; FileID: Text): Integer
    var
        GDIMedia: Record "GDI Media";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDIMedia.Init();
        GDIMedia.Validate(FileID, FileID);
        GDIMedia.Validate(FileName, FileName);
        GDIMedia.FileContent.ImportStream(IStream, 'default', GDITokens.MimeTypeJpeg()); // TODO remove hardcode
        GDIMedia.Insert(true);
        exit(GDIMedia.ID);
    end;

    local procedure GetGoogleDriveMediaFileID(MediaID: Integer): Text
    var
        GDIMedia: Record "GDI Media";
    begin
        if GDIMedia.Get(MediaID) then
            exit(GDIMedia.FileID);
        exit('');
    end;

    local procedure UpdateGoogleDriveMediaFileID(MediaID: Integer; FileID: Text)
    var
        GDIMedia: Record "GDI Media";
    begin
        GDIMedia.Get(MediaID);
        GDIMedia.Validate(FileID, FileID);
        GDIMedia.Modify(true);
    end;

    local procedure UpdateGoogleDriveMedia(IStream: InStream; FileName: Text; ID: Integer)
    var
        GDIMedia: Record "GDI Media";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDIMedia.Get(ID);
        GDIMedia.Validate(FileName, FileName);
        GDIMedia.FileContent.ImportStream(IStream, 'default', GDITokens.MimeTypeJpeg()); // TODO remove hardcode
        GDIMedia.Modify(true);
    end;

    var
        DialogTitleUploadTxt: Label 'File Upload';
        SimpleJsonTxt: Label '{"%1": "%2"}', Comment = '%1 = Token name; %2 = Value';
}