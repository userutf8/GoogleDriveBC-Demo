codeunit 50121 "GDI Tokens"
{
    Description = 'Google Drive Integration tokens and labels.';

    procedure AccessToken(): Text
    begin
        exit('access_token');
    end;

    procedure AltTok(): Text
    begin
        exit('alt');
    end;

    procedure Authorization(): Text
    begin
        exit('Authorization');
    end;

    procedure AuthorizationCode(): Text
    begin
        exit('authorization_code');
    end;

    procedure AuthProviderX509CertUrl(): Text
    begin
        exit('auth_provider_x509_cert_url');
    end;

    procedure AuthUri(): Text
    begin
        exit('auth_uri')
    end;

    procedure CodeTok(): Text
    var
    begin
        exit('code');
    end;

    procedure ClientID(): Text
    begin
        exit('client_id');
    end;

    procedure ClientSecret(): Text
    begin
        exit('client_secret');
    end;

    procedure ContentType(): Text
    begin
        exit('Content-Type');
    end;

    procedure GrantType(): Text
    begin
        exit('grant_type');
    end;

    procedure ErrorTok(): Text
    begin
        exit('error');
    end;

    procedure ExpiresIn(): Text
    begin
        exit('expires_in');
    end;

    procedure IdTok(): Text
    begin
        exit('id');
    end;

    procedure Installed(): Text
    begin
        exit('installed');
    end;

    procedure KeyTok(): Text
    begin
        exit('key');
    end;

    procedure MediaTok(): Text
    begin
        exit('media');
    end;

    procedure MimeTypeFormUrlEncoded(): Text
    begin
        exit('application/x-www-form-urlencoded');
    end;

    procedure MimeTypeJson(): Text
    begin
        exit('application/json');
    end;

    procedure MimeTypeJpeg(): Text
    begin
        exit('image/jpeg');
    end;

    procedure Name(): Text
    begin
        exit('name');
    end;

    procedure ProjectID(): Text
    begin
        exit('project_id');
    end;

    procedure RedirectUri(): Text
    begin
        exit('redirect_uri');
    end;

    procedure RefreshToken(): Text
    begin
        exit('refresh_token');
    end;

    procedure ResponseType(): Text
    begin
        exit('response_type');
    end;

    procedure Scope(): Text
    begin
        exit('scope');
    end;

    procedure TokenType(): Text
    begin
        exit('token_type');
    end;

    procedure TokenUri(): Text
    begin
        exit('token_uri');
    end;

    procedure UploadType(): Text
    begin
        exit('uploadType');
    end;
}