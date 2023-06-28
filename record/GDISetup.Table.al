table 50100 "GDI Setup"
{
    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Description = 'Unique identifier of the setup. Must be 0.';
            InitValue = 0;

            trigger OnValidate()
            begin
                TestField(ID, 0);
            end;
        }
        field(2; Active; Boolean)
        {
            Caption = 'Active';
            Description = 'Specifies that the setup is active.';
            InitValue = false;

            trigger OnValidate()
            begin
                if Active = true then
                    TestField(RefreshToken)
                else
                    if xRec.Active = true then
                        ClearTokens();
            end;

        }
        field(3; ClientID; Text[1024])
        {
            Caption = 'Client ID';
            Description = 'Specifies the unique client_id uploaded from Google Drive API client secret file.';
        }
        field(4; ProjectID; Text[1024])
        {
            Caption = 'Project ID';
            Description = 'Specifies the unique project_id uploaded from Google Drive API client secret file. Not mandatory.';
        }
        field(5; AuthURI; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Auth URI';
            Description = 'Specifies the auth_uri uploaded from Google Drive API client secret file.';
        }
        field(6; TokenURI; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Token URI';
            Description = 'Specifies the token_uri uploaded from Google Drive API client secret file.';
        }
        field(7; AuthProvider; Text[1024])
        {
            Caption = 'Auth Provider';
            Description = 'Specifies the auth_provider_x509_cert_url uploaded from Google Drive API client secret file. Not mandatory.';
        }
        field(8; ClientSecret; Text[1024])
        {
            Caption = 'Client Secret';
            Description = 'Specifies the unique client_secret uploaded from Google Drive API client secret file.';
        }
        field(9; RedirectURI; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Redirect URI';
            Description = 'Specifies the redirect_uri required to obtain an authorization code. On init setup it defaults to Google Drive Auth Mini Page.';
        }
        field(10; AccessToken; Text[2048])
        {
            Caption = 'Access Token';
            Description = 'Specifies the access_token received from Google OAuth2.0 API. Required for all Google Drive API requests.';
        }
        field(11; TokenType; Text[1024])
        {
            Caption = 'Token Type';
            Description = 'Specifies the token_type received from Google OAuth2.0 API. Defaults to "Bearer".';
        }
        field(12; ExpiresIn; Text[1024])
        {
            Caption = 'Expires in (seconds)';
            Description = 'Specifies expires_in value received from Google OAuth2.0 API. The default lifetime in seconds of the access token.';
        }
        field(13; RefreshToken; Text[2048])
        {
            Caption = 'Refresh Token';
            Description = 'Specifies the refresh_token received from Google OAuth2.0 API. Required to refresh an Access Token.';
            trigger OnValidate()
            begin
                if (RefreshToken = '') and (xRec.RefreshToken <> '') then
                    Validate(Active, false);
            end;
        }
        field(14; AuthScope; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Scope (authorization)';
            Description = 'Specifies the authorization scope URI. Required to authorize an app to access Google Drive API.';
            trigger OnValidate()
            begin
                if AuthScope <> xRec.AuthScope then
                    ClearTokens();
            end;
        }
        field(15; LifeTime; Integer)
        {
            Caption = 'Token Life Time';
            Description = 'Specifies the Access Token life time in seconds.';
            InitValue = 3600;

            trigger OnValidate()
            var
                Field: Record Field;
                GDIErrorHandler: Codeunit "GDI Error Handler";
                ExpiresInInt: Integer;
            begin
                if not Evaluate(ExpiresInInt, ExpiresIn) then
                    GDIErrorHandler.ThrowEvaluateError(FieldCaption(ExpiresIn), ExpiresIn, Format(Field.Type::Integer));

                if (LifeTime < 0) or (LifeTime > ExpiresInInt) then
                    GDIErrorHandler.ThrowValueOutOfRange(FieldCaption(LifeTime), Format(LifeTime), '0', ExpiresIn);
            end;

        }
        field(16; IssuedUtc; DateTime)
        {
            Caption = 'Issued DateTime (UTC)';
            Description = 'Specifies the UTC timestamp for the last Access Token request.';
        }
        field(17; AuthCode; Text[2048])
        {
            Caption = 'Auth Code';
            Description = 'Specifies the code obtained from the redirect URI endpoint listener after redirect from OAuth consent screen.';
        }
        field(18; APIScope; text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Scope (API)';
            Description = 'Specifies the API scope (URI). Required for API requests.';
        }
        field(19; APIUploadScope; text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Upload Scope (API)';
            Description = 'Specifies the API upload scope (URI). Required for API requests, when you send a file.';
        }
        field(20; CacheSize; Decimal)
        {
            Caption = 'Cache size (MB)';
            DecimalPlaces = 0 : 2;
            InitValue = 1024.0; // 1 GB
            MaxValue = 10240.0; // 10 GB
            MinValue = 0.0;
        }
        field(21; CacheWarning; Integer)
        {
            Caption = 'Cache warning (%)';
            InitValue = 90;
            MaxValue = 100;
            MinValue = 50;
        }
        field(22; GracePeriod; Text[128])
        {
            Caption = 'Grace period';
            InitValue = '7 days';
            trigger OnValidate()
            var
                TestDuration: Duration;
            begin
                Evaluate(TestDuration, GracePeriod)
            end;
        }
        field(23; ClearAllBelowRank; Integer)
        {
            Caption = 'Clear all below rank';
            InitValue = 3;
            MinValue = 1;
            MaxValue = 100;
        }

    }

    keys
    {
        key(PK; ID)
        {
            Clustered = false;
        }
    }

    var
        RecExistsErr: Label 'Record already exists. You can update or delete this record.';
        RenameErr: Label 'You cannot rename this record.';

    trigger OnInsert()
    var
        GDISetup: Record "GDI Setup";
    begin
        GDISetup.Reset();
        if not GDISetup.IsEmpty() then
            Error(RecExistsErr);

        ID := 0;
    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin
        Error(RenameErr);
    end;

    procedure ClearTokens()
    begin
        Clear(AccessToken);
        Clear(RefreshToken);
        Clear(ExpiresIn);
        Clear(IssuedUtc);
        Clear(AuthCode);
        Active := false;
    end;

    procedure TestMandatoryAuthFields()
    begin
        TestField(ClientID);
        TestField(ClientSecret);
        TestField(AuthURI);
        TestField(RedirectURI);
        TestField(AuthScope);
        TestField(TokenURI);
    end;

    procedure AccessTokenIsAlive(): Boolean
    var
        RemainingTime: Duration;
    begin
        if IssuedUtc <> 0DT then begin
            RemainingTime := (LifeTime * 1000) - (System.CurrentDateTime() - Rec.IssuedUtc);
            if RemainingTime > 0 then
                exit(true);
        end;
        exit(false);
    end;
}