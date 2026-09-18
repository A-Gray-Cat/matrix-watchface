import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Time;
import Toybox.WatchUi;

class TerminalView extends WatchUi.View {
    const COL_TEXT = 0x78FF8C;
    const COL_BAR = 0x00FF41;
    const COL_MID = 0x14AA37;
    const COL_DIM = 0x084E18;

    var _timer as Timer.Timer?;
    var _body as FontType = Graphics.FONT_TINY;
    var _tiny as FontType = Graphics.FONT_XTINY;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var h = dc.getHeight();
        if (Graphics has :getVectorFont) {
            var b = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoRegular"], :size => h * 0.045});
            if (b != null) {
                _body = b;
            }
            var t = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => h * 0.032});
            if (t != null) {
                _tiny = t;
            }
        }
    }

    function onShow() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        _timer.start(method(:onTick), 1000, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var x = (w * 0.12).toNumber();
        var y = (h * 0.12).toNumber();
        var step = (h * 0.075).toNumber();
        if (step < 16) {
            step = 16;
        }

        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _tiny, "root@fenix8:~# status", Graphics.TEXT_JUSTIFY_LEFT);
        y += step;
        line(dc, x, y, "time", Dump.timeWithSec());
        y += step;
        line(dc, x, y, "date", Dump.dateStr());
        y += step;
        line(dc, x, y, "wx  ", Dump.wxStr());
        y += step;
        line(dc, x, y, "batt", Dump.battStr());
        y += step;
        line(dc, x, y, "hr  ", Dump.hrStr());
        y += step;
        line(dc, x, y, "step", Dump.stepsStr());
        y += step;
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _tiny, "epoch " + Time.now().value().toString(), Graphics.TEXT_JUSTIFY_LEFT);
        y += step;
        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _tiny, "#", Graphics.TEXT_JUSTIFY_LEFT);
    }

    function line(dc as Dc, x as Number, y as Number, k as String, v as String) as Void {
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _tiny, k, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + (dc.getWidth() * 0.18).toNumber(), y, _body, v, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
