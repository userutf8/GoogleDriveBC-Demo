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
    RefreshOnActivate = true;
    SourceTable = "Google Drive Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(Active; Rec.Active)
            {
                Editable = true;
            }
            group(Client)
            {

                field("Client ID"; Rec.ClientID)
                {

                }
                field("Client Secret"; Rec.ClientSecret)
                {

                }
                field("Redirect URI"; Rec.RedirectURI)
                {

                }
            }
            group(Defaults)
            {
                field("Auth URI"; Rec.AuthUri)
                {

                }
                field("Token URI"; Rec.TokenURI)
                {

                }
                field("Auth Scope"; Rec.AuthScope)
                {

                }
                field("API Scope"; Rec.APIScope)
                {

                }

                field("API Upload Scope"; Rec.APIUploadScope)
                {

                }
            }
            group(Authentication)
            {
                Visible = false;
                field("Access Token"; Rec.AccessToken)
                {

                }
                field("Refresh Token"; Rec.RefreshToken)
                {

                }
                field("Expires in"; Rec.ExpriresIn)
                {

                }
                field("Token Type"; Rec.TokenType)
                {

                }

                field("Authentication Code"; Rec.AuthCode)
                {

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
                Caption = 'Init';
                Image = New;
                ToolTip = 'Upload the client secret file (Google Drive API) and populate the setup with its values.';
                trigger OnAction()
                var
                    GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
                begin
                    GoogleDriveSetupMgt.InitSetup();
                end;
            }
            action("Activate Setup")
            {
                Caption = 'Activate';
                Image = Apply;
                ToolTip = 'Open Google authorization screen and authorize Business Central to work with Google Drive.';
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
                    if OldStatus and GoogleDriveSetup.Active then
                        if OldToken <> GoogleDriveSetup.AccessToken then
                            Message(TokenRefreshedTxt); // TODO replace by notification?
                end;
            }

            action("Clear Auth Code")
            {
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
        TokenRefreshedTxt: Label 'Access token was successfully refereshed!';
}