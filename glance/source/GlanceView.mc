import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class MatrixGlanceView extends WatchUi.GlanceView {
    const COL_TEXT = 0x78FF8C;
    const COL_BAR = 0x00FF41;
    const COL_MID = 0x14AA37;

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var font = Graphics.FONT_GLANCE;
        if (!(Graphics has :FONT_GLANCE)) {
            font = Graphics.FONT_XTINY;
        }
        var small = Graphics.FONT_XTINY;
        var y = 2;
        var lh = dc.getFontHeight(font);
        if (lh < 1) {
            lh = 14;
        }

        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2, y, small, "root@fenix8", Graphics.TEXT_JUSTIFY_LEFT);
        y += dc.getFontHeight(small) + 2;

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2, y, font, Dump.timeStr() + "  " + Dump.battStr(), Graphics.TEXT_JUSTIFY_LEFT);
        y += lh + 1;
        if (y + lh <= h) {
            dc.setColor(COL_MID, Graphics.COLOR_TRANSPARENT);
            dc.drawText(2, y, font, Dump.wxStr(), Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}
