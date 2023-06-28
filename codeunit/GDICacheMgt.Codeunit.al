codeunit 50102 "GDI Cache Mgt."
{

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

        GDIMediaInfo.CalcSums(FileSize, ViewedByEntity, Stars, Qty);
        AvgSize := GDIMediaInfo.FileSize / GDIMediaInfo.Qty;
        AvgViews := Round(GDIMediaInfo.ViewedByEntity / GDIMediaInfo.Qty, 1, '>');
        AvgStars := Round(GDIMediaInfo.Stars / GDIMediaInfo.Qty, 1, '>');
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