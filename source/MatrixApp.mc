import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class MatrixApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new MatrixView()];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}

function getApp() as MatrixApp {
    return Application.getApp() as MatrixApp;
}
