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
        MyHttpClient: HttpClient;
        MyHttpRequestMessage: HttpRequestMessage;
        MyHttpResponseMessage: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GDISetup.ClientID));
        MyHttpRequestMessage.SetRequestUri(Url);
        MyHttpRequestMessage.Method := 'DELETE';
        MyHttpClient.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        MyHttpClient.Send(MyHttpRequestMessage, MyHttpResponseMessage); // TODO wrapper for the failure
        MyHttpResponseMessage.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure GetErrorText(): Text
    begin
        // TODO: can it be removed?
        exit(CurrentErrorText);
    end;

    procedure GetMedia(var MediaInStream: InStream; FileID: Text)
    var
        GDISetup: Record "GDI Setup";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        MyHttpClient: HttpClient;
        MyHttpResponseMessage: HttpResponseMessage;
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
        MyHttpClient.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if MyHttpClient.Get(Url, MyHttpResponseMessage) then
            if MyHttpResponseMessage.IsSuccessStatusCode then
                MyHttpResponseMessage.Content.ReadAs(MediaInStream) // TODO: will that work in Azure considering 1 mln bytes limitation? 
            else begin
                MyHttpResponseMessage.Content.ReadAs(ErrorText);
                SetErrorText(GDIJsonHelper.CreateSimpleJson(GDITokens.ErrorTok(), ErrorText));
            end
        else
            SetErrorText(GDIJsonHelper.CreateSimpleJson(GDITokens.ErrorTok(), MyHttpResponseMessage.HttpStatusCode));
    end;

    procedure GetMetadata(FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        MyHttpClient: HttpClient;
        MyHttpResponseMessage: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        // TODO wrapper for get call
        if FileID = '' then
            GDIErrorHandler.ThrowFileIDMissingErr();

        GDISetup.Get();
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GDISetup.ClientID));
        MyHttpClient.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        MyHttpClient.Get(Url, MyHttpResponseMessage);
        MyHttpResponseMessage.Content.ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure PatchFile(MediaInStream: InStream; FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDITokens: Codeunit "GDI Tokens";
        MyHttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        MyHttpRequestMessage: HttpRequestMessage;
        MyHttpClient: HttpClient;
        MyHttpResponseMessage: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        MyHttpContent.WriteFrom(MediaInStream);
        MyHttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJpeg());
        MyHttpRequestMessage.Content := MyHttpContent;
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIUploadScope, FileID, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GDISetup.ClientID,
                    GDITokens.UploadType(), GDITokens.MediaTok()));
        MyHttpRequestMessage.SetRequestUri(Url);
        MyHttpRequestMessage.Method := 'PATCH';
        MyHttpClient.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if MyHttpClient.Send(MyHttpRequestMessage, MyHttpResponseMessage) then begin
            MyHttpResponseMessage.Content.ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(GDIJsonHelper.CreateSimpleJson(GDITokens.ErrorTok(), MyHttpResponseMessage.HttpStatusCode));
    end;

    procedure PatchMetadata(NewMetadata: Text; FileID: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDITokens: Codeunit "GDI Tokens";
        MyHttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        MyHttpRequestMessage: HttpRequestMessage;
        MyHttpClient: HttpClient;
        MyHttpResponseMessage: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        MyHttpContent.WriteFrom(NewMetadata);
        MyHttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJson());
        MyHttpRequestMessage.Content := MyHttpContent;
        Url := StrSubstNo(UrlWithIdAndParamsTok, GDISetup.APIScope, FileID, StrSubstNo(CreateUrlParamsTemplate(1),
                    GDITokens.KeyTok(), GDISetup.ClientID));
        MyHttpRequestMessage.SetRequestUri(Url);
        MyHttpRequestMessage.Method := 'PATCH';
        MyHttpClient.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if MyHttpClient.Send(MyHttpRequestMessage, MyHttpResponseMessage) then begin
            MyHttpResponseMessage.Content.ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(GDIJsonHelper.CreateSimpleJson(GDITokens.ErrorTok(), MyHttpResponseMessage.HttpStatusCode));
    end;

    procedure PostFile(var MediaInStream: InStream): Text;
    var
        GDISetup: Record "GDI Setup";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDITokens: Codeunit "GDI Tokens";
        MyHttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        MyHttpClient: HttpClient;
        MyHttpResponseMessage: HttpResponseMessage;
        Url: Text;
        ResponseText: Text;
    begin
        GDISetup.Get();
        MyHttpContent.WriteFrom(MediaInStream);
        MyHttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeJpeg());
        Url := StrSubstNo(UrlWithParamsTok, GDISetup.APIUploadScope, StrSubstNo(CreateUrlParamsTemplate(2),
                    GDITokens.KeyTok(), GDISetup.ClientID,
                    GDITokens.UploadType(), GDITokens.MediaTok()));
        MyHttpClient.DefaultRequestHeaders.Add(
            GDITokens.Authorization(), StrSubstNo(AuthHdrValueTok, GDISetup.TokenType, GDISetup.AccessToken));
        if MyHttpClient.Post(Url, MyHttpContent, MyHttpResponseMessage) then begin
            MyHttpResponseMessage.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(GDIJsonHelper.CreateSimpleJson(GDITokens.ErrorTok(), MyHttpResponseMessage.HttpStatusCode));
    end;

    procedure RequestAccessToken(RequestBody: Text): Text
    var
        GDISetup: Record "GDI Setup";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDITokens: Codeunit "GDI Tokens";
        MyHttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        MyHttpClient: HttpClient;
        MyHttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
    begin
        GDISetup.Get();
        MyHttpContent.WriteFrom(RequestBody);
        MyHttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add(GDITokens.ContentType(), GDITokens.MimeTypeFormUrlEncoded());
        if MyHttpClient.Post(GDISetup.TokenURI, MyHttpContent, MyHttpResponseMessage) then begin
            MyHttpResponseMessage.Content().ReadAs(ResponseText);
            exit(ResponseText);
        end;
        exit(GDIJsonHelper.CreateSimpleJson(GDITokens.ErrorTok(), MyHttpResponseMessage.HttpStatusCode));
    end;

    local procedure CreateUrlParamsTemplate(QtyParams: Integer): Text
    var
        GDIErrorHandler: Codeunit "GDI Error Handler";
        TemplText: Text;
        Index: Integer;
    begin
        // Creates texts like '%1=%2&%3=%4'
        if QtyParams < 1 then
            GDIErrorHandler.ThrowBadParameterErr('CreateUrlParamsTemplate', QtyParams);

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
        UrlWithParamsTok: Label '%1?%2', Comment = '%1 = Url; %2 = parameters';
        UrlWithIdAndParamsTok: Label '%1/%2?%3', Comment = '%1 = Url; %2 = entity id; %3 = parameters';
        CurrentErrorText: Text;
}