import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

(:glance)
module Dump {
    function pad2(n as Number) as String {
        if (n < 10) {
            return "0" + n.toString();
        }
        return n.toString();
    }

    function timeStr() as String {
        var clock = System.getClockTime();
        var hour = clock.hour;
        var settings = System.getDeviceSettings();
        if (!settings.is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return pad2(hour) + ":" + pad2(clock.min);
    }

    function timeWithSec() as String {
        return timeStr() + ":" + pad2(System.getClockTime().sec);
    }

    function dateStr() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;
        var dow = (info.day_of_week as Number) - 1;
        if (dow < 0 || dow > 6) {
            dow = 0;
        }
        return days[dow] + "  " + (info.year as Number).toString() + "-" + pad2(info.month as Number) + "-" + pad2(info.day as Number);
    }

    function battStr() as String {
        return System.getSystemStats().battery.toNumber().toString() + "%";
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

    function wxStr() as String {
        if (!(Toybox has :Weather)) {
            return "--";
        }
        var cond = Weather.getCurrentConditions();
        if (cond == null || cond.temperature == null) {
            return "--";
        }
        var celsius = cond.temperature as Float;
        var unit = "C";
        var t = celsius;
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
            t = celsius * 9.0 / 5.0 + 32.0;
            unit = "F";
        }
        var code = "---";
        if (cond.condition != null) {
            code = metar(cond.condition as Number);
        }
        return t.toNumber().toString() + unit + "  " + code;
    }

    function hrStr() as String {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return (info.currentHeartRate as Number).toString();
        }
        return "--";
    }

    function stepsStr() as String {
        var info = ActivityMonitor.getInfo();
        if (info.steps != null) {
            return (info.steps as Number).toString();
        }
        return "--";
    }
}
