import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class MatrixGlanceView extends WatchUi.GlanceView {
    const COL_TEXT = 0x78FF8C;
    const COL_BAR = 0x00FF41;

    var _big as FontType = Graphics.FONT_SMALL;
    var _small as FontType = Graphics.FONT_TINY;

    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var h = dc.getHeight();
        if (Graphics has :FONT_GLANCE_NUMBER) {
            _big = Graphics.FONT_GLANCE_NUMBER;
        } else if (Graphics has :FONT_GLANCE) {
            _big = Graphics.FONT_GLANCE;
        }
        if (Graphics has :FONT_GLANCE) {
            _small = Graphics.FONT_GLANCE;
        }
        if (Graphics has :getVectorFont) {
            var b = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoBold", "RobotoRegular"], :size => h * 0.38});
            if (b != null) {
                _big = b;
            }
            var s = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoRegular"], :size => h * 0.22});
            if (s != null) {
                _small = s;
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.30).toNumber(), _big, Dump.dateTimeStr(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.72).toNumber(), _small, Dump.battStr() + "  " + Dump.wxStr(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
