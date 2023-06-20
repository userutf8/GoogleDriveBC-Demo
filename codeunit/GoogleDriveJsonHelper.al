codeunit 50120 "Google Drive Json Helper"
{
    trigger OnRun()
    begin

    end;

    procedure GetTextValueFromJson(jsonObj: JsonObject; tokenName: Text): Text
    var
        jToken: JsonToken;
        jValue: JsonValue;
    begin
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
        if not jsonObj.Get(tokenName, jToken) then
            exit('');

        jObj := jToken.AsObject();
        jObj.WriteTo(ObjText);
        exit(ObjText);
    end;

}