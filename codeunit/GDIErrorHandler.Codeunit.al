codeunit 50111 "GDI Error Handler"
{
    procedure GetError(var Method: Enum "GDI Method"; var Problem: Enum "GDI Problem"; var ErrorValue: Text)
    begin
        Method := CurrentMethod;
        Problem := CurrentProblem;
        ErrorValue := CurrentErrorValue;
    end;

    procedure ResponseHasError(Method: Enum "GDI Method"; ResponseText: Text): Boolean
    var
        GDIJsonHelper: Codeunit "GDI Json Helper";
        ResponseJson: JsonObject;
        Problem: Enum "GDI Problem";
        ErrorValue: Text;
    begin
        ClearError();
        ClearLastError();
        If ResponseText = '' then
            exit(false); // no errors

        if not ResponseJson.ReadFrom(ResponseText) then begin
            LogError(Problem::JsonRead, Method, ResponseText);
            ClearLastError();
            exit(true); // json parsing is an error
        end;


        if GDIJsonHelper.GetErrorValueFromJson(ErrorValue, ResponseJson) then begin
            ClearLastError();
            if Method = Method::Authorize then
                Error('%1 Error: %2', Format(Method), ErrorValue);

            case (ErrorValue) of
                '0':
                    Problem := Problem::Timeout;
                '404':
                    Problem := Problem::NotFound;
                Format(Problem::JsonRead):
                    Problem := Problem::JsonRead;
                Format(Problem::MissingFileID):
                    Problem := Problem::MissingFileID;
                else
                    Problem := Problem::Undefined;
            end;
            if Problem in [Problem::JsonRead, Problem::Undefined] then
                ErrorValue := ResponseText;
            LogError(Problem, Method, ErrorValue);
            exit(true);
        end;
        exit(false);
    end;

    procedure ThrowBadParameterErr(FunctionName: Text; ParameterVariant: Variant)
    begin
        Error(BadParameterErr, FunctionName, Format(ParameterVariant, 0, 9));
    end;

    procedure ThrowJsonReadErr(FileName: Text)
    begin
        Error(JsonReadErr, FileName);
    end;

    procedure ThrowJsonStructureErr(FileName: Text)
    begin
        Error(JsonStructureErr, FileName);
    end;

    procedure ThrowEvaluateError(StringName: Text; StringValue: Text; ToTypeName: Text)
    begin
        Error(EvaluateFailErr, StringName, StringValue, ToTypeName);
    end;

    procedure ThrowFileNameMissingErr()
    begin
        Error(FileNameMissingErr);
    end;

    procedure ThrowFileIDMissingErr()
    begin
        Error(FileIDMissingErr);
    end;

    procedure ThrowFileUploadErr(FileName: Text)
    begin
        Error(FileUploadErr, FileName);
    end;

    procedure ThrowNotImplementedErr()
    begin
        Error(NotImplementedErr);
    end;

    procedure ThrowValueOutOfRange(Name: Text; Val: Text; LowMargin: Text; HighMargin: Text)
    begin
        Error(ValueOutOfRangeErr, Name, Val, LowMargin, HighMargin);
    end;

    local procedure ClearError()
    begin
        CurrentProblem := CurrentProblem::Undefined;
        CurrentMethod := CurrentMethod::Undefined;
        Clear(CurrentErrorValue);
    end;

    local procedure LogError(Problem: Enum "GDI Problem"; Method: Enum "GDI Method"; ErrorValue: Text)
    begin
        ClearError();
        CurrentProblem := Problem;
        CurrentMethod := Method;
        CurrentErrorValue := ErrorValue;
    end;

    var
        BadParameterErr: Label '%1 says: bad parameter value %2.', Comment = '%1 = function, %2 = parameter value';
        EvaluateFailErr: Label 'Failed to evaluate %1=%2 into %3 type.', Comment = '%1 = Variable/field name; %2 = Variable/field value; %3 = Target type';
        FileNameMissingErr: Label 'File name was not specified.';
        FileIDMissingErr: Label 'File ID was not specified.';
        FileUploadErr: Label 'Cannot upload file %1 into stream.', Comment = '%1 = File name';
        JsonReadErr: Label 'Cannot read file %1 as json.', Comment = '%1 = File name';
        JsonStructureErr: Label 'Wrong json structure in %1. Please, check recent Google Drive API updates.', Comment = '%1 = File name, http content, text variable, etc';
        NotImplementedErr: Label 'Not implemented.';
        ValueOutOfRangeErr: Label '%1 %2 is out of range [%3 .. %4]', Comment = '%1 = Variable/field name; %2 = Variable/field value; %3 = low margin; %4 = high margin';
        CurrentProblem: Enum "GDI Problem";
        CurrentMethod: Enum "GDI Method";
        CurrentErrorValue: text;
}