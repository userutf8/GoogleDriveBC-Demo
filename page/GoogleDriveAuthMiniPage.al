page 50111 "Google Drive Auth Mini Page"
{
    ApplicationArea = All;
    Caption = 'Google Drive Authorization';
    Editable = false;
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Status; Status)
            {
                ApplicationArea = All;
                ShowCaption = false;
                Style = Strong;
            }
            field(Hint; Hint)
            {
                ApplicationArea = All;
                ShowCaption = false;
            }
            usercontrol(GetAuthCode; "Google Drive Auth Add-In")
            {
                ApplicationArea = All;
                trigger GetAuthCode(AuthCode: Text)
                var
                    GoogleDriveSetup: Record "Google Drive Setup";
                    GoogleDriveSetupMgt: Codeunit "Google Drive Setup Mgt.";
                begin
                    Hint := CloseTabHintTxt;
                    Status := UnknownErr;

                    if AuthCode = '' then begin
                        GoogleDriveSetup.Get;
                        If GoogleDriveSetup.Active then
                            Status := AlreadyActiveTxt;
                    end else begin
                        GoogleDriveSetup.Get;
                        GoogleDriveSetup.Validate(AuthCode, AuthCode);
                        GoogleDriveSetup.Modify(true);
                        GoogleDriveSetupMgt.Authorize();
                        GoogleDriveSetup.Get;
                        If GoogleDriveSetup.Active then
                            Status := SuccessTxt
                        else
                            Status := AuthCompleteErr;
                    end;
                end;
            }
        }
    }
    var
        Status: Text;
        Hint: Text;
        CloseTabHintTxt: Label 'You can close this browser tab now.';
        SuccessTxt: Label 'Success! Setup is active.';
        AlreadyActiveTxt: Label 'Setup is already active.';
        UnknownErr: Label 'Oops! Something went wrong... Please, try again.';
        AuthCompleteErr: Label 'Auth code was received from Google Drive API, but authorization failed. Please, try again.';
}