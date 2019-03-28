import QtQuick 1.1
import com.nokia.meego 1.1
import com.nokia.extras 1.1
import QtMultimediaKit 1.1
import QtMobility.systeminfo 1.1
import com.yeatse.tbclient.extensions 1.0

Page{
	id: root;

	property string videosource;
	property string title;
	property int iPlayerOrientation: 1;
	property alias requestHeaders: video.requestHeaders;
	property alias headersEnabled: video.headersEnabled;

	property string __STATE_SHOW: "show";
	property string __STATE_HIDE: "hide";
	property int __PLAYER_RIGHT_BAR_WIDTH: 320;
	property int __PLAYER_TOP_BAR_HEIGHT: 60;

	orientationLock: iPlayerOrientation === 0 ? PageOrientation.Automatic : (iPlayerOrientation === 2 ? PageOrientation.LockPortrait : PageOrientation.LockLandscape);

	function _Load(pos) {
		video.source = root.videosource;
		if(video.source != "")
		{
			video.fillMode = YeatseVideo.PreserveAspectFit;
			video.play();

			if(pos && video.seekable)
				video.position = pos;
		}
	}

	function __Stop()
	{
		video.stop();
		video.source = "";
		video.position = 0;
	}

	function __Quit()
	{
		video.stop();
		pageStack.pop();
	}

	function __CastMS2S(t) {
		var format = "mm:ss";
		if(t >= 3600000){
			return parseInt(t / 3600000) + ":" + Qt.formatTime(new Date(t % 3600000), format);
		}else{
			return Qt.formatTime(new Date(t % 3600000), format);
		}
	}


	Rectangle{
		anchors.fill: parent;
		color: "black";
	}

	YeatseVideo {
		id: video;
		anchors.fill: parent;
		z: 1;
		headersEnabled: false;
		onError: {
			if(error !== YeatseVideo.NoError){
				signalCenter.showMessage(error + " : " + errorString);
				root.__Stop();
			}
		}
		onStatusChanged:{
			if(status === YeatseVideo.EndOfMedia){
				video.position = 0;
			}
		}
		volume: (devinfo.voiceRingtoneVolume > 50 ? 50 : devinfo.voiceRingtoneVolume < 20 ? 20 : devinfo.voiceRingtoneVolume) / 100;
		focus: true
		Keys.onSpacePressed: video.paused = !video.paused
		Keys.onLeftPressed: video.position -= 5000
		Keys.onRightPressed: video.position += 5000

		function setFillMode(value)
		{
			switch(value)
			{
				case 0:
				video.fillMode = YeatseVideo.Stretch;
				break;
				case 2:
				video.fillMode = YeatseVideo.PreserveAspectCrop;
				break;
				case 1:
				default:
				video.fillMode = YeatseVideo.PreserveAspectFit;
				break;
			}

		}
	}

	ScreenSaver{
		id: screensaver;
		screenSaverDelayed: video.playing && !video.paused;
	}
	DeviceInfo {
		id: devinfo;
	}

	Rectangle{
		id: toolbar;
		property int theight: root.__PLAYER_TOP_BAR_HEIGHT;
		anchors.bottom: parent.bottom;
		width: parent.width;
		color: "black";
		z: 2;
		opacity: 0.8;
		states: [
			State{
				name: root.__STATE_SHOW;
				PropertyChanges {
					target: toolbar;
					height: theight;
				}
			}
			,
			State{
				name: root.__STATE_HIDE;
				PropertyChanges {
					target: toolbar;
					height: 0;
				}
			}
		]
		state: root.__STATE_HIDE;
		transitions: [
			Transition {
				from: root.__STATE_HIDE;
				to: root.__STATE_SHOW;
				NumberAnimation{
					target: toolbar;
					property: "height";
					duration: 400;
					easing.type: Easing.OutExpo;
				}
			}
			,
			Transition {
				from: root.__STATE_SHOW;
				to: root.__STATE_HIDE;
				NumberAnimation{
					target: toolbar;
					property: "height";
					duration: 400;
					easing.type: Easing.InExpo;
				}
			}
		]
		onStateChanged: {
		}

		ToolIcon{
			id:play;
			iconId: video.paused ? "toolbar-mediacontrol-play" : "toolbar-mediacontrol-pause";
			anchors.left: parent.left;
			anchors.verticalCenter: parent.verticalCenter;
			enabled: video.playing;
			visible: parent.height === parent.theight;
			onClicked: {
				timer.restart();
				video.paused = !video.paused;
			}
		}

		Text{
			anchors.left: progressBar.left;
			anchors.top: parent.top;
			anchors.bottom: progressBar.top;
			color: "white";
			width: progressBar.width / 2;
			horizontalAlignment: Text.AlignLeft;
			verticalAlignment: Text.AlignVCenter;
			font.pixelSize: constant.fontSmall;
			visible: parent.height === parent.theight;
			text: visible ? __CastMS2S(video.position) : "";
			clip: true;
		}

		ProgressBar {
			id: progressBar
			anchors{
				left: play.right;
				right: stop.left;
				verticalCenter: toolbar.verticalCenter;
			}
			visible: parent.height === parent.theight;
			minimumValue: 0;
			maximumValue: video.duration || 0;
			value: video.position || 0;
			MouseArea{
				anchors.centerIn: parent;
				enabled: video.duration !== 0;
				width: parent.width;
				height: 5 * parent.height;
				onClicked: {
					timer.restart();
					if(video.seekable) {
						video.position = video.duration * mouse.x / parent.width;
					} else {
						setMsg(qsTr("Can not support seek for this video"));
					}
				}
				onPositionChanged: {
					if(pressed)
					{
						timer.restart();
						if(video.seekable) {
							video.position = video.duration * mouse.x / parent.width;
						} else {
							setMsg(qsTr("Can not support seek for this video"));
						}
					}
				}
			}
		}

		Text{
			id:durationtext;
			anchors.right: progressBar.right;
			anchors.top: parent.top;
			anchors.bottom: progressBar.top;
			color: "white";
			width: progressBar.width / 2;
			horizontalAlignment: Text.AlignRight;
			verticalAlignment: Text.AlignVCenter;
			font.pixelSize: constant.fontSmall;
			visible: parent.height === parent.theight;
			text: visible ? __CastMS2S(video.duration) : "";
			clip: true;
		}
		ToolIcon{
			id: stop;
			iconId: "toolbar-mediacontrol-stop";
			anchors.right: parent.right;
			anchors.verticalCenter: parent.verticalCenter;
			visible: parent.height === parent.theight;
			onClicked: {
				root.__Quit();
			}
		}
	}

	Timer{
		id: timer;
		interval: 8000;
		repeat: false;
		running: toolbar.state === root.__STATE_SHOW;
		onTriggered: {
			toolbar.state = root.__STATE_HIDE;
		}
	}

	MouseArea{
		anchors.fill: parent;
		onClicked: {
			if(toolbar.state === root.__STATE_HIDE) {
				toolbar.state=root.__STATE_SHOW;
			} else if(toolbar.state === root.__STATE_SHOW) {
				toolbar.state=root.__STATE_HIDE;
			}
		}
		onDoubleClicked: {
			if(video.playing){
				video.paused = ! video.paused;
			}
		}
	}

	BusyIndicator{
		id: show;
		anchors.centerIn: parent;
		z: 50;
		platformStyle:BusyIndicatorStyle{
			size: "large";
			inverted: true;
		}
		visible: video.playing && video.bufferProgress !== 1.0;
		running: visible;
	}

	Component.onDestruction:{
		video.stop();
	}
}
