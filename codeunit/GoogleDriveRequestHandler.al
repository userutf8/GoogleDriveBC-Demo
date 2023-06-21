codeunit 50110 "Google Drive Request Handler"
{
    Description = 'Handles Google Drive API calls.';

    procedure CreateRequestParamsAuthCode(): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GoogleDriveSetup.Get();
        exit(StrSubstNo(CreateUrlParamsTemplate(5),
                    GDITokens.CodeTok(), GoogleDriveSetup.AuthCode,
                    GDITokens.ClientID(), GoogleDriveSetup.ClientID,
                    GDITokens.ClientSecret(), GoogleDriveSetup.ClientSecret,
                    GDITokens.RedirectUri(), GoogleDriveSetup.RedirectURI,
                    GDITokens.GrantType(), GDITokens.AuthorizationCode()));
    end;

    procedure CreateRequestParamsRefreshToken(): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GoogleDriveSetup.Get();
        exit(StrSubstNo(CreateUrlParamsTemplate(4),
                    GDITokens.ClientID(), GoogleDriveSetup.ClientID,
                    GDITokens.ClientSecret(), GoogleDriveSetup.ClientSecret,
                    GDITokens.RefreshToken(), GoogleDriveSetup.RefreshToken,
                    GDITokens.GrantType(), GDITokens.RefreshToken()));
    end;

    procedure CreateRequestParamsRedirect(): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GoogleDriveSetup.Get();
        exit(StrSubstNo(CreateUrlParamsTemplate(4),
                        GDITokens.ClientID(), GoogleDriveSetup.ClientID,
                        GDITokens.RedirectUri(), GoogleDriveSetup.RedirectURI,
                        GDITokens.ResponseType(), GDITokens.CodeTok(),
                        GDITokens.Scope(), GoogleDriveSetup.AuthScope));
    end;

    procedure DeleteFile(FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get();
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GoogleDriveSetup.ClientID));
        Request.SetRequestUri(Url);
        Request.Method := 'DELETE';
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure GetErrorText(): Text
    begin
        // TODO: to remove
        exit(ErrorText);
    end;

    procedure GetMedia(var IStream: InStream; FileID: Text)
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ErrorText: Text;
    begin
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        Clear(ErrorText);
        GoogleDriveSetup.Get();
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GoogleDriveSetup.ClientID,
                    GDITokens.AltTok(), GDITokens.MediaTok()));
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
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
        GDITokens: Codeunit "GDI Tokens";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        // TODO almost duplicates GetMedia
        if FileID = '' then
            GoogleDriveErrorHandler.ThrowFileIDMissingErr();

        GoogleDriveSetup.Get;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GoogleDriveSetup.ClientID));
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        Client.Get(Url, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure PatchFile(IStream: InStream; FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get();
        Content.WriteFrom(IStream); // TODO Check IStream
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJpeg());
        Request.Content := Content;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIUploadScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GoogleDriveSetup.ClientID,
                    GDITokens.UploadType(), GDITokens.MediaTok()));
        Request.SetRequestUri(Url);
        Request.Method := 'PATCH';
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        if Client.Send(Request, Response) then begin
            Response.Content.ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo('{"%1": "%2"}', GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get();
        Content.WriteFrom(NewMetadata);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJson());
        Request.Content := Content;
        Url := StrSubstNo('%1/%2?%3', GoogleDriveSetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GoogleDriveSetup.ClientID));
        Request.SetRequestUri(Url);
        Request.Method := 'PATCH';
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        if Client.Send(Request, Response) then begin
            Response.Content.ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo('{"%1": "%2"}', GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    procedure PostFile(var IStream: InStream): Text;
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get();
        Content.WriteFrom(IStream); // TODO Check IStream
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJpeg());
        Url := StrSubstNo('%1?%2', GoogleDriveSetup.APIUploadScope, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GoogleDriveSetup.ClientID,
                    GDITokens.UploadType(), GDITokens.MediaTok()));
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo('%1 %2', GoogleDriveSetup.TokenType, GoogleDriveSetup.AccessToken));
        if Client.Post(Url, Content, Response) then begin
            Response.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo('{"%1": "%2"}', GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    procedure RequestAccessToken(RequestBody: Text): Text
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get();
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeFormUrlEncoded());
        if Client.Post(GoogleDriveSetup.TokenURI, Content, Response) then begin
            Response.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo('{"%1": "%2"}', GDITokens.ErrorTok(), Response.HttpStatusCode));
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

    // local procedure PostSimpleHttpRequest(RequestBody: Text; MimeType: Text; Uri: Text): Text
    // var
    //     Tokens: Codeunit "GDI Tokens";
    //     Content: HttpContent;
    //     ContentHeaders: HttpHeaders;
    //     Client: HttpClient;
    //     Response: HttpResponseMessage;
    //     ResponseText: Text;
    // begin
    //     Content.WriteFrom(RequestBody);
    //     Content.GetHeaders(ContentHeaders);
    //     ContentHeaders.Clear();
    //     ContentHeaders.Add(Tokens.ContentType(), MimeType);
    //     Client.Post(Uri, Content, Response);
    //     Response.Content().ReadAs(ResponseText);
    //     exit(ResponseText);
    // end;

    local procedure SetErrorText(NewErrorText: Text)
    begin
        ErrorText := NewErrorText;
    end;

    var
        BadParameterErr: Label 'Bad parameter(s) %1.';
        ErrorText: Text;

}