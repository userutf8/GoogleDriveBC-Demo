codeunit 50101 "GDI Media Mgt."
{
    Description = 'Manages Google Drive API calls and handles Google Drive Media.';

    procedure CreateWithLink(var NewMediaID: Integer; EntityTypeID: Integer; EntityID: Text)
    var
        GDILinksHandler: Codeunit "GDI Links Handler";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        IStream: InStream;
        ClientFileName: Text;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', UploadFileFilterTxt, ClientFileName, IStream) then
            GDIErrorHandler.ThrowFileUploadErr(ClientFileName);

        NewMediaID := CreateGoogleDriveMedia(IStream, ClientFileName, '');
        if EntityTypeID <> 0 then
            GDILinksHandler.CreateLink(NewMediaID, EntityTypeID, EntityID);
        CreateOnGoogleDrive(IStream, ClientFileName, NewMediaID);
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

    procedure Delete(MediaID: Integer; EntityTypeID: Integer; EntityID: Text)
    var
        GDILinksHandler: Codeunit "GDI Links Handler";
        SelectedOption: Integer;
    begin
        if EntityTypeID = 0 then begin
            if Confirm(DeleteConfirmTxt, true) then
                Delete(MediaID);
        end else
            if GDILinksHandler.MediaHasSeveralLinks(MediaID, EntityTypeID, EntityID) then begin
                SelectedOption := StrMenu(DeleteMenuOptionsTxt, 1, DeleteMenuLabelTxt);
                case SelectedOption of
                    1:
                        GDILinksHandler.DeleteLink(MediaID, EntityTypeID, EntityID);
                    2:
                        Delete(MediaID);
                end;
            end else
                if Confirm(DeleteConfirmTxt, true) then
                    Delete(MediaID);
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

    procedure Get(var GDIMedia: Record "GDI Media")
    var
        GDIMediaInfo: Record "GDI Media Info";
        TenantMedia: Record "Tenant Media";
        GDICacheCleaner: Codeunit "GDI Cache Cleaner";
        Tokens: Codeunit "GDI Tokens";
        IStream: InStream;
        ErrorText: Text;
    begin
        if GDIMedia.FileContent.HasValue() then
            if not Confirm(GetConfirmTxt, false) then
                exit;

        Get(IStream, ErrorText, GDIMedia.FileID);
        if ErrorText = '' then begin
            GDIMedia.FileContent.ImportStream(IStream, GDIMedia.FileName, Tokens.MimeTypeJpeg());
            GDIMedia.Modify(true);
            if GDIMediaInfo.Get(GDIMedia.ID) then begin
                TenantMedia.Get(GDIMedia.FileContent.MediaId);
                TenantMedia.CalcFields(Content);
                GDIMediaInfo.Validate(FileSize, TenantMedia.Content.Length / 1048576);
                GDIMediaInfo.Validate(Rank, 100);
                GDIMediaInfo.Modify(true);
                GDICacheCleaner.ClearCacheOnDemand(GDIMediaInfo.FileSize, GDIMediaInfo.MediaID);
            end;
        end else
            Error(ErrorText); // TODO parse error and use error handler
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
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', UploadFileFilterTxt, ClientFileName, IStream) then
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

    procedure RunMediaPage(EntityTypeID: Integer; EntityID: Text; Caption: Text)
    var
        GDIMedia: Record "GDI Media";
        GDILinksHandler: Codeunit "GDI Links Handler";
        GDIMediaPage: Page "GDI Media";
    begin
        GDIMedia.SetFilter(ID, GDILinksHandler.CreateSelectionFilter(EntityTypeID, EntityID)); // FilterGroup 0
        GDIMediaPage.SetTableView(GDIMedia);
        GDIMediaPage.SetEntity(EntityTypeID, EntityID);
        GDIMediaPage.UpdateViews(EntityTypeID, EntityID);
        if Caption <> '' then
            GDIMediaPage.Caption := Caption;
        GDIMediaPage.Run();
    end;

    procedure UpdateViewedByEntity(MediaID: Integer)
    var
        GDIMediaInfo: Record "GDI Media Info";
    begin
        if GDIMediaInfo.Get(MediaID) then begin
            GDIMediaInfo.ViewedByEntity += 1;
            GDIMediaInfo.LastViewedByEntity := CurrentDateTime;
            GDIMediaInfo.Modify(true);
        end;
    end;

    local procedure CreateGoogleDriveMedia(IStream: InStream; FileName: Text; FileID: Text): Integer
    var
        GDIMedia: Record "GDI Media";
        GDIMediaInfo: Record "GDI Media Info";
        TenantMedia: Record "Tenant Media";
        GDICacheCleaner: Codeunit "GDI Cache Cleaner";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDIMedia.Init();
        GDIMedia.Validate(FileID, FileID);
        GDIMedia.Validate(FileName, FileName);
        GDIMedia.FileContent.ImportStream(IStream, FileName, GDITokens.MimeTypeJpeg());
        GDIMedia.Insert(true);

        TenantMedia.Get(GDIMedia.FileContent.MediaId);
        TenantMedia.CalcFields(Content);
        GDIMediaInfo.Init();
        GDIMediaInfo.Validate(MediaID, GDIMedia.ID);
        GDIMediaInfo.Validate(FileSize, TenantMedia.Content.Length / 1048576);
        GDIMediaInfo.Validate(Rank, 100);
        GDIMediaInfo.Insert(true);
        GDICacheCleaner.ClearCacheOnDemand(GDIMediaInfo.FileSize, GDIMediaInfo.MediaID);
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

    local procedure UpdateGoogleDriveMedia(IStream: InStream; FileName: Text; ID: Integer)
    var
        GDIMedia: Record "GDI Media";
        GDIMediaInfo: Record "GDI Media Info";
        TenantMedia: Record "Tenant Media";
        GDICacheCleaner: Codeunit "GDI Cache Cleaner";
        GDITokens: Codeunit "GDI Tokens";
        OldFileSize: Decimal;
    begin
        GDIMedia.Get(ID);
        GDIMedia.Validate(FileName, FileName);
        GDIMedia.FileContent.ImportStream(IStream, FileName, GDITokens.MimeTypeJpeg());
        GDIMedia.Modify(true);

        TenantMedia.Get(GDIMedia.FileContent.MediaId);
        TenantMedia.CalcFields(Content);
        GDIMediaInfo.Get(GDIMedia.ID);
        OldFileSize := GDIMediaInfo.FileSize;
        GDIMediaInfo.Validate(FileSize, TenantMedia.Content.Length / 1048576);
        GDIMediaInfo.Validate(Rank, 100);
        Clear(GDIMediaInfo.Stars);
        GDIMediaInfo.Modify(true);
        if OldFileSize < GDIMediaInfo.FileSize then
            GDICacheCleaner.ClearCacheOnDemand(GDIMediaInfo.FileSize, GDIMediaInfo.MediaID);
    end;

    local procedure UpdateGoogleDriveMediaFileID(MediaID: Integer; FileID: Text)
    var
        GDIMedia: Record "GDI Media";
    begin
        GDIMedia.Get(MediaID);
        GDIMedia.Validate(FileID, FileID);
        GDIMedia.Modify(true);
    end;

    var
        DialogTitleUploadTxt: Label 'File Upload'; // duplicate. shall it be here?
        DialogTitleDownloadTxt: Label 'File Download'; // shall it be here?
        DeleteConfirmTxt: Label 'Do you really want to delete this media?';
        DeleteMenuOptionsTxt: Label 'Delete the link only (recommended),Delete the media and links';
        DeleteMenuLabelTxt: Label 'Warning! This media has links to other entities. Please, select an option:';
        GetConfirmTxt: Label 'The image is already in the database. Do you want to pull the last version from Google Drive?';
        UploadFileFilterTxt: Label 'JPEG|*.jpg;*.jpeg';
}