page 50100 "GDI Setup"
{
    AboutText = 'You can configure Google Drive integration settings.';
    AboutTitle = 'Google Drive Setup';
    AdditionalSearchTerms = 'Gallery, Google, Drive, Setup';
    ApplicationArea = All;
    Caption = 'Google Drive Setup';
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    RefreshOnActivate = true; // TODO: check, it has issues
    SourceTable = "GDI Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(Active; Rec.Active)
            {
                ApplicationArea = All;
                Editable = true;
                ToolTip = 'Specifies that record is active.';
            }
            group(Client)
            {

                field("Client ID"; Rec.ClientID)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Client ID received from the client secret file.';
                }
                field("Client Secret"; Rec.ClientSecret)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Client secret received from the client secret file.';
                }
                field("Redirect URI"; Rec.RedirectURI)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies the redirect URI for OAuth 2.0 consent screen.';
                }
            }
            group(API)
            {
                field("Life Time"; Rec.LifeTime)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies the refresh time of the Access Token in seconds.';
                }

                field("Auth URI"; Rec.AuthUri)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Google OAuth 2.0 consent screen URI.';
                }
                field("Token URI"; Rec.TokenURI)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Google OAuth 2.0 endpoint required to exchange the authorization code for token.';
                }
                field("Auth Scope"; Rec.AuthScope)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Google OAuth 2.0 endpoint required to refresh the access token.';
                }
                field("API Scope"; Rec.APIScope)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Google Drive API endpoint for metadata and download.';
                }

                field("API Upload Scope"; Rec.APIUploadScope)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Google Drive API endpoint for upload.';
                }
            }
            group(Authorization)
            {
                Visible = false;
                field("Access Token"; Rec.AccessToken)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Access Token required for all Google Drive API requests.';
                }
                field("Refresh Token"; Rec.RefreshToken)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Refresh Token required to request a fresh Access Token.';
                }
                field("Expires in"; Rec.ExpiresIn)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Default access token expiration time.';
                }
                field("Token Type"; Rec.TokenType)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Default token type.';
                }
            }

            group(Cache)
            {
                Visible = true;
                field(CacheSize; Rec.CacheSize)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the cache size limit in megabytes.';
                }
                field(CacheWarning; Rec.CacheWarning)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the minimum percent of the cache to stop automatic cache cleaning.';

                }
                field(GracePeriod; Rec.GracePeriod)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the period when media is considered new. Affects the automatic cache cleaning.';
                }
                field(ClearAllBelowRank; Rec.ClearAllBelowRank)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the minimum rank for the cache cleaner to start checking the necessity of cleaning.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action("Init Setup")
            {
                ApplicationArea = All;
                Caption = 'Init';
                Image = New;
                ToolTip = 'Upload the client secret file received from Google Drive API and populate the setup.';

                trigger OnAction()
                var
                    GDISetupMgt: Codeunit "GDI Setup Mgt.";
                begin
                    GDISetupMgt.InitSetup();
                end;
            }
            action("Activate Setup")
            {
                ApplicationArea = All;
                Caption = 'Activate';
                Image = Apply;
                ToolTip = 'Open Google Drive authorization screen and authorize Business Central to work with Google Drive.';
                // TODO: bad design, shan't be here
                // TODO: move it to Active.OnValidate?
                trigger OnAction()
                var
                    GDISetup: Record "GDI Setup";
                    GDISetupMgt: Codeunit "GDI Setup Mgt.";
                    OldToken: Text;
                    OldStatus: Boolean;
                begin
                    OldToken := Rec.AccessToken;
                    OldStatus := Rec.Active;
                    GDISetupMgt.Authorize();
                    CurrPage.Update(false);
                    GDISetup.Get();
                    if OldStatus and GDISetup.Active then
                        if OldToken = GDISetup.AccessToken then
                            Message(OldTokenAliveTxt)
                        else
                            Message(TokenRefreshedTxt);
                end;
            }

        }
        area(Promoted)
        {
            actionref(Init_Ref; "Init Setup")
            {

            }
            actionref(Activate_Ref; "Activate Setup")
            {

            }
        }

    }
    var
        OldTokenAliveTxt: Label 'The existing access token is still valid. No need to refresh.';
        TokenRefreshedTxt: Label 'Access token was successfully refreshed!';
}