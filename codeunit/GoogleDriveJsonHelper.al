codeunit 50120 "Google Drive Json Helper"
{
    procedure GetErrorValueFromJson(var ErrorValue: Text; JsonObj: JsonObject): Boolean
    var
        InnerJsonObj: JsonObject;
        GDITokens: Codeunit "GDI Tokens";
        Problem: Enum GDProblem;
    begin
        // returns true, if the error presents in Json or if Json failed to parse
        if TryGetTextValueFromJson(ErrorValue, JsonObj, GDITokens.ErrorTok()) then
            exit(ErrorValue <> '');

        ClearLastError();
        if TryGetObjectValueFromJson(ErrorValue, JsonObj, GDITokens.ErrorTok()) then begin
            InnerJsonObj.ReadFrom(ErrorValue);
            if TryGetTextValueFromJson(ErrorValue, InnerJsonObj, GDITokens.CodeTok()) then
                exit(ErrorValue <> '');
        end;

        ErrorValue := Format(Problem::JsonRead);
        exit(true);
    end;

    procedure GetTextValueFromJson(jsonObj: JsonObject; tokenName: Text): Text
    var
        jToken: JsonToken;
        jValue: JsonValue;
    begin
        // unsafe call to get value from Json
        if not jsonObj.Get(tokenName, jToken) then
            exit('');

        jValue := jToken.AsValue();
        exit(jValue.AsText());
    end;

    procedure GetObjectValueFromJson(jsonObj: JsonObject; tokenName: Text): Text
    var
        jToken: JsonToken;
        jObj: JsonObject;
        ObjText: Text;
    begin
        // unsafe call to get object from Json
        if not jsonObj.Get(tokenName, jToken) then
            exit('');

        jObj := jToken.AsObject();
        jObj.WriteTo(ObjText);
        exit(ObjText);
    end;

    [TryFunction]
    procedure TryGetTextValueFromJson(var TextValue: Text; jsonObj: JsonObject; tokenName: Text)
    begin
        // wraps unsafe call
        TextValue := GetTextValueFromJson(jsonObj, tokenName);
    end;

    [TryFunction]
    procedure TryGetObjectValueFromJson(var TextValue: Text; jsonObj: JsonObject; tokenName: Text)
    begin
        // wraps unsafe call
        TextValue := GetObjectValueFromJson(jsonObj, tokenName);
    end;

}