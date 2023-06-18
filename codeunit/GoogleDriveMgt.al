codeunit 50111 "Google Drive Mgt."
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
        ResponseText: Text;
        FileID: Text;
        MediaID: Integer;
    begin
        if FileName = '' then
            GoogleDriveErrorHandler.ThrowFileNameMissingErr();

        // TODO check Istream (Length is available in runtime 11.0)

        // Create record with empty File ID
        MediaID := CreateGoogleDriveMedia(IStream, FileName, '');
        Commit();

        GoogleDriveSetupMgt.Authorize();
        ResponseText := GoogleDriveRequestHandler.PostFile(IStream);
        GoogleDriveErrorHandler.HandleErrors(Tokens.PostFileLbl, ResponseText);
        ResponseJson.ReadFrom(ResponseText);
        FileID := GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.IdTok);
        UpdateGoogleDriveMediaFileID(MediaID, FileID);
        Commit();

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        GoogleDriveErrorHandler.HandleErrors(Tokens.PatchMetadataLbl, ResponseText);
    end;

    procedure Delete(FileID: Text)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        ResponseText: Text;
        ErrorText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        DeleteLinksAndMedia(FileID);
        Commit();

        GoogleDriveSetupMgt.Authorize();
        ResponseText := GoogleDriveRequestHandler.DeleteFile(FileID);
        GoogleDriveErrorHandler.HandleErrors(Tokens.DeleteFileLbl, ResponseText);
    end;

    procedure Get(var IStream: InStream; var ErrorText: Text; FileID: Text)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr;

        GoogleDriveSetupMgt.Authorize();
        GoogleDriveRequestHandler.GetMedia(IStream, FileID);
        ErrorText := GoogleDriveRequestHandler.GetErrorText();
    end;

    procedure GetMetadata(FileID: Text): Text
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        ResponseText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr;

        GoogleDriveSetupMgt.Authorize();
        ResponseText := GoogleDriveRequestHandler.GetMetadata(FileID);
        exit(ResponseText);
        // TODO check ResponseText?
    end;

    procedure Update(FileID: Text)
    var
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        IStream: InStream;
        ClientFileName: Text;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GoogleDriveErrorHandler.ThrowFileUploadErr(ClientFileName);

        Update(IStream, ClientFileName, FileID);
    end;

    procedure Update(var IStream: InStream; FileName: Text; FileID: Text)
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        ResponseText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        if FileName = '' then
            GoogleDriveErrorHandler.ThrowFileNameMissingErr();

        UpdateGoogleDriveMedia(IStream, FileName, FileID);
        Commit();

        GoogleDriveSetupMgt.Authorize();
        ResponseText := GoogleDriveRequestHandler.PatchFile(IStream, FileID);
        GoogleDriveErrorHandler.HandleErrors(Tokens.PatchFileLbl, ResponseText);

        ResponseText := PatchMetadata(StrSubstNo('{"name": "%1"}', FileName), FileID);
        GoogleDriveErrorHandler.HandleErrors(Tokens.PatchMetadataLbl, ResponseText);
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        ResponseText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        // TODO check NewMetadata
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

    local procedure UpdateGoogleDriveMediaFileID(MediaID: Integer; FileID: Text)
    var
        GoogleDriveMedia: Record "Google Drive Media";
    begin
        GoogleDriveMedia.Get(MediaID);
        GoogleDriveMedia.Validate(FileID, FileID);
        GoogleDriveMedia.Modify(true);
    end;

    local procedure UpdateGoogleDriveMedia(IStream: InStream; FileName: Text; FileID: Text)
    var
        GoogleDriveMedia: Record "Google Drive Media";
        Tokens: Codeunit "Google Drive API Tokens";
    begin
        GoogleDriveMedia.SetRange(FileID, FileID);
        GoogleDriveMedia.FindFirst();
        GoogleDriveMedia.Validate(FileName, FileName);
        GoogleDriveMedia.FileContent.ImportStream(IStream, 'default', Tokens.MimeTypeJpeg); // TODO remove hardcode
        GoogleDriveMedia.Modify(true);
    end;

    local procedure DeleteLinksAndMedia(FileID: Text)
    var
        Link: Record "Google Drive Link";
        GoogleDriveMedia: Record "Google Drive Media";
    begin
        // TODO Logic to delete links can be moved to OnDelete trigger
        GoogleDriveMedia.SetRange(FileID, FileID);
        GoogleDriveMedia.FindFirst();
        Link.SetRange(MediaID, GoogleDriveMedia.ID);
        Link.DeleteAll(true);
        GoogleDriveMedia.Delete(true);
    end;

    var
        DialogTitleUploadTxt: Label 'File Upload';
}