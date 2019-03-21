import QtQuick 1.1
import com.nokia.meego 1.1
import "../../js/VideoParser.js" as Parser

DynamicCommonDialog {
    id: root;

		objectName: "StreamtypeDialog";
    titleText: qsTr("Stream types") + ": " + source;

		property string source;
		property string vid;
		property string url;
		property alias model: repeater.model;

		function _ParseUrl(url)
		{
			var r = Parser.GetStreamtypes(url, repeater.model);
			if(r)
			{
				root.url = url;
				root.vid = r.id;
				root.source = r.source;
			}
			return root.vid !== "";
		}

        function _Play(url, type, part)
		{
			showMessage("[INFO]: %1 -> %2[%3]".arg(qsTr("Playing video")).arg(type).arg(part));
			if(url !== "")
			{
                Parser.PlayVideo(url);
			}
			else
			{
				Parser.ParseVideo(root.source, root.vid, type, part);
			}
			root.close();
		}

		function _Copy(url)
		{
			if(url !== "")
			{
                utility.copyToClipbord(url);
				showMessage("[INFO]: %1".arg(qsTr("Copy video url to clipboard")));
			}
		}

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
					id:layout;
					width: parent.width;
					spacing: constant.paddingSmall;
					Repeater {
						id:repeater;
						model: ListModel{ id: streamtypemodel; }
						Item{
							width: layout.width;
							height: grid.height + header.height + line.height;
							Column{
								anchors.fill: parent;
								clip: true;
								Text{
									id: header;
									horizontalAlignment: Text.AlignHCenter;
									verticalAlignment: Text.AlignVCenter;
									width: parent.width;
									height: 48;
									text: model.name;
									color: "white";
									font.bold: true;
                                    font.pixelSize: constant.fontLarge;
								}
								Rectangle{
									id: line;
									width: parent.width - 64;
									height: 1;
									anchors.horizontalCenter: parent.horizontalCenter;
									color: "#eeeeee";
								}
								Grid{
									id:grid;
									columns: 4;
									clip: true;
									property variant submodel:model.part;
									width: parent.width;
									Repeater{
										model: grid.submodel;
										Item{
											width: 120;
											height: 60;
											Text{
												anchors.fill: parent;
												font.pixelSize: constant.fontMedium;
												color: model.url.length ? "white" : "red";
												text: "[" + model.name + "]";
												horizontalAlignment: Text.AlignHCenter;
												verticalAlignment: Text.AlignVCenter;
												elide: Text.ElideLeft;
											}
											MouseArea{
												anchors.fill: parent;
												onClicked: {
                                                    root._Play(model.url, model.title, model.value);
												}
												onPressAndHold: {
													root._Copy(model.url);
												}
											}
										}
									}
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
