codeunit 50110 "Google Drive Setup Mgt."
{
    Description = 'Manages Google Drive Setup.';
    procedure InitSetup()
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        IStream: InStream;
        ClientFileName: Text;
        JsonText: Text;
        JsonObj: JsonObject;
    begin
        if not File.UploadIntoStream(DialogTitleUploadTxt, '', '', ClientFileName, IStream) then
            GoogleDriveErrorHandler.ThrowFileUploadErr(ClientFileName);

        if not JsonObj.ReadFrom(IStream) then
            GoogleDriveErrorHandler.ThrowJsonReadErr(ClientFileName);

        if not JsonObj.Contains(Tokens.Installed) then
            GoogleDriveErrorHandler.ThrowJsonStructureErr(ClientFileName);

        JsonText := GoogleDriveJsonHelper.GetObjectValueFromJson(JsonObj, Tokens.Installed);
        if not JsonObj.ReadFrom(JsonText) then
            GoogleDriveErrorHandler.ThrowJsonStructureErr(ClientFileName);

        GoogleDriveSetup.Reset();
        GoogleDriveSetup.DeleteAll();
        GoogleDriveSetup.Init();
        GoogleDriveSetup.Validate(ClientID, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, Tokens.ClientID));
        GoogleDriveSetup.Validate(ClientSecret, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, Tokens.ClientSecret));
        GoogleDriveSetup.Validate(AuthURI, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, Tokens.AuthUri));
        GoogleDriveSetup.Validate(TokenURI, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, Tokens.TokenUri));
        GoogleDriveSetup.Validate(ProjectID, GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, Tokens.ProjectID));
        GoogleDriveSetup.Validate(AuthProvider,
            GoogleDriveJsonHelper.GetTextValueFromJson(JsonObj, Tokens.AuthProviderX509CertUrl));
        GoogleDriveSetup.Validate(RedirectURI, GetRedirectUri);
        GoogleDriveSetup.Validate(AuthScope, AuthScopeTxt);
        GoogleDriveSetup.Validate(APIScope, APIScopeTxt);
        GoogleDriveSetup.Validate(APIUploadScope, APIUploadScopeTxt);
        GoogleDriveSetup.TestMandatoryAuthFields();
        GoogleDriveSetup.Insert();
    end;

    procedure Authorize()
    var
        GoogleDriveSetup: Record "Google Drive Setup";
        GoogleDriveRequestHandler: Codeunit "Google Drive Request Handler";
        GoogleDriveJsonHelper: Codeunit "Google Drive Json Helper";
        GoogleDriveErrorHandler: Codeunit "Google Drive Error Handler";
        Tokens: Codeunit "Google Drive API Tokens";
        ResponseJson: JsonObject;
        RequestParams: Text;
        ResponseText: Text;
    begin
        GoogleDriveSetup.Get;
        if not GoogleDriveSetup.TokenExpired() then
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
        ResponseText := GoogleDriveRequestHandler.RequestAccessToken(RequestParams);
        GoogleDriveErrorHandler.HandleErrors(Tokens.AuthorizeLbl, ResponseText);

        ResponseJson.ReadFrom(ResponseText);
        Clear(GoogleDriveSetup.AuthCode);
        GoogleDriveSetup.Validate(AccessToken, GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.AccessToken));
        GoogleDriveSetup.Validate(ExpriresIn, GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.ExpiresIn));
        GoogleDriveSetup.Validate(TokenType, GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.TokenType));
        GoogleDriveSetup.Validate(Issued, Format(CurrentDateTime, 9));
        if not GoogleDriveSetup.Active then begin
            GoogleDriveSetup.Validate(RefreshToken,
                GoogleDriveJsonHelper.GetTextValueFromJson(ResponseJson, Tokens.RefreshToken));
            GoogleDriveSetup.Validate(Active, true);
        end;
        GoogleDriveSetup.Modify(true);
    end;

    local procedure GetRedirectUri(): Text
    begin
        // Endpoint for OAuth 2.0 redirect
        // Company Name must be empty on prem, or Google will refuse to redirect to this URI (weird).
        // TODO: check in Azure.
        exit(System.GetUrl(CurrentClientType, '', ObjectType::Page, Page::"Google Drive Auth Mini Page"));
    end;

    var
        APIScopeTxt: Label 'https://www.googleapis.com/drive/v3/files';
        APIUploadScopeTxt: Label 'https://www.googleapis.com/upload/drive/v3/files';
        AuthScopeTxt: Label 'https://www.googleapis.com/auth/drive';
        DialogTitleUploadTxt: Label 'File Upload';

}