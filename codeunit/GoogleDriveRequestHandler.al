codeunit 50110 "Google Drive Request Handler"
{
    Description = 'Handles calls to Google Drive API.';

    procedure CreateRequestParamsAuthCode(): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        Tokens: Codeunit "Google Drive API Tokens";
    begin
        GoogleDriveSetup.Get;
        exit(StrSubstNo(CreateUrlParamsTemplate(5),
                    Tokens.CodeTok, GoogleDriveSetup.AuthCode,
                    Tokens.ClientID, GoogleDriveSetup.ClientID,
                    Tokens.ClientSecret, GoogleDriveSetup.ClientSecret,
                    Tokens.RedirectUri, GoogleDriveSetup.RedirectURI,
                    Tokens.GrantType, Tokens.AuthorizationCode));
    end;

    procedure CreateRequestParamsRefreshToken(): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        Tokens: Codeunit "Google Drive API Tokens";
    begin
        GoogleDriveSetup.Get;
        exit(StrSubstNo(CreateUrlParamsTemplate(4),
                    Tokens.ClientID, GoogleDriveSetup.ClientID,
                    Tokens.ClientSecret, GoogleDriveSetup.ClientSecret,
                    Tokens.RefreshToken, GoogleDriveSetup.RefreshToken,
                    Tokens.GrantType, Tokens.RefreshToken));
    end;

    procedure CreateRequestParamsRedirect(): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        Tokens: Codeunit "Google Drive API Tokens";
    begin
        GoogleDriveSetup.Get;
        exit(StrSubstNo(CreateUrlParamsTemplate(4),
                        Tokens.ClientID, GoogleDriveSetup.ClientID,
                        Tokens.RedirectUri, GoogleDriveSetup.RedirectURI,
                        Tokens.ResponseType, Tokens.CodeTok,
                        Tokens.Scope, GoogleDriveSetup.AuthScope));
    end;

    procedure DeleteFile(FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        Tokens: Codeunit "Google Drive API Tokens";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    Tokens.KeyTok, GoogleDriveSetup.ClientID));
        Request.SetRequestUri(Url);
        Request.Method := 'DELETE';
        Client.DefaultRequestHeaders.Add(
            Tokens.Authorization, StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure GetErrorText(): Text
    begin
        exit(ErrorText);
    end;

    procedure GetMedia(var IStream: InStream; FileID: Text)
    var
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        GoogleDriveSetup: Record "Google Drive Setup";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ErrorText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr;

        Clear(ErrorText);
        GoogleDriveSetup.Get;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    Tokens.KeyTok, GoogleDriveSetup.ClientID,
                    Tokens.AltTok, Tokens.MediaTok));
        Client.DefaultRequestHeaders.Add(
            Tokens.Authorization, StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Get(Url, Response);
        if Response.IsSuccessStatusCode then
            Response.Content.ReadAs(IStream)
        else begin
            Response.Content.ReadAs(ErrorText);
            SetErrorText(ErrorText);
        end;
    end;

    procedure GetMetadata(FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        // TODO almost duplicates GetMedia
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr;

        GoogleDriveSetup.Get;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    Tokens.KeyTok, GoogleDriveSetup.ClientID));
        Client.DefaultRequestHeaders.Add(
            Tokens.Authorization, StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Get(Url, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure PatchFile(IStream: InStream; FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get;
        Content.WriteFrom(IStream); // TODO Check IStream
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(Tokens.ContentType, Tokens.MimeTypeJpeg);
        Request.Content := Content;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIUploadScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    Tokens.KeyTok, GoogleDriveSetup.ClientID,
                    Tokens.UploadType, Tokens.MediaTok));
        Request.SetRequestUri(Url);
        Request.Method := 'PATCH';
        Client.DefaultRequestHeaders.Add(
            Tokens.Authorization, StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;


    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get;
        Content.WriteFrom(NewMetadata);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(Tokens.ContentType, Tokens.MimeTypeJson);
        Request.Content := Content;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    Tokens.KeyTok, GoogleDriveSetup.ClientID));
        Request.SetRequestUri(Url);
        Request.Method := 'PATCH';
        Client.DefaultRequestHeaders.Add(
            Tokens.Authorization, StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure PostFile(var IStream: InStream): Text;
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        Tokens: Codeunit "Google Drive API Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get;
        Content.WriteFrom(IStream); // TODO Check IStream
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(Tokens.ContentType, Tokens.MimeTypeJpeg);
        Url := StrSubstNo('%1?%2', GoogleDriveSetup.APIUploadScope, StrSubstNo(CreateUrlParamsTemplate(2),
                    Tokens.KeyTok, GoogleDriveSetup.ClientID,
                    Tokens.UploadType, Tokens.MediaTok));
        Client.DefaultRequestHeaders.Add(
            Tokens.Authorization, StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Post(Url, Content, Response);
        Response.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure RequestAccessToken(RequestBody: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        Tokens: Codeunit "Google Drive API Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get;
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(Tokens.ContentType, Tokens.MimeTypeFormUrlEncoded);
        if Client.Post(GoogleDriveSetup.TokenURI, Content, Response) then begin
            Response.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end else
            exit(StrSubstNo('{"%1": "%2"}', Tokens.ErrorTok, Response.HttpStatusCode));
    end;

    local procedure CreateUrlParamsTemplate(QtyParams: Integer): Text
    var
        TemplText: Text;
        Index: Integer;
    begin
        // Creates texts like '%1=%2&%3=%4'
        if QtyParams < 1 then
            Error(BadParameterErr, QtyParams);

        for Index := 1 to QtyParams do
            TemplText += '%' + Format(2 * Index - 1) + '=%' + Format(2 * Index) + '&';
        exit(TemplText.Remove(StrLen(TemplText)));
    end;

    local procedure PostSimpleHttpRequest(RequestBody: Text; MimeType: Text; Uri: Text): Text
    var
        Tokens: Codeunit "Google Drive API Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(Tokens.ContentType, MimeType);
        Client.Post(Uri, Content, Response);
        Response.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    local procedure SetErrorText(NewErrorText: Text)
    begin
        ErrorText := NewErrorText;
    end;

    var
        BadParameterErr: Label 'Bad parameter(s) %1.';
        ErrorText: Text;

}