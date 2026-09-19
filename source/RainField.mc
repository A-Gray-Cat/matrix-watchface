import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Compact digital-rain field. Column state is four parallel arrays so we
// never allocate per frame. Glyph strings are interned at init.
class RainField {
    const COLS = 16;
    const ROWS = 20;

    var head as Array<Float>;
    var speed as Array<Float>;
    var trail as Array<Number>;
    var seed as Array<Number>;
    var glyphs as Array<String>;
    var nGlyphs as Number = 0;
    var rainFont as FontType = Graphics.FONT_XTINY;
    var rainFontReady as Boolean = false;

    function initialize() {
        // Matrix rain: half-width katakana + digits + a few latin (the film mix).
        var charset = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ012345789Z:=*+$";
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

    function resetCol(c as Number, scatter as Boolean) as Void {
        if (scatter) {
            head[c] = (Math.rand() % ROWS).toFloat();
        } else {
            head[c] = 0.0;
        }
        speed[c] = 0.28 + (Math.rand() % 70).toFloat() / 100.0;
        trail[c] = 7 + (Math.rand() % 8);
        seed[c] = Math.rand();
    }

    function step() as Void {
        var c;
        for (c = 0; c < COLS; c++) {
            head[c] = head[c] + speed[c];
            if (head[c] - trail[c].toFloat() > ROWS) {
                resetCol(c, false);
            }
        }
    }

    function glyphAt(c as Number, row as Number) as String {
        var n = seed[c] + c * 131 + row * 17;
        if (n < 0) {
            n = -n;
        }
        return glyphs[n % nGlyphs];
    }

    function prepareFont(h as Number) as Void {
        if (rainFontReady) {
            return;
        }
        if (Graphics has :getVectorFont) {
            var f = Graphics.getVectorFont({:face => ["KosugiRegular", "RobotoRegular"], :size => h * 0.038});
            if (f != null) {
                rainFont = f;
            }
        }
        rainFontReady = true;
    }

    function draw(dc as Graphics.Dc, w as Number, h as Number) as Void {
        prepareFont(h);
        var colW = w.toFloat() / COLS;
        var rowH = h.toFloat() / ROWS;
        var cx = w / 2;
        var cy = h / 2;
        var r2 = (cx - 8) * (cx - 8);
        var font = rainFont;
        var c;
        var d;
        for (c = 0; c < COLS; c++) {
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
                dc.drawText(x, y, font, glyphAt(c, rowF.toNumber()), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }
}
