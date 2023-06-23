codeunit 50100 "GDI Setup Mgt."
{
    Description = 'Manages Google Drive Setup.';

    procedure Authorize()
    var
        GDIMethod: enum "GDI Method";
    begin
        // Use this function for calls from setup UI
        Authorize(GDIMethod::Authorize);
    end;

    procedure Authorize(GDIMethod: enum "GDI Method")
    var
        GDISetup: Record "GDI Setup";
        GDIRequestHandler: Codeunit "GDI Request Handler";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        GDIProblem: Enum "GDI Problem";
        ResponseJson: JsonObject;
        RequestParams: Text;
        ResponseText: Text;
        ErrorValue: Text;
        RequestSentAtUTC: DateTime;
    begin
        GDISetup.Get();
        if GDISetup.AccessTokenIsAlive() then
            exit;

        GDISetup.TestMandatoryAuthFields();
        if GDISetup.Active then
            RequestParams := GDIRequestHandler.CreateRequestParamsRefreshToken()
        else begin
            if GDISetup.AuthCode = '' then begin
                RequestParams := GDIRequestHandler.CreateRequestParamsRedirect();
                System.Hyperlink(StrSubstNo(UrlWithParamsTok, GDISetup.AuthURI, RequestParams));
                exit;
            end;
            RequestParams := GDIRequestHandler.CreateRequestParamsAuthCode();
        end;

        RequestSentAtUTC := System.CurrentDateTime();
        ResponseText := GDIRequestHandler.RequestAccessToken(RequestParams);

        if GDIErrorHandler.ResponseHasError(GDIMethod, ResponseText) then begin
            GDIErrorHandler.GetError(GDIMethod, GDIProblem, ErrorValue);
            SetError(GDIProblem, GDIMethod, ErrorValue);
            exit;
        end;

        ResponseJson.ReadFrom(ResponseText);
        Clear(GDISetup.AuthCode);
        GDISetup.Validate(AccessToken, GDIJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.AccessToken()));
        GDISetup.Validate(TokenType, GDIJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.TokenType()));
        GDISetup.Validate(IssuedUtc, RequestSentAtUTC);
        GDISetup.Validate(ExpiresIn, GDIJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.ExpiresIn()));
        GDISetup.Validate(LifeTime, CalcLifetime(GDISetup.ExpiresIn, GDISetup.LifeTime));
        if not GDISetup.Active then begin
            GDISetup.Validate(RefreshToken, GDIJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.RefreshToken()));
            GDISetup.Validate(Active, true);
        end;
        GDISetup.Modify(true);
    end;

    procedure GetError(var GDIMethod: enum "GDI Method"; var GDIProblem: enum "GDI Problem"; var ErrorValue: Text)
    begin
        GDIMethod := CurrentMethod;
        GDIProblem := CurrentProblem;
        ErrorValue := CurrentErrorValue;
    end;

    procedure InitSetup()
    var
        GDISetup: Record "GDI Setup";
        GDIJsonHelper: Codeunit "GDI Json Helper";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        IStream: InStream;
        ClientFileName: Text;
        JsonText: Text;
        JsonObj: JsonObject;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GDIErrorHandler.ThrowFileUploadErr(ClientFileName);

        if not JsonObj.ReadFrom(IStream) then
            GDIErrorHandler.ThrowJsonReadErr(ClientFileName);

        if not JsonObj.Contains(GDITokens.Installed()) then
            GDIErrorHandler.ThrowJsonStructureErr(ClientFileName);

        JsonText := GDIJsonHelper.GetObjectValueFromJson(JsonObj, GDITokens.Installed());
        if not JsonObj.ReadFrom(JsonText) then
            GDIErrorHandler.ThrowJsonStructureErr(ClientFileName);

        GDISetup.Reset();
        GDISetup.DeleteAll();
        GDISetup.Init();
        GDISetup.Validate(ClientID, GDIJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.ClientID()));
        GDISetup.Validate(ClientSecret, GDIJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.ClientSecret()));
        GDISetup.Validate(AuthURI, GDIJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.AuthUri()));
        GDISetup.Validate(TokenURI, GDIJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.TokenUri()));
        GDISetup.Validate(ProjectID, GDIJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.ProjectID()));
        GDISetup.Validate(AuthProvider, GDIJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.AuthProviderX509CertUrl()));
        GDISetup.Validate(RedirectURI, GetRedirectUri());
        GDISetup.Validate(AuthScope, AuthScopeTxt);
        GDISetup.Validate(APIScope, APIScopeTxt);
        GDISetup.Validate(APIUploadScope, APIUploadScopeTxt);
        GDISetup.TestMandatoryAuthFields();
        GDISetup.Insert();
    end;

    local procedure CalcLifeTime(ExpiresIn: Text; OldLifeTime: Integer): Integer
    var
        ExpiresInInt: Integer;
    begin
        // if evaluate fails just return 0, as we don't need errors
        if Evaluate(ExpiresInInt, ExpiresIn) then begin
            if OldLifeTime < ExpiresInInt then
                exit(OldLifeTime);
            exit(ExpiresInInt div 2);
        end;
        exit(0);
    end;

    local procedure ClearError()
    begin
        CurrentProblem := CurrentProblem::Undefined;
        CurrentMethod := CurrentMethod::Undefined;
        Clear(CurrentErrorValue);
    end;

    local procedure GetRedirectUri(): Text
    begin
        // Endpoint for OAuth 2.0 redirect
        // Company Name must be empty on prem, or Google will refuse to redirect to this URI (weird).
        // TODO: check in Azure.
        exit(System.GetUrl(CurrentClientType, '', ObjectType::Page, Page::"GDI Auth Mini-Page"));
    end;

    local procedure SetError(GDIProblem: enum "GDI Problem"; GDIMethod: Enum "GDI Method"; ErrorValue: Text)
    begin
        ClearError();
        CurrentProblem := GDIProblem;
        CurrentMethod := GDIMethod;
        CurrentErrorValue := ErrorValue;
    end;

    var
        APIScopeTxt: Label 'https://www.googleapis.com/drive/v3/files';
        APIUploadScopeTxt: Label 'https://www.googleapis.com/upload/drive/v3/files';
        AuthScopeTxt: Label 'https://www.googleapis.com/auth/drive';
        DialogTitleUploadTxt: Label 'File Upload';
        UrlWithParamsTok: Label '%1?%2', Comment = '%1 = Url; %2 = parameters'; // duplicate
        CurrentProblem: enum "GDI Problem";
        CurrentMethod: enum "GDI Method";
        CurrentErrorValue: text;
}