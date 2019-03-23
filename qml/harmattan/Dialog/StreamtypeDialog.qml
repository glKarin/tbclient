import QtQuick 1.1
import com.nokia.meego 1.1
import "../Component"
import "../../js/VideoParser.js" as Parser

DynamicCommonDialog {
    id: root;

		objectName: "StreamtypeDialog";
    titleText: qsTr("Stream types") + ": " + st.source;

		property alias source: st.source;
		property alias vid: st.vid;
		property alias url: st.url;
		property alias model: st.model;

		function _Load(url_or_id, source)
		{
			if(source && source !== "url")
			{
				return st._ParseId(source, url_or_id);
			}
			else
			{
				return st._ParseUrl(url_or_id);
			}
		}

		content: Streamtype {
			id: st;
			width: root.width;
			height: root._iContentHeight;
			inverted: true;
			onPlayStarted: {
				root.close();
			}
		}

		tools: [
			Row{
				width: childrenRect.width;
				height: childrenRect.height;
				visible: st.model.count > 1;
				spacing: constant.paddingLarge;
				Button{
					text: qsTr("Sort asc");
					width: 160;
					onClicked: {
						st._SortStreamType("ASC");
					}
				}
				Button{
					text: qsTr("Sort desc");
					width: 160;
					onClicked: {
						st._SortStreamType("DESC");
					}
				}
			}
		]
	}
