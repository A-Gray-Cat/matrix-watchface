import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// Digital rain. Glyphs are a tiny original bitmap font (mirrored
// half-width katakana packed as ASCII). Column state is four parallel
// arrays so we never allocate per frame.
class RainField {
    const COLS = 32;
    const ROWS = 28;

    var head as Array<Float>;
    var speed as Array<Float>;
    var trail as Array<Number>;
    var seed as Array<Number>;
    var xs as Array<Number>;
    var glyphs as Array<String>;
    var nGlyphs as Number = 0;
    var rainFont as FontType = Graphics.FONT_XTINY;
    var rainFontReady as Boolean = false;
    var liveCols as Number = 24;
    var liveRows as Number = 24;
    var rowH as Float = 16.0;
    var cx as Number = 227;
    var cy as Number = 227;
    var r2 as Number = 40000;
    var lastMs as Number = 0;

    function initialize() {
        var charset = "abcdefghijklmnopqrstuvwxyz0123456789*+$:=#";
        nGlyphs = charset.length();
        glyphs = new Array<String>[nGlyphs];
        var i;
        for (i = 0; i < nGlyphs; i++) {
            glyphs[i] = charset.substring(i, i + 1);
        }

        head = new Array<Float>[COLS];
        speed = new Array<Float>[COLS];
        trail = new Array<Number>[COLS];
        seed = new Array<Number>[COLS];
        xs = new Array<Number>[COLS];
        Math.srand(System.getClockTime().sec + 1);
        for (i = 0; i < COLS; i++) {
            resetCol(i, true);
        }
    }

    function layout(w as Number, h as Number) as Void {
        var cols = w / 16;
        if (cols > COLS) {
            cols = COLS;
        }
        if (cols < 16) {
            cols = 16;
        }
        liveCols = cols;
        var rows = h / 18;
        if (rows > ROWS) {
            rows = ROWS;
        }
        if (rows < 16) {
            rows = 16;
        }
        liveRows = rows;
        rowH = h.toFloat() / rows;
        cx = w / 2;
        cy = h / 2;
        var r = cx - 8;
        r2 = r * r;
        var colW = w.toFloat() / cols;
        var i;
        for (i = 0; i < cols; i++) {
            xs[i] = ((i.toFloat() + 0.5) * colW).toNumber();
        }
    }

    function resetCol(c as Number, scatter as Boolean) as Void {
        if (scatter) {
            head[c] = (Math.rand() % liveRows).toFloat();
        } else {
            head[c] = 0.0;
        }
        // Rows per 100ms. Higher than v3 (0.28–0.97) so it reads as a fall,
        // not a drift. step() scales by real elapsed time.
        speed[c] = 0.45 + (Math.rand() % 80).toFloat() / 100.0;
        trail[c] = 6 + (Math.rand() % 5);
        seed[c] = Math.rand();
    }

    function step() as Void {
        var now = System.getTimer();
        var dt = now - lastMs;
        lastMs = now;
        if (dt <= 0) {
            dt = 50;
        } else if (dt > 200) {
            dt = 200;
        }
        var scale = dt.toFloat() / 100.0;
        var c;
        for (c = 0; c < liveCols; c++) {
            head[c] = head[c] + speed[c] * scale;
            if (head[c] - trail[c].toFloat() > liveRows) {
                resetCol(c, false);
            }
        }
    }

    function glyphAt(c as Number, slot as Number) as String {
        var n = seed[c] + c * 131 + slot * 17;
        if (n < 0) {
            n = -n;
        }
        return glyphs[n % nGlyphs];
    }

    function prepareFont() as Void {
        if (rainFontReady) {
            return;
        }
        rainFont = WatchUi.loadResource(Rez.Fonts.MatrixRain) as FontType;
        rainFontReady = true;
    }

    function draw(dc as Graphics.Dc, w as Number, h as Number) as Void {
        prepareFont();
        var font = rainFont;
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(0x084E18, Graphics.COLOR_TRANSPARENT);
        band(dc, font, just, 4, 20);
        dc.setColor(0x14AA37, Graphics.COLOR_TRANSPARENT);
        band(dc, font, just, 2, 3);
        dc.setColor(0x00FF41, Graphics.COLOR_TRANSPARENT);
        band(dc, font, just, 1, 1);
        dc.setColor(0xC8FFC8, Graphics.COLOR_TRANSPARENT);
        band(dc, font, just, 0, 0);
    }

    function band(dc as Graphics.Dc, font as FontType, just as Number, d0 as Number, d1 as Number) as Void {
        var cols = liveCols;
        var rh = rowH;
        var midX = cx;
        var midY = cy;
        var rad2 = r2;
        var c;
        var d;
        for (c = 0; c < cols; c++) {
            var x = xs[c];
            var len = trail[c];
            var hd = head[c];
            var last = d1;
            if (last >= len) {
                last = len - 1;
            }
            for (d = d0; d <= last; d++) {
                var rowF = hd - d.toFloat();
                if (rowF < 0) {
                    continue;
                }
                var y = ((rowF + 0.5) * rh).toNumber();
                var dx = x - midX;
                var dy = y - midY;
                if (dx * dx + dy * dy > rad2) {
                    continue;
                }
                dc.drawText(x, y, font, glyphAt(c, d), just);
            }
        }
    }
}
