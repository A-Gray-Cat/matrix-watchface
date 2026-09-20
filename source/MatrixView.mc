import Toybox.Application;
import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class MatrixView extends WatchUi.WatchFace {
    const COL_TEXT = 0x78FF8C;
    const COL_MID = 0x14AA37;
    const COL_AOD = 0x3E6E3E;
    const COL_BAR = 0x00FF41;

    var rain as RainField;
    var data as FaceData;
    var timer as Timer.Timer?;
    var sleeping as Boolean = false;
    var pending as Boolean = false;
    var amoled as Boolean = true;
    var cachedStyle as Number = 0;
    var styleSec as Number = -1;
    var w as Number = 454;
    var h as Number = 454;
    var timeFont as FontType = Graphics.FONT_NUMBER_HOT;
    var bodyFont as FontType = Graphics.FONT_TINY;
    var tinyFont as FontType = Graphics.FONT_XTINY;
    var aodFont as FontType = Graphics.FONT_NUMBER_MEDIUM;
    var fontsReady as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        rain = new RainField();
        data = new FaceData();
    }

    function onLayout(dc as Dc) as Void {
        w = dc.getWidth();
        h = dc.getHeight();
        var s = System.getDeviceSettings();
        amoled = (s has :requiresBurnInProtection) && s.requiresBurnInProtection;
        rain.layout(w, h);
        loadFonts();
    }

    function loadFonts() as Void {
        if (fontsReady) {
            return;
        }
        if (Graphics has :getVectorFont) {
            var tf = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoBold", "RobotoRegular"], :size => h * 0.26});
            if (tf != null) {
                timeFont = tf;
            }
            var bf = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"], :size => h * 0.052});
            if (bf != null) {
                bodyFont = bf;
            }
            var nf = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => h * 0.032});
            if (nf != null) {
                tinyFont = nf;
            }
            var af = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoRegular"], :size => h * 0.14});
            if (af != null) {
                aodFont = af;
            }
        }
        fontsReady = true;
    }

    function onShow() as Void {
        if (!sleeping) {
            startTimer();
        }
    }

    function onHide() as Void {
        stopTimer();
    }

    function onExitSleep() as Void {
        sleeping = false;
        startTimer();
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        sleeping = true;
        stopTimer();
        WatchUi.requestUpdate();
    }

    function startTimer() as Void {
        if (timer == null) {
            timer = new Timer.Timer();
        }
        timer.start(method(:onTick), 50, true);
    }

    function stopTimer() as Void {
        if (timer != null) {
            timer.stop();
        }
    }

    function onTick() as Void {
        // One paint request at a time. rain.step() runs in onUpdate
        // using elapsed ms so fall speed does not depend on fps.
        if (pending) {
            return;
        }
        pending = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        pending = false;
        var low = sleeping;
        if (System has :getDisplayMode) {
            var mode = System.getDisplayMode();
            if (mode == System.DISPLAY_MODE_OFF) {
                return;
            }
            low = (mode == System.DISPLAY_MODE_LOW_POWER);
        }
        // MIP Solar is always-on; don't collapse to the dim AMOLED layout.
        if (low && amoled) {
            drawAod(dc);
            return;
        }
        rain.step();
        data.refresh();
        if (styleId() == 1) {
            drawCrt(dc);
        } else {
            drawRain(dc);
        }
    }

    function styleId() as Number {
        var sec = System.getClockTime().sec;
        if (sec == styleSec) {
            return cachedStyle;
        }
        styleSec = sec;
        var settings = WatchFaceConfig.getSettings(null);
        if (settings != null && settings.styleId != null) {
            cachedStyle = settings.styleId as Number;
        } else {
            cachedStyle = Application.Properties.getValue("style") as Number;
        }
        return cachedStyle;
    }

    function drawAod(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        data.refresh();
        // Shift a few pixels each minute so the same AMOLED cells don't sit lit.
        var clock = System.getClockTime();
        var ox = (clock.min % 5) - 2;
        var oy = ((clock.min / 5) % 5) - 2;
        dc.setColor(COL_AOD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 + ox, h / 2 + oy - 8, aodFont, data.timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2 + ox, h / 2 + oy + (h * 0.08).toNumber(), tinyFont, data.dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawRain(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        rain.draw(dc, w, h);

        var cx = w / 2;
        var justC = Graphics.TEXT_JUSTIFY_CENTER;
        var justCV = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.12).toNumber(), bodyFont, data.promptLine, justC);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.36).toNumber(), timeFont, data.timeStr, justCV);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.54).toNumber(), bodyFont, data.dateStr, justC);
        dc.drawText(cx, (h * 0.64).toNumber(), bodyFont, data.wxVal, justC);
        dc.drawText(cx, (h * 0.74).toNumber(), bodyFont, data.battStr, justC);

        dc.setColor(COL_MID, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.88).toNumber(), bodyFont, data.epochLine, justC);
    }

    function drawCrt(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        rain.draw(dc, w, h);

        var x0 = (w * 0.12).toNumber();
        var y0 = (h * 0.14).toNumber();
        var ww = (w * 0.76).toNumber();
        var hh = (h * 0.72).toNumber();
        var rad = 8;
        if (Graphics has :createColor) {
            dc.setFill(Graphics.createColor(235, 0, 6, 0));
            dc.fillRoundedRectangle(x0, y0, ww, hh, rad);
        } else {
            dc.setColor(0x000400, 0x000400);
            dc.fillRoundedRectangle(x0, y0, ww, hh, rad);
        }
        dc.setColor(COL_MID, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x0, y0, ww, hh, rad);
        dc.setColor(0x002008, 0x002008);
        dc.fillRectangle(x0 + 2, y0 + 2, ww - 4, (h * 0.055).toNumber());
        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x0 + 10, y0 + (h * 0.03).toNumber(), bodyFont, "tty1  root@fenix8", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var cx = w / 2;
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y0 + (h * 0.16).toNumber(), timeFont, data.timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var lx = x0 + 16;
        var y = y0 + (h * 0.28).toNumber();
        var step = (h * 0.055).toNumber();
        cmd(dc, lx, y, "# date");
        y += step;
        out(dc, lx, y, data.dateStr);
        y += step;
        cmd(dc, lx, y, "# wx");
        y += step;
        out(dc, lx, y, data.wxStr);
        y += step;
        cmd(dc, lx, y, "# batt");
        y += step;
        out(dc, lx, y, data.battStr);
        y += step;
        cmd(dc, lx, y, "#  " + data.blink);
    }

    function cmd(dc as Dc, x as Number, y as Number, s as String) as Void {
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, tinyFont, s, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function out(dc as Dc, x as Number, y as Number, s as String) as Void {
        dc.setColor(COL_BAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, bodyFont, s, Graphics.TEXT_JUSTIFY_LEFT);
    }

}
