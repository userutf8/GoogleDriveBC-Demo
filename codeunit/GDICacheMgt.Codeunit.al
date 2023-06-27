codeunit 50102 "GDI Cache Mgt."
{
    procedure CleanCache()
    var
        GDISetup: Record "GDI Setup";
        ClearedSpace: Decimal;
    begin
        GDISetup.Get();
        SetCurrentSettings(GDISetup.CacheSize, GDISetup.CacheWarning, GDISetup.GracePeriod);
        SetMaxRecursionLevel(2);
        ClearedSpace := 0.0;
        if not CleanCacheRecursively(ClearedSpace, 0) then
            CleanCacheForce();
    end;

    procedure CleanCacheForce(): Boolean
    var
        GDIMediaInfo: Record "GDI Media Info";
        GDIMedia: Record "GDI Media";
        ClearedSpace: Decimal;
        CacheSize: Decimal;
        CacheWarning: Decimal;
        DummyGracePeriod: Duration;
        TotalFileSize: Decimal;
    begin
        if GDIMediaInfo.IsEmpty() then
            exit(true);

        GetCurrentSettings(CacheSize, CacheWarning, DummyGracePeriod);
        GDIMediaInfo.CalcSums(FileSize);
        TotalFileSize := GDIMediaInfo.FileSize;
        ClearedSpace := 0.0;
        GDIMediaInfo.SetCurrentKey(SystemModifiedAt);
        GDIMediaInfo.FindSet();
        repeat
            GDIMedia.Get(GDIMediaInfo.MediaID);
            Clear(GDIMedia.FileContent);
            GDIMedia.Modify();
            ClearedSpace += GDIMediaInfo.FileSize;
            Clear(GDIMediaInfo.FileSize);
            GDIMediaInfo.Modify();
            if TotalFileSize - ClearedSpace < CacheSize * CacheWarning then
                exit(true);
        until GDIMediaInfo.Next() = 0;
    end;

    procedure CleanCacheRecursively(var ClearedSpace: Decimal; RecursionLevel: Integer): Boolean
    var
        GDIMediaInfo: Record "GDI Media Info";
        GDIMedia: Record "GDI Media";
        CacheSize: Decimal;
        CacheWarning: Decimal;
        GracePeriod: Duration;
        TotalFileSize: Decimal;
        GracePeriodStart: DateTime;
        QtyRecWithFile: Integer;
        AvgFileSize: Decimal;
        AvgViews: Integer;
    begin
        GetCurrentSettings(CacheSize, CacheWarning, GracePeriod);
        if RecursionLevel > GetMaxRecursionLevel() then
            exit(false); // we have to exit but the cache is still not clean 

        GDIMediaInfo.SetFilter(FileSize, '>%1', 0.0);
        if GDIMediaInfo.IsEmpty() then
            exit(true); // cache is clean as has no files at all

        GDIMediaInfo.CalcSums(FileSize);
        TotalFileSize := GDIMediaInfo.FileSize;
        if TotalFileSize < CacheSize * CacheWarning then
            exit(true); // cache is not yet at warning capacity

        GDIMediaInfo.Reset();
        GracePeriodStart := CurrentDateTime - GracePeriod;

        // Firstly, clean files with zero views which have been modified before the Grace Period start
        if RecursionLevel = 0 then begin
            GDIMediaInfo.SetRange(ViewedByEntity, 0);
            GDIMediaInfo.SetFilter(SystemModifiedAt, '<%1', GracePeriodStart);
            if GDIMediaInfo.FindSet(true) then // locks table
                repeat
                    GDIMedia.Get(GDIMediaInfo.MediaID);
                    Clear(GDIMedia.FileContent);
                    GDIMedia.Modify();
                    ClearedSpace += GDIMediaInfo.FileSize;
                    Clear(GDIMediaInfo.FileSize);
                    GDIMediaInfo.Modify();
                until GDIMediaInfo.Next() = 0;

            if TotalFileSize - ClearedSpace < CacheSize * CacheWarning then
                exit(true); // cache is not yet at warning capacity
        end;

        // Count qty of media that still have content
        GDIMediaInfo.Reset();
        GDIMediaInfo.SetFilter(FileSize, '>%1', 0.0);
        if GDIMediaInfo.IsEmpty() then
            exit(true); // cache is clean as has no files at all

        QtyRecWithFile := GDIMediaInfo.Count(); // slow
        if QtyRecWithFile = 0 then // safety check
            exit(true); // cache is clean as has no files at all

        // Calc average file size and average views (round up)
        GDIMediaInfo.CalcSums(FileSize, ViewedByEntity); // faster
        TotalFileSize := GDIMediaInfo.FileSize;
        AvgFileSize := TotalFileSize / QtyRecWithFile;
        AvgViews := Round(GDIMediaInfo.ViewedByEntity / QtyRecWithFile, 1, '>');

        // Clean bigger than average files modified not recently and viewed below average
        // or at least clean bigger than average files viewed below average
        // or at least clean bigger than average files
        GDIMediaInfo.Reset();
        GDIMediaInfo.SetCurrentKey(SystemModifiedAt); // sort by modified at
        GDIMediaInfo.SetFilter(FileSize, '>=%1', AvgFileSize);
        GDIMediaInfo.SetFilter(SystemModifiedAt, '<%1', GracePeriodStart);
        GDIMediaInfo.SetFilter(ViewedByEntity, '<%1', AvgViews);
        if GDIMediaInfo.IsEmpty() then begin
            GDIMediaInfo.SetRange(SystemModifiedAt);
            if GDIMediaInfo.IsEmpty() then
                GDIMediaInfo.SetRange(ViewedByEntity);
        end;
        if GDIMediaInfo.FindSet(true) then // locks table
            repeat
                GDIMedia.Get(GDIMediaInfo.MediaID);
                Clear(GDIMedia.FileContent);
                GDIMedia.Modify();
                ClearedSpace += GDIMediaInfo.FileSize;
                Clear(GDIMediaInfo.FileSize);
                GDIMediaInfo.Modify();
                if TotalFileSize - ClearedSpace < CacheSize * CacheWarning then
                    exit(true);
            until GDIMediaInfo.Next() = 0;

        // If all above was not enough, then call the next level
        exit(CleanCacheRecursively(ClearedSpace, RecursionLevel + 1));
    end;

    local procedure GetCurrentSettings(var CacheSize: Decimal; var CacheWarning: Decimal; var GracePeriod: Duration)
    begin
        CacheSize := CurrentCacheSize;
        CacheWarning := CurrentCacheWarning;
        GracePeriod := CurrentGracePeriod;
    end;

    local procedure GetMaxRecursionLevel(): Integer
    begin
        exit(CurrentMaxRecursionLevel);
    end;

    local procedure SetCurrentSettings(NewCacheSize: Decimal; NewCacheWarningPercent: Integer; NewGracePeriod: Text)
    begin
        CurrentCacheSize := NewCacheSize;
        CurrentCacheWarning := NewCacheWarningPercent / 100;
        Evaluate(CurrentGracePeriod, NewGracePeriod);
    end;

    local procedure SetMaxRecursionLevel(NewMaxRecursionLevel: Integer)
    begin
        CurrentMaxRecursionLevel := NewMaxRecursionLevel;
    end;

    var
        CurrentCacheSize: Decimal;
        CurrentCacheWarning: Decimal;
        CurrentGracePeriod: Duration;
        CurrentMaxRecursionLevel: Integer;
}