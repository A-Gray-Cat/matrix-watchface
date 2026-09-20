import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class TerminalView extends WatchUi.View {
    const COL_TEXT = 0x78FF8C;
    const COL_BAR = 0x00FF41;
    const COL_MID = 0x14AA37;

    var _timer as Timer.Timer?;
    var _time as FontType = Graphics.FONT_SMALL;
    var _body as FontType = Graphics.FONT_TINY;
    var _tiny as FontType = Graphics.FONT_XTINY;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var h = dc.getHeight();
        if (Graphics has :getVectorFont) {
            var tf = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoBold", "RobotoRegular"], :size => h * 0.09});
            if (tf != null) {
                _time = tf;
            }
            var b = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => h * 0.046});
            if (b != null) {
                _body = b;
            }
            var t = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => h * 0.038});
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
        dc.drawText(cx, (h * 0.10).toNumber(), _tiny, "root@fenix8:~#", just);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.22).toNumber(), _time, Dump.dateTimeStr(), just | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COL_MID, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.36).toNumber(), _body, "epoch  " + Dump.epochStr(), just);
        dc.drawText(cx, (h * 0.44).toNumber(), _body, "utc    " + Dump.utcStr(), just);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.54).toNumber(), _body, Dump.wxStr() + "    " + Dump.battStr(), just);
        dc.drawText(cx, (h * 0.62).toNumber(), _body, "hr " + Dump.hrStr() + "   bb " + Status.bodyBattStr() + "   str " + Status.stressStr(), just);
        dc.drawText(cx, (h * 0.70).toNumber(), _body, "step " + Status.stepsGoalStr(), just);
        dc.drawText(cx, (h * 0.78).toNumber(), _body, "sun  " + Status.sunStr(), just);

        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.87).toNumber(), _tiny, "wo  " + Status.workoutsLine(), just);
    }
}
