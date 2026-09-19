import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// Digital rain. Glyphs are a tiny original bitmap font (mirrored
// half-width katakana packed as ASCII). Column state is four parallel
// arrays so we never allocate per frame.
class RainField {
    const COLS = 40;
    const ROWS = 36;

    var head as Array<Float>;
    var speed as Array<Float>;
    var trail as Array<Number>;
    var seed as Array<Number>;
    var glyphs as Array<String>;
    var nGlyphs as Number = 0;
    var rainFont as FontType = Graphics.FONT_XTINY;
    var rainFontReady as Boolean = false;
    var liveCols as Number = 32;
    var liveRows as Number = 28;

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
        Math.srand(System.getClockTime().sec + 1);
        for (i = 0; i < COLS; i++) {
            resetCol(i, true);
        }
    }

    function layout(w as Number, h as Number) as Void {
        var cols = w / 12;
        if (cols > COLS) {
            cols = COLS;
        }
        if (cols < 16) {
            cols = 16;
        }
        liveCols = cols;
        var rows = h / 15;
        if (rows > ROWS) {
            rows = ROWS;
        }
        if (rows < 16) {
            rows = 16;
        }
        liveRows = rows;
    }

    function resetCol(c as Number, scatter as Boolean) as Void {
        if (scatter) {
            head[c] = (Math.rand() % liveRows).toFloat();
        } else {
            head[c] = 0.0;
        }
        // Per 50ms tick. Same fall rate as the old 100ms 0.38–1.28 range,
        // but half the pixels per frame so columns slide instead of jump.
        speed[c] = 0.16 + (Math.rand() % 40).toFloat() / 100.0;
        trail[c] = 10 + (Math.rand() % 9);
        seed[c] = Math.rand();
    }

    function step() as Void {
        var c;
        for (c = 0; c < liveCols; c++) {
            head[c] = head[c] + speed[c];
            if (head[c] - trail[c].toFloat() > liveRows) {
                resetCol(c, false);
            }
        }
    }

    // Glyphs stick to the trail slot, not the grid row, so a strip slides.
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
        var cols = liveCols;
        var rows = liveRows;
        var colW = w.toFloat() / cols;
        var rowH = h.toFloat() / rows;
        var cx = w / 2;
        var cy = h / 2;
        var r2 = (cx - 8) * (cx - 8);
        var font = rainFont;
        var c;
        var d;
        for (c = 0; c < cols; c++) {
            var x = ((c.toFloat() + 0.5) * colW).toNumber();
            var len = trail[c];
            var hd = head[c];
            for (d = 0; d < len; d++) {
                var rowF = hd - d.toFloat();
                if (rowF < 0) {
                    continue;
                }
                var y = ((rowF + 0.5) * rowH).toNumber();
                var dx = x - cx;
                var dy = y - cy;
                if (dx * dx + dy * dy > r2) {
                    continue;
                }
                var color;
                if (d == 0) {
                    color = 0xC8FFC8;
                } else if (d == 1) {
                    color = 0x00FF41;
                } else if (d < 4) {
                    color = 0x14AA37;
                } else {
                    color = 0x084E18;
                }
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, y, font, glyphAt(c, d), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }
}
