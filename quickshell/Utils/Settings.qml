pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
import qs.Services

// this config is based on https://github.com/noctalia-dev/noctalia-shell/ and fine-tuned to personal preference!
Singleton {
    id: root

    property bool volumeOverdrive: false

    property string shellName: "chicken-shell"
    property string cacheDir: Quickshell.env("XDG_CACHE_HOME") + "/" + shellName + "/"
    property string dataFile: Quickshell.env("XDG_DATA_HOME") + "/" + shellName + "/state.json" // stuff like active wallpaper...
    // Used to access via Settings.data.xxx.yyy
    property alias data: adapter
    // Flag to prevent unnecessary wallpaper calls during reloads
    property bool isInitialLoad: true

    FileView {
        path: dataFile
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        Component.onCompleted: function () {
            reload();
        }
        onLoaded: function () {
            Logger.log("Settings", "OnLoaded");
            Qt.callLater(function () {
                // Only set wallpaper on initial load, not on reloads
                // if (isInitialLoad && adapter.wallpaper.current !== "") {
                //   Logger.log("Settings", "Set current wallpaper", adapter.wallpaper.current)
                //   WallpaperService.setCurrentWallpaper(adapter.wallpaper.current, true) todo!
                // }

                isInitialLoad = false;
            });
        }
        onLoadFailed: function (error) {
            if (error.toString().includes("No such file") || error === 2)
                // File doesn't exist, create it with default values
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // bar
            property JsonObject bar

            bar: JsonObject {
                property bool top: true
                property bool showNotificationsHistory: true
                property real backgroundOpacity: 1.0
                property list<string> monitors: []
            }

            // general
            property JsonObject general
            general: JsonObject {
                property bool dimDesktop: true
                property real defaultScale: 1.3333
            }

            // Scaling (not stored inside JsonObject, or it crashes)
            property var monitorsScaling: {}

            // brightness
            property JsonObject brightness

            // notifications
            property JsonObject notifications
            notifications: JsonObject {
                property list<string> monitors: []
                property bool suppressed: false
            }
        }
    }
}
