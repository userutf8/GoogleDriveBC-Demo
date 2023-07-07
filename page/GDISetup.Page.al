page 50100 "GDI Setup"
{
    AboutText = 'You can configure Google Drive integration settings.';
    AboutTitle = 'Google Drive Setup';
    AdditionalSearchTerms = 'Gallery, Google, Drive, Setup';
    ApplicationArea = All;
    Caption = 'Google Drive Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
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
                ToolTip = 'Specifies that the setup is active.';
            }
            group(Client)
            {
                field("Client ID"; Rec.ClientID)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Client ID loaded from client secret file.';
                }
                field("Client Secret"; Rec.ClientSecret)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Client secret loaded from client secret file.';
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
                    ToolTip = 'Google OAuth 2.0 endpoint required to exchange the authorization code for the access token.';
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
                    ToolTip = 'Access Token is required for all Google Drive API requests.';
                }
                field("Refresh Token"; Rec.RefreshToken)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Refresh Token is required to request a fresh Access Token.';
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
                    ToolTip = 'Cache size limit in megabytes.';
                }
                field(CacheVolume; Rec.CacheVolume)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the minimum volume percent of the Cache for the automatic cleaner to stop cleaning.';
                }
                field(GracePeriod; Rec.GracePeriod)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the period when media is considered ''new''. New media is less likely to be cleaned than the older one.';
                }
                field(ClearAllBelowRank; Rec.ClearAllBelowRank)
                {
                    ApplicationArea = all;
                    Editable = true;
                    ToolTip = 'Specifies the minimum rank for the cache cleaner to stop bulk cleaning and start checking remaining size to clean.';
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
                    if Confirm(InitWarningTxt, true) then
                        GDISetupMgt.InitSetup();
                end;
            }

            action("Activate Setup")
            {
                ApplicationArea = All;
                Caption = 'Activate';
                Image = Apply;
                ToolTip = 'Open Google Drive authorization screen and authorize Business Central to work with Google Drive.';
                // INFO: this will be moved to Active.OnValidate
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

            action("Create Jobs")
            {
                ApplicationArea = all;
                Caption = 'Create Jobs';
                Image = Job;
                ToolTip = 'Create Job Queue entries for Queue and Cache handling';
                trigger OnAction()
                var
                    GDISetupMgt: Codeunit "GDI Setup Mgt.";
                    JobsCreatedNotification: Notification;
                begin
                    GDISetupMgt.CreateJobQueues();
                    JobsCreatedNotification.Scope := JobsCreatedNotification.Scope::LocalScope;
                    JobsCreatedNotification.Message(JobQueueEntriesCreatedTxt);
                    JobsCreatedNotification.AddAction(ViewTok, Codeunit::"GDI Setup Mgt.", 'ViewJobQueueEntries');
                    JobsCreatedNotification.Send();
                end;
            }

            action("Clear Cache")
            {
                ApplicationArea = all;
                Caption = 'Clear Cache';
                Image = Delete;
                ToolTip = 'Wipes all Media from Google Drive Media records.';
                trigger OnAction()
                var
                    GDIMedia: Record "GDI Media";
                    GDIMediaInfo: Record "GDI Media Info";
                begin
                    if not Confirm(ClearCacheQst, false) then
                        exit;

                    GDIMedia.Reset();
                    GDIMedia.FindSet();
                    repeat
                        Clear(GDIMedia.FileContent);
                        GDIMedia.Modify(true);
                    until GDIMedia.Next() = 0;
                    GDIMediaInfo.ModifyAll(FileSize, 0.0);
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
            actionref(CreateJobs_Ref; "Create Jobs")
            {
            }
        }
    }
    var
        InitWarningTxt: Label 'Warning! This action will clear all settings. Do you want to proceed?';
        OldTokenAliveTxt: Label 'The existing access token is still valid. No need to refresh.';
        TokenRefreshedTxt: Label 'Access token was successfully refreshed!';
        JobQueueEntriesCreatedTxt: Label 'Job Queue Entries are created.';
        ClearCacheQst: Label 'Warning: this action clears all media from Google Drive Media records.\Do you want to procceed?';
        ViewTok: Label 'View';
}