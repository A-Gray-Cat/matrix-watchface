import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

// Full-page helpers. Not (:glance) — keep the 64KB glance process thin.
module Status {
    function clip(s as String, max as Number) as String {
        if (s.length() <= max) {
            return s;
        }
        return s.substring(0, max) as String;
    }

    function workoutsLine() as String {
        if (!(Toybox has :PersistedContent) || !(PersistedContent has :getWorkouts)) {
            return "--";
        }
        var it = PersistedContent.getWorkouts();
        var line = "";
        var n = 0;
        var extra = 0;
        var w = it.next();
        while (w != null) {
            if (n < 2) {
                var name = w.getName();
                if (name != null && name.length() > 0) {
                    if (n > 0) {
                        line = line + " | ";
                    }
                    line = line + clip(name, 14);
                    n++;
                }
            } else {
                extra++;
            }
            w = it.next();
        }
        if (n == 0) {
            return "--";
        }
        if (extra > 0) {
            line = line + " +" + extra.toString();
        }
        return line;
    }

    function bodyBattStr() as String {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getBodyBatteryHistory)) {
            return "--";
        }
        var it = SensorHistory.getBodyBatteryHistory({:period => new Time.Duration(14400)});
        var sample = it.next();
        if (sample == null || sample.data == null) {
            return "--";
        }
        return (sample.data as Number).toNumber().toString();
    }

    function stressStr() as String {
        var info = ActivityMonitor.getInfo();
        if (info has :stressScore && info.stressScore != null) {
            return (info.stressScore as Number).toString();
        }
        return "--";
    }

    function stepsGoalStr() as String {
        var info = ActivityMonitor.getInfo();
        var steps = "--";
        if (info.steps != null) {
            steps = (info.steps as Number).toString();
        }
        if (info.stepGoal != null && (info.stepGoal as Number) > 0) {
            var g = info.stepGoal as Number;
            var gs = g.toString();
            if (g >= 1000 && (g % 1000) == 0) {
                gs = (g / 1000).toString() + "k";
            }
            return steps + " / " + gs;
        }
        return steps;
    }

    function hm(moment as Time.Moment) as String {
        var t = Gregorian.info(moment, Time.FORMAT_SHORT);
        return Dump.pad2(t.hour as Number) + ":" + Dump.pad2(t.min as Number);
    }

    function sunStr() as String {
        if (!(Toybox has :Weather) || !(Weather has :getSunrise) || !(Weather has :getSunset)) {
            return "--";
        }
        var loc = null;
        var cond = Weather.getCurrentConditions();
        if (cond != null && cond.observationLocationPosition != null) {
            loc = cond.observationLocationPosition;
        }
        if (loc == null) {
            var act = Activity.getActivityInfo();
            if (act != null && act.currentLocation != null) {
                loc = act.currentLocation;
            }
        }
        if (loc == null) {
            return "--";
        }
        var now = Time.now();
        var rise = Weather.getSunrise(loc, now);
        var set = Weather.getSunset(loc, now);
        if (rise == null || set == null) {
            return "--";
        }
        return hm(rise) + " / " + hm(set);
    }
}
