table 50110 "Google Drive Setup"
{
    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Description = 'Unique identifier. Must be 0.';
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
            Description = 'Specifies the unique client_id uploaded from Google Drive API client secret file. Required for authorization requests.';
        }
        field(4; ProjectID; Text[1024])
        {
            Caption = 'Project ID';
            Description = 'Specifies the unique project_id uploaded from Google Drive API client secret file.';
        }
        field(5; AuthURI; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Auth URI';
            Description = 'Specifies the auth_uri uploaded from Google Drive API client secret file. Required for authorization requests.';
        }
        field(6; TokenURI; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Token URI';
            Description = 'Specifies the token_uri uploaded from Google Drive API client secret file. Required for authorization requests.';
        }
        field(7; AuthProvider; Text[1024])
        {
            Caption = 'Auth Provider';
            Description = 'Specifies the auth_provider_x509_cert_url uploaded from Google Drive API client secret file.';
        }
        field(8; ClientSecret; Text[1024])
        {
            Caption = 'Client Secret';
            Description = 'Specifies the unique client_secret uploaded from Google Drive API client secret file. Required for authorization requests.';
        }
        field(9; RedirectURI; Text[1024])
        {
            ExtendedDatatype = URL;
            Caption = 'Redirect URI';
            Description = 'Specifies the redirect_uri required to obtain an authorization code. You should provide the trusted URI, and (ideally) it should be an endpoint which can process GET responses (http listener URI).';
        }
        field(10; AccessToken; Text[2048])
        {
            Caption = 'Access Token';
            Description = 'Specifies the unique access_token received from Google OAuth2 API. Required for requests to Google Drive.';
        }
        field(11; TokenType; Text[1024])
        {
            Caption = 'Token Type';
            Description = 'Specifies the token_type received from Google OAuth2 API. Default value is "Bearer".';
        }
        field(12; ExpriresIn; Text[1024])
        {
            Caption = 'Expires in (seconds)';
            Description = 'Specifies optional expires_in value received from Google OAuth2 API. The lifetime in seconds of the access token.';
        }
        field(13; RefreshToken; Text[2048])
        {
            Caption = 'Refresh Token';
            Description = 'Specifies the unique refresh_token received from Google OAuth2 API. Required for authorization requests.';
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
            Description = 'Specifies the authorization scope (URI). Required for authorization requests.';
            trigger OnValidate()
            begin
                if AuthScope <> xRec.AuthScope then
                    ClearTokens();
            end;
        }
        field(15; Issued; Text[1024])
        {
            Caption = 'Issued DateTime';
            Description = 'Specifies the issued time of the access token.';
        }
        field(16; IssuedUtc; Text[1024])
        {
            Caption = 'Issued DateTime (UTC)';
            Description = 'Specifies the issued time (UTC) of the access token.';
        }
        field(17; AuthCode; Text[2048])
        {
            Caption = 'Auth Code';
            Description = 'Specifies the code value obtained from redirect URI. Note: this field is required for the http listener endpoint.';
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
            Description = 'Specifies the API upload scope (URI). Required for API upload requests.';
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
        RecExistsErr: Label 'Record already exists. You can choose to update or delete the old record.';

    trigger OnInsert()
    var
        GoogleDriveSetup: Record "Google Drive Setup";
    begin
        GoogleDriveSetup.Reset();
        if not GoogleDriveSetup.IsEmpty() then
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

    end;

    procedure ClearTokens()
    begin
        Clear(AccessToken);
        Clear(RefreshToken);
        Clear(ExpriresIn);
        Clear(Issued);
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

    procedure TokenExpired(): Boolean
    begin
        // TODO: implement
        exit(true);
    end;

}