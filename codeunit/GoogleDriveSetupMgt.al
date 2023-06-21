codeunit 50100 "Google Drive Setup Mgt."
{
    Description = 'Manages Google Drive Setup.';

    procedure Authorize()
    var
        Method: enum GDMethod;
    begin
        Authorize(Method::Authorize);
    end;

    procedure Authorize(Method: enum GDMethod)
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        Problem: Enum GDProblem;
        ResponseJson: JsonObject;
        RequestParams: Text;
        ResponseText: Text;
        ErrorValue: Text;
        RequestSentAtUTC: DateTime;
    begin
        GoogleDriveSetup.Get();
        if GoogleDriveSetup.AccessTokenIsAlive() then
            exit;

        GoogleDriveSetup.TestMandatoryAuthFields();
        if GoogleDriveSetup.Active then
            RequestParams := GoogleDriveRequestHandler.CreateRequestParamsRefreshToken()
        else begin
            if GoogleDriveSetup.AuthCode = '' then begin
                RequestParams := GoogleDriveRequestHandler.CreateRequestParamsRedirect();
                System.Hyperlink(StrSubstNo('%1?%2', GoogleDriveSetup.AuthURI, RequestParams));
                exit;
            end;
            RequestParams := GoogleDriveRequestHandler.CreateRequestParamsAuthCode();
        end;

        RequestSentAtUTC := System.CurrentDateTime();
        ResponseText := GoogleDriveRequestHandler.RequestAccessToken(RequestParams);

        if GoogleDriveErrorHandler.ResponseHasError(Method, ResponseText) then begin
            GoogleDriveErrorHandler.GetError(Method, Problem, ErrorValue);
            SetError(Problem, Method, ErrorValue);
            exit;
        end;

        ResponseJson.ReadFrom(ResponseText);
        Clear(GoogleDriveSetup.AuthCode);
        GoogleDriveSetup.Validate(AccessToken, GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.AccessToken()));
        GoogleDriveSetup.Validate(TokenType, GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.TokenType()));
        GoogleDriveSetup.Validate(IssuedUtc, RequestSentAtUTC);
        GoogleDriveSetup.Validate(ExpiresIn, GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.ExpiresIn()));
        GoogleDriveSetup.Validate(LifeTime, CalcLifetime(GoogleDriveSetup.ExpiresIn, GoogleDriveSetup.LifeTime));
        if not GoogleDriveSetup.Active then begin
            GoogleDriveSetup.Validate(RefreshToken,
                GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, GDITokens.RefreshToken()));
            GoogleDriveSetup.Validate(Active, true);
        end;
        GoogleDriveSetup.Modify(true);
    end;

    procedure GetError(var Method: enum GDMethod; var Problem: enum GDProblem; var ErrorValue: Text)
    begin
        Method := CurrentMethod;
        Problem := CurrentProblem;
        ErrorValue := CurrentErrorValue;
    end;

    procedure InitSetup()
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        GDITokens: Codeunit "GDI Tokens";
        IStream: InStream;
        ClientFileName: Text;
        JsonText: Text;
        JsonObj: JsonObject;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GoogleDriveErrorHandler.ThrowFileUploadErr(ClientFileName);

        if not JsonObj.ReadFrom(IStream) then
            GoogleDriveErrorHandler.ThrowJsonReadErr(ClientFileName);

        if not JsonObj.Contains(GDITokens.Installed()) then
            GoogleDriveErrorHandler.ThrowJsonStructureErr(ClientFileName);

        JsonText := GoogleDriveJsonHelper.GetObjectValueFromJson(JsonObj, GDITokens.Installed());
        if not JsonObj.ReadFrom(JsonText) then
            GoogleDriveErrorHandler.ThrowJsonStructureErr(ClientFileName);

        GoogleDriveSetup.Reset();
        GoogleDriveSetup.DeleteAll();
        GoogleDriveSetup.Init();
        GoogleDriveSetup.Validate(ClientID, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.ClientID()));
        GoogleDriveSetup.Validate(ClientSecret, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.ClientSecret()));
        GoogleDriveSetup.Validate(AuthURI, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.AuthUri()));
        GoogleDriveSetup.Validate(TokenURI, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.TokenUri()));
        GoogleDriveSetup.Validate(ProjectID, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.ProjectID()));
        GoogleDriveSetup.Validate(AuthProvider,
            GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, GDITokens.AuthProviderX509CertUrl()));
        GoogleDriveSetup.Validate(RedirectURI, GetRedirectUri());
        GoogleDriveSetup.Validate(AuthScope, AuthScopeTxt);
        GoogleDriveSetup.Validate(APIScope, APIScopeTxt);
        GoogleDriveSetup.Validate(APIUploadScope, APIUploadScopeTxt);
        GoogleDriveSetup.TestMandatoryAuthFields();
        GoogleDriveSetup.Insert();
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
        exit(System.GetUrl(CurrentClientType, '', ObjectType::Page, Page::"Google Drive Auth Mini Page"));
    end;

    local procedure SetError(Problem: enum GDProblem; Method: Enum GDMethod; ErrorValue: Text)
    begin
        ClearError();
        CurrentProblem := Problem;
        CurrentMethod := Method;
        CurrentErrorValue := ErrorValue;
    end;

    var
        APIScopeTxt: Label 'https://www.googleapis.com/drive/v3/files';
        APIUploadScopeTxt: Label 'https://www.googleapis.com/upload/drive/v3/files';
        AuthScopeTxt: Label 'https://www.googleapis.com/auth/drive';
        DialogTitleUploadTxt: Label 'File Upload';
        CurrentProblem: enum GDProblem;
        CurrentMethod: enum GDMethod;
        CurrentErrorValue: text;
}