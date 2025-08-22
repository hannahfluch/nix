import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Utils
import qs.Services
import qs.Widgets

// Loader for Notification History panel
LoaderWidget {
    id: root

    content: Component {
        PanelWidget {
            id: notificationPanel
            showOverlay: false

            // Override hide function to animate first
            function hide() {
                // Start hide animation
                notificationRect.scaleValue = 0.8;
                notificationRect.opacityValue = 0.0;

                // Hide after animation completes
                hideTimer.start();
            }
            Shortcut {
                sequence: "Escape"
                context: Qt.WindowShortcut
                onActivated: notificationPanel.hide()
            }

            Connections {
                target: notificationPanel
                ignoreUnknownSignals: true
                function onDismissed() {
                    // Start hide animation
                    notificationRect.scaleValue = 0.8;
                    notificationRect.opacityValue = 0.0;

                    // Hide after animation completes
                    hideTimer.start();
                }
            }

            // Also handle visibility changes from external sources
            onVisibleChanged: {
                if (!visible && notificationRect.opacityValue > 0) {
                    // Start hide animation
                    notificationRect.scaleValue = 0.8;
                    notificationRect.opacityValue = 0.0;

                    // Hide after animation completes
                    hideTimer.start();
                }
            }

            // Timer to hide panel after animation
            Timer {
                id: hideTimer
                interval: Style.animationSlow
                repeat: false
                onTriggered: {
                    notificationPanel.visible = false;
                    notificationPanel.dismissed();
                }
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Rectangle {
                id: notificationRect
                color: Color.mSurface
                radius: Style.radiusL * scaling
                border.color: Color.mOutline
                border.width: Math.max(1, Style.borderS * scaling)
                width: 400 * scaling
                height: 500 * scaling
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.marginXS * scaling
                anchors.rightMargin: Style.marginXS * scaling
                clip: true

                // Animation properties
                property real scaleValue: 0.8
                property real opacityValue: 0.0

                scale: scaleValue
                opacity: opacityValue

                // Animate in when component is completed
                Component.onCompleted: {
                    scaleValue = 1.0;
                    opacityValue = 1.0;
                }

                // Animation behaviors
                Behavior on scale {
                    NumberAnimation {
                        duration: Style.animationSlow
                        easing.type: Easing.OutExpo
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.animationNormal
                        easing.type: Easing.OutQuad
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginL * scaling
                    spacing: Style.marginM * scaling

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM * scaling

                        IconWidget {
                            text: "notifications"
                            font.pointSize: Style.fontSizeXXL * scaling
                            color: Color.mPrimary
                        }

                        TextWidget {
                            text: "Notification History"
                            font.pointSize: Style.fontSizeL * scaling
                            font.bold: true
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        IconButtonWidget {
                            icon: "delete"
                            tooltipText: "Clear History"
                            sizeMultiplier: 0.8
                            onClicked: NotificationService.clearHistory()
                        }

                        IconButtonWidget {
                            icon: "close"
                            tooltipText: "Close"
                            sizeMultiplier: 0.8
                            onClicked: {
                                notificationPanel.hide();
                            }
                        }
                    }

                    DividerWidget {}

                    // Empty state when no notifications
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: NotificationService.historyModel.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.marginM * scaling

                            IconWidget {
                                text: "notifications_off"
                                font.pointSize: Style.fontSizeXXXL * scaling
                                color: Color.mOnSurfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }

                            TextWidget {
                                text: "No notifications"
                                font.pointSize: Style.fontSizeL * scaling
                                color: Color.mOnSurfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }

                            TextWidget {
                                text: "Notifications will appear here when you receive them"
                                font.pointSize: Style.fontSizeNormal * scaling
                                color: Color.mOnSurfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    ListView {
                        id: notificationList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: NotificationService.historyModel
                        spacing: Style.marginM * scaling
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: NotificationService.historyModel.count > 0

                        delegate: Rectangle {
                            width: notificationList ? (notificationList.width - 20) : 380 * scaling
                            height: Math.max(80, notificationContent.height + 30)
                            radius: Style.radiusM * scaling
                            color: notificationMouseArea.containsMouse ? Color.mPrimary : Color.mSurfaceVariant

                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Style.marginM * scaling
                                }
                                spacing: Style.marginM * scaling

                                // Notification content
                                Column {
                                    id: notificationContent
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: Style.marginXXS * scaling

                                    TextWidget {
                                        text: (summary || "No summary").substring(0, 100)
                                        font.pointSize: Style.fontSizeM * scaling
                                        font.weight: Font.Medium
                                        color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                                        wrapMode: Text.Wrap
                                        width: parent.width - 60
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }

                                    TextWidget {
                                        text: (body || "").substring(0, 150)
                                        font.pointSize: Style.fontSizeXS * scaling
                                        color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                                        wrapMode: Text.Wrap
                                        width: parent.width - 60
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }

                                    TextWidget {
                                        text: NotificationService.formatTimestamp(timestamp)
                                        font.pointSize: Style.fontSizeXS * scaling
                                        color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                                    }
                                }

                                // Trash icon button
                                IconButtonWidget {
                                    icon: "delete"
                                    tooltipText: "Delete Notification"
                                    sizeMultiplier: 0.7

                                    onClicked: {
                                        Logger.log("NotificationHistory", "Removing notification:", summary);
                                        NotificationService.historyModel.remove(index);
                                        NotificationService.saveHistory();
                                    }
                                }
                            }

                            MouseArea {
                                id: notificationMouseArea
                                anchors.fill: parent
                                anchors.rightMargin: Style.marginL * 3 * scaling
                                hoverEnabled: true
                                // Remove the onClicked handler since we now have a dedicated delete button
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                    }
                }
            }
        }
    }
}
