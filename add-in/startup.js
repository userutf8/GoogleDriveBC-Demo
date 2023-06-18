// reads URL and checks for parameter 'code'. Returns its value on success.
var params = new URLSearchParams(window.location.search);
var codeFound = params.has('code');
var codeValue;
if (codeFound)
    codeValue = params.get('code');
else
    codeValue = "";
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("GetAuthCode", [codeValue]); // control is ready
