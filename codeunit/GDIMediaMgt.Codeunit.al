codeunit 50101 "GDI Media Mgt."
{
    Description = 'Manages Google Drive API calls and handles Google Drive Media.';

    procedure Create()
    var
        GDIErrorHandler: Codeunit "GDI Error Handler";
        IStream: InStream;
        ClientFileName: Text;
        MediaID: Integer;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GDIErrorHandler.ThrowFileUploadErr(ClientFileName);

        MediaID := CreateGoogleDriveMedia(IStream, ClientFileName, '');
        CreateOnGoogleDrive(IStream, ClientFileName, MediaID);
    end;

    procedure CreateOnGoogleDrive(var IStream: InStream; FileName: Text; MediaID: Integer)
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

        QueueID: Integer;
    begin
        if FileName = '' then
            GDIErrorHandler.ThrowFileNameMissingErr();
        // todo: check mediaid

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

        ResponseText := PatchMetadata(GDIJsonHelper.CreateSimpleJson(GDITokens.Name(), FileName), FileID);
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

    procedure CreateOnGoogleDrive(MediaID: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        IStream: InStream;
        FileName: Text;
    begin
        ReadFileFromMedia(TempBlob, FileName, MediaID);
        TempBlob.CreateInStream(IStream);
        CreateOnGoogleDrive(IStream, FileName, MediaID);
    end;

    procedure Delete(MediaID: Integer)
    var
        GDIMedia: Record "GDI Media";
        FileID: Text;
    begin
        GDIMedia.Get(MediaID);
        FileID := GDIMedia.FileID;
        GDIMedia.Delete(true);
        DeleteFromGoogleDrive(MediaID, FileID);
    end;

    procedure DeleteFromGoogleDrive(MediaID: Integer; FileID: Text)
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIQueueHandler: Codeunit "GDI Queue Handler";
        GDIMethod: Enum "GDI Method";
        GDIProblem: Enum "GDI Problem";
        GDIStatus: Enum "GDI Status";
        ResponseText: Text;
        ErrorValue: Text;
        QueueID: Integer;
    begin
        if FileID = '' then begin
            GDIQueueHandler.Create(GDIStatus::"To Handle", GDIMethod::DeleteFile, GDIProblem::MissingFileID, MediaID, '');
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

    procedure Download(MediaID: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        IStream: InStream;
        FileName: Text;
    begin
        ReadFileFromMedia(TempBlob, FileName, MediaID);
        TempBlob.CreateInStream(IStream);
        File.DownloadFromStream(IStream, DialogTitleDownloadTxt, '', '', FileName);
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

        UpdateGoogleDriveMedia(IStream, ClientFileName, MediaID);
        UpdateOnGoogleDrive(IStream, ClientFileName, MediaID);
    end;

    procedure UpdateOnGoogleDrive(var IStream: InStream; FileName: Text; MediaID: Integer)
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIQueueHandler: Codeunit "GDI Queue Handler";
        GDIJsonHelper: Codeunit "GDI Json Helper";
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

        ResponseText := PatchMetadata(GDIJsonHelper.CreateSimpleJson(GDITokens.Name(), FileName), FileID);
        if GDIErrorHandler.ResponseHasError(GDIMethod::PatchMetadata, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            GDIQueueHandler.Update(QueueID, GDIStatus::"To Handle", GDIMethod, GDIProblem, MediaID, FileID, ErrorValue);
            Commit();
            exit;
        end;

        GDIQueueHandler.Update(QueueID, GDIStatus::Handled, GDIMethod::PatchFile, GDIProblem::Undefined, MediaID, FileID, '');
        Commit();
    end;

    procedure UpdateOnGoogleDrive(MediaID: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        IStream: InStream;
        FileName: Text;
    begin
        ReadFileFromMedia(TempBlob, FileName, MediaID);
        TempBlob.CreateInStream(IStream);
        UpdateOnGoogleDrive(IStream, FileName, MediaID);
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GDISetupMgt: Codeunit "GDI Setup Mgt.";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDIMethod: Enum "GDI Method";
        ResponseText: Text;
    begin
        //todo: patch metadata doesn't know how to create queue yet
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        // TODO check NewMetadata
        GDISetupMgt.Authorize(GDIMethod::PatchMetadata);
        ResponseText := GDIRequestHandler.PatchMetadata(NewMetadata, FileID);
        exit(ResponseText);
        // TODO check ResponseText?
    end;

    procedure ReadFileFromMedia(var TempBlob: codeunit "Temp Blob"; var FileName: Text; MediaID: Integer)
    var
        GDIMedia: Record "GDI Media";
        OStream: OutStream;
    begin
        Clear(TempBlob); // clears reference only
        GDIMedia.Get(MediaID);
        FileName := GDIMedia.FileName;
        TempBlob.CreateOutStream(OStream);
        GDIMedia.FileContent.ExportStream(OStream);
    end;

    local procedure CreateGoogleDriveMedia(IStream: InStream; FileName: Text; FileID: Text): Integer
    var
        GDIMedia: Record "GDI Media";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDIMedia.Init();
        GDIMedia.Validate(FileID, FileID);
        GDIMedia.Validate(FileName, FileName);
        GDIMedia.FileContent.ImportStream(IStream, FileName, GDITokens.MimeTypeJpeg());
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
        GDIMedia.FileContent.ImportStream(IStream, FileName, GDITokens.MimeTypeJpeg());
        GDIMedia.Modify(true);
    end;

    var
        DialogTitleUploadTxt: Label 'File Upload'; // duplicate. shall it be here?
        DialogTitleDownloadTxt: Label 'File Download'; // shall it be here?
}