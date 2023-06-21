codeunit 50120 "Google Drive Json Helper"
{
    procedure GetErrorValueFromJson(var ErrorValue: Text; jsonObj: JsonObject): Boolean
    var
        Tokens: Codeunit "Google Drive API Tokens";
        Problem: Enum GDProblem;
    begin
        // returns true, if the error presents in Json or if Json failed to parse
        ClearLastError();
        TryGetTextValueFromJson(ErrorValue, jsonObj, Tokens.ErrorTok());
        if GetLastErrorText = '' then
            exit(ErrorValue <> '');

        ClearLastError();
        TryGetObjectValueFromJson(ErrorValue, jsonObj, Tokens.ErrorTok());
        if GetLastErrorText() = '' then begin
            TryGetTextValueFromJson(ErrorValue, jsonObj, Tokens.ErrorTok());
            if GetLastErrorText() = '' then
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