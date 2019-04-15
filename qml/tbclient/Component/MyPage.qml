import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: root;

    property string title;
    property bool loading;
    property bool loadingVisible: loading && (internal.view?internal.view.count===0:false);
    property string loadingText: qsTr("Loading");

		orientationLock: tbsettings.orientation == 1 ? PageOrientation.LockPortrait : (tbsettings.orientation == 2 ? PageOrientation.LockLandscape : PageOrientation.Automatic);

    QtObject {
        id: internal;

        property variant view: null;

        function getFlickable(){
            for (var i = 0; i<root.children.length; i++){
                var c = root.children[i];
                if (c.hasOwnProperty("flicking") && c.hasOwnProperty("count")){
                    view = c;
                    return;
                }
            }
        }
    }

    Text {
        id: loadingLabel;
        visible: root.loadingVisible;
        anchors.centerIn: parent;
        font.pixelSize: constant.fontXXLarge;
        color: constant.colorDisabled;
        text: root.loadingText;
    }

    Binding {
        target: statusPaneText;
        property: "text";
        value: root.title;
        when: root.visible && root.status === PageStatus.Active;
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Backspace){
            pageStack.pop();
            event.accepted = true;
        }
    }

    Component.onCompleted: internal.getFlickable();
}
