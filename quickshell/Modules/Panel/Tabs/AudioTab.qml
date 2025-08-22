import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Widgets
import qs.Utils
import qs.Services

ColumnLayout {
  id: root

  property real localVolume: AudioService.volume

  // Connection used to open the pill when volume changes
  Connections {
    target: AudioService.sink?.audio ? AudioService.sink?.audio : null
    function onVolumeChanged() {
      localVolume = AudioService.volume
    }
  }

  spacing: 0

  ScrollView {
    id: scrollView

    Layout.fillWidth: true
    Layout.fillHeight: true
    padding: Style.marginM * scaling
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: scrollView.availableWidth
      spacing: 0

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
      }

      ColumnLayout {
        spacing: Style.marginXS * scaling
        Layout.fillWidth: true

        TextWidget {
          text: "Audio Output Volume"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Volume Controls
        ColumnLayout {
          spacing: Style.marginS * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginS * scaling

          // Master Volume
          ColumnLayout {
            spacing: Style.marginS * scaling
            Layout.fillWidth: true

            LabelWidget {
              label: "Master Volume"
              description: "System-wide volume level."
            }

            RowLayout {
              // Pipewire seems a bit finicky, if we spam too many volume changes it breaks easily
              // Probably because they have some quick fades in and out to avoid clipping
              // We use a timer to space out the updates, to avoid lock up
              Timer {
                interval: Style.animationFast
                running: true
                repeat: true
                onTriggered: {
                  if (Math.abs(localVolume - AudioService.volume) >= 0.01) {
                    AudioService.setVolume(localVolume)
                  }
                }
              }

              SliderWidget {
                Layout.fillWidth: true
                from: 0
                to: Settings.data.volumeOverdrive ? 2.0 : 1.0
                value: localVolume
                stepSize: 0.01
                onMoved: {
                  localVolume = value
                }
              }

              TextWidget {
                text: Math.floor(AudioService.volume * 100) + "%"
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Style.marginS * scaling
                color: Color.mOnSurface
              }
            }
          }

          // Mute Toggle
          ColumnLayout {
            spacing: Style.marginS * scaling
            Layout.fillWidth: true
            Layout.topMargin: Style.marginM * scaling

            ToggleWidget {
              label: "Mute Audio Output"
              description: "Mute or unmute the default audio output."
              checked: AudioService.muted
              onToggled: checked => {
                           if (AudioService.sink && AudioService.sink.audio) {
                             AudioService.sink.audio.muted = checked
                           }
                         }
            }
          }
        }

        DividerWidget {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginL * 2 * scaling
          Layout.bottomMargin: Style.marginL * scaling
        }

        // AudioService Devices
        ColumnLayout {
          spacing: Style.marginL * scaling
          Layout.fillWidth: true

          TextWidget {
            text: "Audio Devices"
            font.pointSize: Style.fontSizeXXL * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.bottomMargin: Style.marginS * scaling
          }

          // -------------------------------
          // Output Devices
          ButtonGroup {
            id: sinks
          }

          ColumnLayout {
            spacing: Style.marginXS * scaling
            Layout.fillWidth: true
            Layout.bottomMargin: Style.marginL * scaling

            LabelWidget {
              label: "Output Device"
              description: "Select the desired audio output device."
            }

            Repeater {
              model: AudioService.sinks
              RadioButtonWidget {
                required property PwNode modelData
                ButtonGroup.group: sinks
                checked: AudioService.sink?.id === modelData.id
                onClicked: AudioService.setAudioSink(modelData)
                text: modelData.description
              }
            }
          }
        }

        // -------------------------------
        // Input Devices
        ButtonGroup {
          id: sources
        }

        ColumnLayout {
          spacing: Style.marginXS * scaling
          Layout.fillWidth: true
          Layout.bottomMargin: Style.marginL * scaling

          LabelWidget {
            label: "Input Device"
            description: "Select the desired audio input device."
          }

          Repeater {
            model: AudioService.sources
            RadioButtonWidget {
              required property PwNode modelData
              ButtonGroup.group: sources
              checked: AudioService.source?.id === modelData.id
              onClicked: AudioService.setAudioSource(modelData)
              text: modelData.description
            }
          }
        }
      }
    }
  }
}
