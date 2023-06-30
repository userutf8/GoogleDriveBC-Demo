controladdin "GDI Auth Add-In"
{
    HorizontalShrink = true;
    HorizontalStretch = true;
    MaximumHeight = 1;
    MaximumWidth = 1;
    MinimumHeight = 1;
    MinimumWidth = 1;
    RequestedHeight = 1;
    RequestedWidth = 1;
    StartupScript = 'add-in/startup.js';
    VerticalShrink = true;
    VerticalStretch = true;

    event GetAuthCode(AuthCode: Text)

    procedure MyProcedure()
}