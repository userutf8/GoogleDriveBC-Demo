codeunit 50102 "GDI Cache Mgt."
{

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

    procedure ClearCache(ClearSize: Decimal; SkipMediaID: Integer)
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

    procedure RankMediaInfo()
    var
        GDISetup: Record "GDI Setup";
        GracePeriodDuration: Duration;
        GracePeriodStart: DateTime;
    begin
        GDISetup.Get();
        Evaluate(GracePeriodDuration, GDISetup.GracePeriod);
        GracePeriodStart := CurrentDateTime - GracePeriodDuration;
        RankMediaInfo(GracePeriodStart, 0);
        RankMediaInfo(GracePeriodStart, 50);
    end;

    local procedure RankMediaInfo(GracePeriodStart: Datetime; RankModifier: Integer)
    var
        GDIMediaInfo: Record "GDI Media Info";
        GDIErrorHandler: Codeunit "GDI Error Handler";
        AvgSize: Decimal;
        AvgViews: Integer;
        AvgStars: Integer;
        RecQty: Integer;
    begin
        GDIMediaInfo.SetFilter(FileSize, '>%1', 0.0);
        if GDIMediaInfo.IsEmpty() then
            exit;

        case RankModifier of
            0:
                GDIMediaInfo.SetFilter(LastViewedByEntity, '<%1', GracePeriodStart);
            50:
                GDIMediaInfo.SetFilter(LastViewedByEntity, '>=%1', GracePeriodStart);
            else
                GDIErrorHandler.ThrowNotImplementedErr();
        end;
        // Group 1: Rank 1 or 51: Zero views
        GDIMediaInfo.SetRange(ViewedByEntity, 0);
        GDIMediaInfo.ModifyAll(Rank, RankModifier + 1);

        // Group 2: Non-zero views (calculations required)
        GDIMediaInfo.SetFilter(ViewedByEntity, '>%1', 0);
        if GDIMediaInfo.IsEmpty then
            exit;

        RecQty := GDIMediaInfo.Count();
        GDIMediaInfo.CalcSums(FileSize, ViewedByEntity, Stars);
        AvgSize := GDIMediaInfo.FileSize / RecQty;
        AvgViews := Round(GDIMediaInfo.ViewedByEntity / RecQty, 1, '>');
        AvgStars := Round(GDIMediaInfo.Stars / RecQty, 1, '>');
        // Rank 3 or 53: > avg size, <= avg views/stars
        GDIMediaInfo.SetFilter(FileSize, '>%1', AvgSize);
        GDIMediaInfo.SetFilter(ViewedByEntity, '>%1&<=%2', 0, AvgViews);
        GDIMediaInfo.SetFilter(Stars, '<=%1', AvgStars);
        GDIMediaInfo.ModifyAll(Rank, RankModifier + 3);
        // Rank 5 or 55: <= avg size, <= avg views/stars
        GDIMediaInfo.SetFilter(FileSize, '<=%1', AvgSize);
        GDIMediaInfo.ModifyAll(Rank, RankModifier + 5);
        // Rank 7 or 57: any size, <= avg views, > avg stars
        GDIMediaInfo.SetRange(FileSize);
        GDIMediaInfo.SetFilter(Stars, '>%1', AvgStars);
        GDIMediaInfo.ModifyAll(Rank, RankModifier + 7);
        // Rank 9 or 59: any size/stars, >= avg views
        GDIMediaInfo.SetRange(Stars);
        GDIMediaInfo.SetFilter(ViewedByEntity, '>%1', AvgViews);
        GDIMediaInfo.ModifyAll(Rank, RankModifier + 9);
    end;
}