page 50110 "Google Drive Setup"
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
    SourceTable = "Google Drive Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(Active; Rec.Active)
            {
                ApplicationArea = All;
                Editable = true;
            }
            group(Client)
            {

                field("Client ID"; Rec.ClientID)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Client Secret"; Rec.ClientSecret)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Redirect URI"; Rec.RedirectURI)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
            }
            group(API)
            {
                field("Life Time"; Rec.LifeTime)
                {
                    ApplicationArea = All;
                    Editable = true;
                }

                field("Auth URI"; Rec.AuthUri)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Token URI"; Rec.TokenURI)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Auth Scope"; Rec.AuthScope)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("API Scope"; Rec.APIScope)
                {
                    ApplicationArea = All;
                    Editable = true;
                }

                field("API Upload Scope"; Rec.APIUploadScope)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
            }
            group(Authentication)
            {
                Visible = false;
                field("Access Token"; Rec.AccessToken)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Refresh Token"; Rec.RefreshToken)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Expires in"; Rec.ExpiresIn)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Token Type"; Rec.TokenType)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Authentication Code"; Rec.AuthCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'This field is expected to be empty most of the time.';
                    Editable = false;
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
                    GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
                begin
                    GoogleDriveSetupMgt.InitSetup();
                end;
            }
            action("Activate Setup")
            {
                ApplicationArea = All;
                Caption = 'Activate';
                Image = Apply;
                ToolTip = 'Open Google Drive authorization screen and authorize Business Central to work with Google Drive.';
                // TODO: move it to Active.OnValidate?
                trigger OnAction()
                var
                    GoogleDriveSetup: Record "Google Drive Setup";
                    GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
                    OldToken: Text;
                    OldStatus: Boolean;
                begin
                    OldToken := Rec.AccessToken;
                    OldStatus := Rec.Active;
                    GoogleDriveSetupMgt.Authorize();
                    CurrPage.Update(false);
                    GoogleDriveSetup.Get();
                    if OldStatus and GoogleDriveSetup.Active then begin
                        if OldToken = GoogleDriveSetup.AccessToken then
                            Message(OldTokenAliveTxt)
                        else
                            Message(TokenRefreshedTxt); // TODO replace by notification?
                    end;
                end;
            }

            action("Clear Auth Code")
            {
                ApplicationArea = All;
                ToolTip = 'Clear authorization code manually.';

                trigger OnAction()
                begin
                    Clear(Rec.AuthCode);
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