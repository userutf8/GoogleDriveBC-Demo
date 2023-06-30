codeunit 50111 "GDI Error Handler"
{
    procedure GetError(var GDIMethod: Enum "GDI Method"; var GDIProblem: Enum "GDI Problem"; var GDIErrorValue: Text)
    begin
        GDIMethod := CurrentMethod;
        GDIProblem := CurrentProblem;
        GDIErrorValue := CurrentErrorValue;
    end;

    procedure HandleCurrentError(NotifyOnly: Boolean)
    begin
        if NotifyOnly = false then
            ThrowCurrentError();

        if CurrentMethod = CurrentMethod::GetFile then
            if not SendNotification(CurrentProblem) then
                ThrowCurrentError();
    end;

    procedure ResponseHasError(CallerMethod: Enum "GDI Method"; ResponseText: Text): Boolean
    var
        GDIJsonHelper: Codeunit "GDI Json Helper";
        ResponseJson: JsonObject;
        GDIProblem: Enum "GDI Problem";
        ErrorValue: Text;
    begin
        ClearError();
        ClearLastError();
        if ResponseText = '' then
            exit(false); // Empty response is ok

        if not ResponseJson.ReadFrom(ResponseText) then begin
            ClearLastError();
            ResponseText := ResponseText.Replace('"{', '{'); // Google Drive API JSON may be not so nice
            ResponseText := ResponseText.Replace('"}', '}'); // Google Drive API JSON may be not so nice
            if not ResponseJson.ReadFrom(ResponseText) then begin
                ClearLastError();
                LogError(GDIProblem::JsonRead, CallerMethod, ResponseText);
                ErrorValue := RegexMatchErrorCode(ResponseText);
                if ErrorValue = '' then
                    exit(true); // we failed to parse JSON, and we didn't locate the problem, so everything is bad
            end;
        end;
        if ErrorValue = '' then
            if not GDIJsonHelper.GetErrorValueFromJson(ErrorValue, ResponseJson) then
                exit(false); // No error is okay

        ClearLastError();
        if CallerMethod = CallerMethod::Authorize then begin
            LogError(GDIProblem::Auth, CallerMethod, ErrorValue);
            ThrowCurrentError(); // Ok to throw error if Authorize was called by Authorize itself
        end;
        case (ErrorValue) of
            '0':
                GDIProblem := GDIProblem::Timeout;
            '400':
                GDIProblem := GDIProblem::Auth;
            '404':
                GDIProblem := GDIProblem::NotFound;
            Format(GDIProblem::JsonRead):
                GDIProblem := GDIProblem::JsonRead;
            Format(GDIProblem::MissingFileID):
                GDIProblem := GDIProblem::MissingFileID;
            else
                GDIProblem := GDIProblem::Undefined;
        end;
        if GDIProblem in [GDIProblem::Auth, GDIProblem::JsonRead, GDIProblem::Undefined] then
            ErrorValue := ResponseText;
        LogError(GDIProblem, CallerMethod, ErrorValue);
        exit(true);
    end;

    procedure SendNotification(GDIProblem: Enum "GDI Problem"): Boolean
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CurrentNotification: Notification;
        NotificationID: Guid;
        NotificationLabel: Text;
        NotificationName: Text;
        NotificationMessage: Text;
        HandlerCodeunitID: Integer;
        HandlerMethodName: Text;
        AddActionDismiss: Boolean;
    begin
        case GDIProblem of
            GDIProblem::Timeout:
                begin
                    NotificationID := GetTimeoutNotificationID();
                    NotificationLabel := GDITimeoutLbl;
                    NotificationName := GDITimeoutTxt;
                    NotificationMessage := TimeoutNotificationTxt;
                    HandlerCodeunitID := Codeunit::"GDI Setup Mgt.";
                    HandlerMethodName := 'CheckConnection';
                    AddActionDismiss := true;
                end;
            GDIProblem::NotFound, GDIProblem::MissingFileID:
                begin
                    NotificationID := GetNotFoundNotificationID();
                    NotificationLabel := GDINotFoundLbl;
                    NotificationName := GDINotFoundTxt;
                    if GDIProblem = GDIProblem::NotFound then
                        NotificationMessage := NotFoundNotificationTxt
                    else
                        NotificationMessage := WaitSyncNotificationTxt;
                    // HandlerCodeunitID := Codeunit::"GDI Error Handler";
                    // HandlerMethodName := 'AssistHandleMissingFile';
                    AddActionDismiss := true;
                end;
            GDIProblem::Auth:
                begin
                    NotificationID := GetAuthNotificationID();
                    NotificationLabel := GDIAuthProblemLbl;
                    NotificationName := GDIAuthProblemTxt;
                    NotificationMessage := AuthFailedNotificationTxt;
                    // We don't need action as user may have no permission to edit setup
                    AddActionDismiss := false;
                end;
            else
                exit(false);
        end;

        if not MyNotifications.Get(UserId, NotificationID) then
            MyNotifications.InsertDefault(NotificationID, CopyStr(NotificationLabel, 1, 128), NotificationLabel, true);

        if MyNotifications.IsEnabled(NotificationID) then begin
            CurrentNotification.Id := NotificationID;
            CurrentNotification.Scope := CurrentNotification.Scope::LocalScope;
            CurrentNotification.Message := NotificationMessage;
            if HandlerCodeunitID <> 0 then
                CurrentNotification.AddAction(CheckConnectionLbl, HandlerCodeunitID, HandlerMethodName);
            if AddActionDismiss then
                CurrentNotification.AddAction(
                    DontShowAgainLbl, Codeunit::"Document Notifications", 'HideNotificationForCurrentUser');
            NotificationLifecycleMgt.SendNotification(CurrentNotification, CurrentRecordID);
        end;
        exit(true);
    end;

    procedure SetRecordId(RecID: RecordID)
    begin
        CurrentRecordID := RecID;
    end;

    procedure ThrowBadParameterErr(FunctionName: Text; ParameterVariant: Variant)
    begin
        Error(BadParameterErr, FunctionName, Format(ParameterVariant, 0, 9));
    end;

    procedure ThrowCurrentError()
    begin
        Error(CurrentErr, CurrentMethod, CurrentProblem, CurrentErrorValue);
    end;

    procedure ThrowEvaluateError(StringName: Text; StringValue: Text; ToTypeName: Text)
    begin
        Error(EvaluateFailErr, StringName, StringValue, ToTypeName);
    end;

    procedure ThrowFileIDMissingErr()
    begin
        Error(FileIDMissingErr);
    end;

    procedure ThrowFileNameMissingErr()
    begin
        Error(FileNameMissingErr);
    end;

    procedure ThrowFileUploadErr(FileName: Text)
    begin
        Error(FileUploadErr, FileName);
    end;

    procedure ThrowJsonReadErr(FileName: Text)
    begin
        Error(JsonReadErr, FileName);
    end;

    procedure ThrowJsonStructureErr(FileName: Text)
    begin
        Error(JsonStructureErr, FileName);
    end;

    procedure ThrowMediaIDMissingErr()
    begin
        Error(MediaIDMissingErr);
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

    local procedure GetAuthNotificationID(): Guid
    begin
        exit('C64BC6B0-F185-4295-B256-3045C72898DD');
    end;

    local procedure GetNotFoundNotificationID(): Guid
    begin
        exit('DEFCE478-F77F-4939-BE6E-78A4D6DBCAA6');
    end;

    local procedure GetTimeoutNotificationID(): Guid
    begin
        exit('61496913-7033-4AAF-8FFE-07C49AF0E541');
    end;

    local procedure RegexMatchErrorCode(ResponseText: Text): Text
    var
        TempMatches: Record Matches temporary;
        TempGroups: Record Groups temporary;
        RegEx: Codeunit Regex;
        ErrorCode: Text;
    begin
        // alternatively can try to replace "{ and }" with just { and } 
        RegEx.Match(ResponseText, '^(?:.|\n)+?error(?:.|\n)+?code(?:\"|\:| |\n|\t|=|\})+?([A-Za-z0-9]{1,})', TempMatches);
        if TempMatches.FindFirst() then begin
            RegEx.Groups(TempMatches, TempGroups);
            TempGroups.Get(1);
            ErrorCode := CopyStr(ResponseText, TempGroups.Index + 1, TempGroups.Length);
        end;
        exit(ErrorCode);
    end;

    local procedure LogError(Problem: Enum "GDI Problem"; Method: Enum "GDI Method";
                                          ErrorValue: Text)
    begin
        ClearError();
        CurrentProblem := Problem;
        CurrentMethod := Method;
        CurrentErrorValue := ErrorValue;
        // TODO: logging
        // NOTE: Logging requires extra commits
    end;

    var
        CurrentRecordID: RecordId;
        CurrentProblem: Enum "GDI Problem";
        CurrentMethod: Enum "GDI Method";
        CurrentErrorValue: text;
        AuthFailedNotificationTxt: Label 'Authorization failed. Please check Google Drive Setup.';
        WaitSyncNotificationTxt: Label 'Please wait for the sync with Google Drive.';
        NotFoundNotificationTxt: Label 'Oops, we cannot locate this file on Google Drive. Did you delete the file from Google Drive?';
        TimeoutNotificationTxt: Label 'Oops, we have trouble connecting you to Google Drive.';
        CheckConnectionLbl: Label 'Check connection.';
        DontShowAgainLbl: Label 'Don''t show again.';
        GDIAuthProblemLbl: Label 'Google Drive authorization failure';
        GDIAuthProblemTxt: Label 'Warns that authorization failed and suggests to check setup.';
        GDINotFoundLbl: Label 'Google Drive file not found';
        GDINotFoundTxt: Label 'Warns that file is not found on Google Drive and suggests to handle Queue.';
        GDITimeoutLbl: Label 'Google Drive Timeout';
        GDITimeoutTxt: Label 'Warns about Google Drive timeout and suggests to check connection.';
        BadParameterErr: Label '%1 says: bad parameter value %2.', Comment = '%1 = function, %2 = parameter value';
        CurrentErr: Label 'Method: %1; Problem: %2; ErrorValue: %3.', Comment = '%1 = Method name; %2 = Problem name; %3 = Error value (text)';
        EvaluateFailErr: Label 'Failed to evaluate %1=%2 into %3 type.', Comment = '%1 = Variable/field name; %2 = Variable/field value; %3 = Target type';
        FileNameMissingErr: Label 'File name was not specified.';
        FileIDMissingErr: Label 'File ID was not specified.';
        FileUploadErr: Label 'Cannot upload file %1.', Comment = '%1 = File name';
        JsonReadErr: Label 'Cannot read file %1 as json.', Comment = '%1 = File name';
        JsonStructureErr: Label 'Wrong json structure in %1. Please, check recent Google Drive API updates.', Comment = '%1 = File name, http content, text variable, etc';
        MediaIDMissingErr: Label 'Media ID is missing.';
        NotImplementedErr: Label 'Not implemented.';
        ValueOutOfRangeErr: Label '%1 %2 is out of range [%3 .. %4].', Comment = '%1 = Variable/field name; %2 = Variable/field value; %3 = low margin; %4 = high margin';
}