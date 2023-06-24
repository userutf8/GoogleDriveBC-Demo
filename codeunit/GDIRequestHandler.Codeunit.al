codeunit 50110 "GDI Request Handler"
{
    Description = 'Handles Google Drive API calls.';

    procedure CreateRequestParamsAuthCode(): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDISetup.Get();
        exit(StrSubstNo(CreateUrlParamsTemplate(5),
                    GDITokens.CodeTok(), GDISetup.AuthCode,
                    GDITokens.ClientID(), GDISetup.ClientID,
                    GDITokens.ClientSecret(), GDISetup.ClientSecret,
                    GDITokens.RedirectUri(), GDISetup.RedirectURI,
                    GDITokens.GrantType(), GDITokens.AuthorizationCode()));
    end;

    procedure CreateRequestParamsRefreshToken(): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDISetup.Get();
        exit(StrSubstNo(CreateUrlParamsTemplate(4),
                    GDITokens.ClientID(), GDISetup.ClientID,
                    GDITokens.ClientSecret(), GDISetup.ClientSecret,
                    GDITokens.RefreshToken(), GDISetup.RefreshToken,
                    GDITokens.GrantType(), GDITokens.RefreshToken()));
    end;

    procedure CreateRequestParamsRedirect(): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
    begin
        GDISetup.Get();
        exit(StrSubstNo(CreateUrlParamsTemplate(4),
                        GDITokens.ClientID(), GDISetup.ClientID,
                        GDITokens.RedirectUri(), GDISetup.RedirectURI,
                        GDITokens.ResponseType(), GDITokens.CodeTok(),
                        GDITokens.Scope(), GDISetup.AuthScope));
    end;

    procedure DeleteFile(FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GDISetup.ClientID));
        Request.SetRequestUri(Url);
        Request.Method := 'DELETE';
        Client.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure GetErrorText(): Text
    begin
        // TODO: to remove
        exit(CurrentErrorText);
    end;

    procedure GetMedia(var IStream: InStream; FileID: Text)
    var
        GDISetup: Record "GDI Setup";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ErrorText: Text;
    begin
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        Clear(ErrorText);
        GDISetup.Get();
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GDISetup.ClientID,
                    GDITokens.AltTok(), GDITokens.MediaTok()));
        Client.DefaultRequestHeaders.Add(GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        Client.Get(Url, Response);
        if Response.IsSuccessStatusCode then
            Response.Content.ReadAs(IStream) // TODO: will that work in Azure considering 1 mln bytes limitation? 
        else begin
            Response.Content.ReadAs(ErrorText);
            SetErrorText(ErrorText);
        end;
    end;

    procedure GetMetadata(FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        // TODO almost duplicates GetMedia
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        GDISetup.Get();
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GDISetup.ClientID));
        Client.DefaultRequestHeaders.Add(GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        Client.Get(Url, Response);
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure PatchFile(IStream: InStream; FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        Content.WriteFrom(IStream); // TODO Check IStream
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJpeg());
        Request.Content := Content;
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIUploadScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GDISetup.ClientID,
                    GDITokens.UploadType(), GDITokens.MediaTok()));
        Request.SetRequestUri(Url);
        Request.Method := 'PATCH';
        Client.DefaultRequestHeaders.Add(GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if Client.Send(Request, Response) then begin
            Response.Content.ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo(SimpleJsonTxt, GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        Content.WriteFrom(NewMetadata);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJson());
        Request.Content := Content;
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GDISetup.ClientID));
        Request.SetRequestUri(Url);
        Request.Method := 'PATCH';
        Client.DefaultRequestHeaders.Add(GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if Client.Send(Request, Response) then begin
            Response.Content.ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo(SimpleJsonTxt, GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    procedure PostFile(var IStream: InStream): Text;
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        Content.WriteFrom(IStream); // TODO: will that work in Azure considering 1 mln bytes limitation? 
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJpeg());
        Url := StrSubstNo(UrlWithParamsTok, GDISetup.APIUploadScope, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GDISetup.ClientID,
                    GDITokens.UploadType(), GDITokens.MediaTok()));
        Client.DefaultRequestHeaders.Add(GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if Client.Post(Url, Content, Response) then begin
            Response.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo(SimpleJsonTxt, GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    procedure RequestAccessToken(RequestBody: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDITokens: Codeunit "GDI Tokens";
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        GDISetup.Get();
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeFormUrlEncoded());
        if Client.Post(GDISetup.TokenURI, Content, Response) then begin
            Response.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(StrSubstNo(SimpleJsonTxt, GDITokens.ErrorTok(), Response.HttpStatusCode));
    end;

    local procedure CreateUrlParamsTemplate(QtyParams: Integer): Text
    var
        TemplText: Text;
        Index: Integer;
    begin
        // Creates texts like '%1=%2&%3=%4'
        if QtyParams < 1 then
            Error(BadParameterErr, 'CreateUrlParamsTemplate', QtyParams);

        for Index := 1 to QtyParams do
            TemplText += '%' + Format(2 * Index - 1) + '=%' + Format(2 * Index) + '&';
        exit(TemplText.Remove(StrLen(TemplText)));
    end;

    local procedure SetErrorText(NewErrorText: Text)
    begin
        CurrentErrorText := NewErrorText;
    end;

    var
        AuthHdrValueTok: Label '%1 %2', Comment = '%1 = token type; %2 = token value'; // bad name
        BadParameterErr: Label '%1 says: bad parameter value %2.', Comment = '%1 = function, %2 = parameter value';
        SimpleJsonTxt: Label '{"%1": "%2"}', Comment = '%1 = Token name; %2 = Value'; // duplicate
        UrlWithParamsTok: Label '%1?%2', Comment = '%1 = Url; %2 = parameters';
        UrlWithIdAndParamsTok: Label '%1/%2?%3', Comment = '%1 = Url; %2 = entity id; %3 = parameters';
        CurrentErrorText: Text;
}