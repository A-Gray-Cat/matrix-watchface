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
    var _time as FontType = Graphics.FONT_NUMBER_MEDIUM;
    var _body as FontType = Graphics.FONT_SMALL;
    var _tiny as FontType = Graphics.FONT_TINY;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var h = dc.getHeight();
        if (Graphics has :getVectorFont) {
            var tf = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoBold", "RobotoRegular"], :size => h * 0.12});
            if (tf != null) {
                _time = tf;
            }
            var b = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoRegular"], :size => h * 0.052});
            if (b != null) {
                _body = b;
            }
            var t = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => h * 0.036});
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
        var cx = w / 2;
        var just = Graphics.TEXT_JUSTIFY_CENTER;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.14).toNumber(), _tiny, "root@fenix8:~# status", just);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.28).toNumber(), _time, Dump.timeStr(), just | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(cx, (h * 0.42).toNumber(), _body, Dump.dateStr(), just);
        dc.drawText(cx, (h * 0.51).toNumber(), _body, Dump.wxStr(), just);
        dc.drawText(cx, (h * 0.60).toNumber(), _body, "batt  " + Dump.battStr(), just);
        dc.drawText(cx, (h * 0.69).toNumber(), _body, "hr  " + Dump.hrStr() + "    step  " + Dump.stepsStr(), just);

        dc.setColor(COL_MID, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.82).toNumber(), _tiny, "epoch " + Time.now().value().toString(), just);
        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.90).toNumber(), _tiny, "#", just);
    }
}
