import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

class FaceData {
    var timeStr as String = "0000";
    var secStr as String = "00";
    var dateStr as String = "";
    var wxStr as String = "wx  --";
    var wxVal as String = "--";
    var battPct as Number = 0;
    var battStr as String = "0%";
    var epochStr as String = "";
    var epochLine as String = "epoch 0";
    var prompt as String = "root@fenix8:~#";
    var blink as String = "#";
    var promptLine as String = "root@fenix8:~# #";

    var _lastSec as Number = -1;
    var _lastMin as Number = -1;

    function refresh() as Void {
        var clock = System.getClockTime();
        if (clock.sec == _lastSec) {
            return;
        }
        _lastSec = clock.sec;
        secStr = pad2(clock.sec);

        timeStr = pad2(clock.hour) + pad2(clock.min);
        if ((clock.sec % 2) == 0) {
            blink = "#";
        } else {
            blink = " ";
        }
        promptLine = prompt + " " + blink;

        if (clock.min != _lastMin) {
            _lastMin = clock.min;
            refreshSlow();
        }

        var stats = System.getSystemStats();
        battPct = stats.battery.toNumber();
        battStr = battPct.toString() + "%";
        epochStr = Time.now().value().toString();
        epochLine = "epoch " + epochStr;
    }

    function refreshSlow() as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;
        var dow = (info.day_of_week as Number) - 1;
        if (dow < 0 || dow > 6) {
            dow = 0;
        }
        dateStr = days[dow] + "  " + (info.year as Number).toString() + "-" + pad2(info.month as Number) + "-" + pad2(info.day as Number);
        wxVal = weatherLine();
        wxStr = "wx  " + wxVal;
    }

    function weatherLine() as String {
        if (!(Toybox has :Weather)) {
            return "--";
        }
        var cond = Weather.getCurrentConditions();
        if (cond == null || cond.temperature == null) {
            return "--";
        }
        var celsius = (cond.temperature as Float);
        var settings = System.getDeviceSettings();
        var unit = "C";
        var t = celsius;
        if (settings.temperatureUnits == System.UNIT_STATUTE) {
            t = celsius * 9.0 / 5.0 + 32.0;
            unit = "F";
        }
        var code = "---";
        if (cond.condition != null) {
            code = metar(cond.condition as Number);
        }
        return t.toNumber().toString() + unit + "  " + code;
    }

    function metar(c as Number) as String {
        if (c == Weather.CONDITION_CLEAR || c == Weather.CONDITION_MOSTLY_CLEAR || c == Weather.CONDITION_PARTLY_CLEAR) {
            return "CLR";
        }
        if (c == Weather.CONDITION_PARTLY_CLOUDY || c == Weather.CONDITION_WINDY) {
            return "SCT";
        }
        if (c == Weather.CONDITION_MOSTLY_CLOUDY || c == Weather.CONDITION_CLOUDY) {
            return "BKN";
        }
        if (c == Weather.CONDITION_RAIN || c == Weather.CONDITION_LIGHT_RAIN || c == Weather.CONDITION_HEAVY_RAIN || c == Weather.CONDITION_SHOWERS || c == Weather.CONDITION_LIGHT_SHOWERS || c == Weather.CONDITION_HEAVY_SHOWERS || c == Weather.CONDITION_SCATTERED_SHOWERS) {
            return "RA";
        }
        if (c == Weather.CONDITION_SNOW || c == Weather.CONDITION_LIGHT_SNOW || c == Weather.CONDITION_HEAVY_SNOW) {
            return "SN";
        }
        if (c == Weather.CONDITION_THUNDERSTORMS || c == Weather.CONDITION_SCATTERED_THUNDERSTORMS) {
            return "TS";
        }
        if (c == Weather.CONDITION_FOG) {
            return "FG";
        }
        return "OVC";
    }

    function pad2(n as Number) as String {
        if (n < 10) {
            return "0" + n.toString();
        }
        return n.toString();
    }
}
