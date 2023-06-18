controladdin "Google Drive Auth Add-In"
{
    RequestedHeight = 1;
    MinimumHeight = 1;
    MaximumHeight = 1;
    RequestedWidth = 1;
    MinimumWidth = 1;
    MaximumWidth = 1;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;
    StartupScript = 'add-in/startup.js';

    event GetAuthCode(AuthCode: Text)

    procedure MyProcedure()
}