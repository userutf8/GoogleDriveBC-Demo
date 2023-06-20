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
        Method: enum GDMethod;
        ResponseJson: JsonObject;
        ResponseText: Text;
        FileID: Text;
        MediaID: Integer;
    begin
        if FileName = '' then
            GoogleDriveErrorHandler.ThrowFileNameMissingErr();

        // TODO check Istream (Length is available in runtime 11.0)

        MediaID := CreateGoogleDriveMedia(IStream, FileName, '');
        Commit();

        GoogleDriveSetupMgt.SetParentMethod(Method::PostFile);
        GoogleDriveSetupMgt.Authorize();
        if not GoogleDriveErrorHandler.FinalizeHandleErrors(Method::PostFile, MediaID, '') then
            exit;

        ResponseText := GoogleDriveRequestHandler.PostFile(IStream);
        GoogleDriveErrorHandler.HandleErrors(Method::PostFile, ResponseText);
        ResponseJson.ReadFrom(ResponseText);
        FileID := GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.IdTok);
        UpdateGoogleDriveMediaFileID(MediaID, FileID);
        Commit();

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        GoogleDriveErrorHandler.HandleErrors(Method::PatchMetadata, ResponseText);
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
            GoogleDriveErrorHandler.HandleErrors(Method::DeleteFile, StrSubstNo('{"%1": {"%1": "%2"}}', Tokens.ErrorTok, 'MissingFileID'));
            GoogleDriveErrorHandler.FinalizeHandleErrors(Method::DeleteFile, MediaID, '');
            exit;
        end;

        GoogleDriveSetupMgt.SetParentMethod(Method::DeleteFile);
        GoogleDriveSetupMgt.Authorize();
        if not GoogleDriveErrorHandler.FinalizeHandleErrors(Method::DeleteFile, MediaID, FileID) then
            exit;
        ResponseText := GoogleDriveRequestHandler.DeleteFile(FileID);
        GoogleDriveErrorHandler.HandleErrors(Method::DeleteFile, ResponseText);
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

        GoogleDriveSetupMgt.SetParentMethod(Method::GetFile);
        GoogleDriveSetupMgt.Authorize();
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

        GoogleDriveSetupMgt.SetParentMethod(Method::GetMetadata);
        GoogleDriveSetupMgt.Authorize();
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
            GoogleDriveErrorHandler.HandleErrors(Method::PatchFile, StrSubstNo('{"%1": {"%1": "%2"}}', Tokens.ErrorTok, 'MissingFileID'));
            GoogleDriveErrorHandler.FinalizeHandleErrors(Method::PatchFile, MediaID, '');
            exit;
        end;

        GoogleDriveSetupMgt.SetParentMethod(Method::PatchFile);
        GoogleDriveSetupMgt.Authorize();
        if not GoogleDriveErrorHandler.FinalizeHandleErrors(Method::PatchFile, MediaID, FileID) then
            exit;

        ResponseText := GoogleDriveRequestHandler.PatchFile(IStream, FileID);
        GoogleDriveErrorHandler.HandleErrors(Method::PatchFile, ResponseText);

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        GoogleDriveErrorHandler.HandleErrors(Method::PatchMetadata, ResponseText);
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
        GoogleDriveSetupMgt.SetParentMethod(Method::PatchMetadata);
        GoogleDriveSetupMgt.Authorize();
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