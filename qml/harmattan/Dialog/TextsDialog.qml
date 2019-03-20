import QtQuick 1.1
import com.nokia.meego 1.1
import "../../js/VideoParser.js" as Parser

DynamicCommonDialog {
    id: root;

		objectName: "TextsDialog";

		property variant model: [];

		content: Item {
			id: contentField;
			width: root.width;
			height: width * 1.2;
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

}
