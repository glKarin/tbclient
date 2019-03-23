import QtQuick 1.1
import com.nokia.meego 1.1
import "../../js/VideoParser.js" as Parser

DynamicCommonDialog {
    id: root;

		objectName: "TextsDialog";

		property variant model: [];
		property variant sBottomTitle: "";

		content: Item {
			id: contentField;
			width: root.width;
			height: root._iContentHeight;
			Flickable{
				id: flickable;
				anchors.fill: parent;
				clip: true;
				contentWidth: width;
				contentHeight: layout.height;
				Column{
					id: layout;
					width: parent.width;
					spacing: constant.paddingSmall;
					Repeater {
						id: repeater;
						model: root.model;
						delegate: Component{
							Text{
								horizontalAlignment: modelData.horizontalAlignment ? modelData.horizontalAlignment : Text.AlignLeft;
								width: parent.width;
								text: modelData.text;
								color: modelData.color ? modelData.color : "white";
								font.bold: modelData.bold ? modelData.bold : false;
								font.pixelSize: modelData.pixelSize ? modelData.pixelSize : constant.fontMedium;
								wrapMode: Text.WordWrap;
								onLinkActivated: {
									if(link !== "") eval(link);
								}
							}
						}
					}
				}
			}

			ScrollDecorator{
				flickableItem: flickable;
			}

		}

		__drawFooterLine: sBottomTitle !== "";
		tools: [
			Text{
				width: root.width;
				height: constant.graphicSizeLarge;
				horizontalAlignment: Text.AlignHCenter;
				verticalAlignment: Text.AlignVCenter;
				text: root.sBottomTitle;
				color: "white";
				font.bold: true;
				font.pixelSize: constant.fontLarge;
				wrapMode: Text.WordWrap;
				elide: Text.ElideRight;
				maximumLineCount: 2;
				onLinkActivated: {
					if(link !== "") eval(link);
				}
			}
		]
	}
