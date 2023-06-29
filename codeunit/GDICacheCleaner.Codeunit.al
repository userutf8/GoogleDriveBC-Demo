codeunit 50114 "GDI Cache Cleaner"
{
    trigger OnRun()
    begin
        ClearCache();
    end;

    procedure ClearCache()
    var
        GDIMediaInfo: Record "GDI Media Info";
        GDIMedia: Record "GDI Media";
        GDISetup: Record "GDI Setup";
        CurrentRank: Integer;
        MaxCacheSize: Decimal;
        CurrentCacheSize: Decimal;
    begin
        GDISetup.Get();
        MaxCacheSize := GDISetup.CacheSize * GDISetup.CacheWarning / 100;
        GDIMediaInfo.SetFilter(FileSize, '>%1', 0.0);
        GDIMediaInfo.CalcSums(FileSize);
        CurrentCacheSize := GDIMediaInfo.FileSize;
        if CurrentCacheSize <= MaxCacheSize then
            exit;

        GDIMediaInfo.SetCurrentKey(Rank);
        if GDIMediaInfo.FindSet(true) then
            repeat
                CurrentRank := GDIMediaInfo.Rank;
                CurrentCacheSize -= GDIMediaInfo.FileSize;
                GDIMedia.Get(GDIMediaInfo.MediaID);
                Clear(GDIMedia.FileContent);
                GDIMedia.Modify();
                Clear(GDIMediaInfo.FileSize);
                Clear(GDIMediaInfo.Rank);
                GDIMediaInfo.Modify();
                if CurrentRank >= GDISetup.ClearAllBelowRank then
                    if CurrentCacheSize <= MaxCacheSize then
                        break;
            until GDIMediaInfo.Next() = 0;
    end;

    procedure ClearCacheOnDemand(ClearSize: Decimal; SkipMediaID: Integer)
    var
        GDIMediaInfo: Record "GDI Media Info";
        GDIMedia: Record "GDI Media";
        GDISetup: Record "GDI Setup";
        MaxCacheSize: Decimal;
        CurrentCacheSize: Decimal;
    begin
        GDISetup.Get();
        MaxCacheSize := GDISetup.CacheSize;
        GDIMediaInfo.SetFilter(FileSize, '>%1', 0.0);
        GDIMediaInfo.CalcSums(FileSize);
        CurrentCacheSize := GDIMediaInfo.FileSize;
        if CurrentCacheSize + ClearSize <= MaxCacheSize then
            exit;

        GDIMediaInfo.SetCurrentKey(Rank);
        if GDIMediaInfo.FindSet(true) then
            repeat
                if GDIMediaInfo.MediaID <> SkipMediaID then begin
                    CurrentCacheSize -= GDIMediaInfo.FileSize;
                    GDIMedia.Get(GDIMediaInfo.MediaID);
                    Clear(GDIMedia.FileContent);
                    GDIMedia.Modify();
                    Clear(GDIMediaInfo.FileSize);
                    Clear(GDIMediaInfo.Rank);
                    GDIMediaInfo.Modify();
                end;
            until (GDIMediaInfo.Next() = 0) or (CurrentCacheSize + ClearSize <= MaxCacheSize);
    end;

}