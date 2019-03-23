import QtQuick 1.1
import com.nokia.meego 1.1
import "../../js/VideoParser.js" as Parser

Item {
	id: root;

	objectName: "Streamtype";

	property string source;
	property string vid;
	property string url;
	property alias model: repeater.model;
	property bool inverted: false;
	signal playStarted;

	property int __CELL_WIDTH: 120;

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

	function _ParseId(s, id)
	{
		var r = Parser.GetStreamtypesById(s, id, repeater.model);
		root.source = s;
		root.vid = id;
		return r;
	}

	function _Clear()
	{
		source = vid = url = "";
		repeater.model.clear();
	}

	function _Play(url, type, part)
	{
		root.playStarted();
		signalCenter.showMessage("[INFO]: %1 -> %2[%3]".arg(qsTr("Playing video")).arg(type).arg(part));
		if(url !== "")
		{
			Parser.PlayVideo(url, root.source);
		}
		else
		{
			Parser.ParseVideo(root.source, root.vid, type, part);
		}
	}

	function _Copy(url)
	{
		if(url !== "")
		{
			utility.copyToClipbord(url);
			signalCenter.showMessage("[INFO]: %1".arg(qsTr("Copy video url to clipboard")));
		}
	}

	function _SortStreamType(opt)
	{
		if(streamtypemodel.count <= 1) return;

		var o = (typeof(opt) === "string" && opt.toUpperCase() === "DESC") || (typeof(opt) !== "string" && opt) ? "DESC" : "ASC";
		for(var i = 0; i < streamtypemodel.count; i++)
		{
			for(var j = i + 1; j < streamtypemodel.count; j++)
			{
				if(o === "DESC")
				{
					if(streamtypemodel.get(j).index > streamtypemodel.get(i).index)
					{
						streamtypemodel.move(j, i, 1);
					}
				}
				else
				{
					if(streamtypemodel.get(j).index < streamtypemodel.get(i).index)
					{
						streamtypemodel.move(j, i, 1);
					}
				}
			}
		}
	}

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
							height: constant.graphicSizeMedium;
							text: model.name;
							color: root.inverted ? "white" : "black";
							font.bold: true;
							font.pixelSize: constant.fontLarge;
							elide: Text.ElideLeft;
							wrapMode: Text.WordWrap;
							maximumLineCount: 2;
							clip: true;
						}
						Rectangle{
							id: line;
							width: parent.width - constant.graphicSizeMedium;
							height: 1;
							anchors.horizontalCenter: parent.horizontalCenter;
							color: root.inverted ? "#eeeeee" : "#333333";
							smooth: true;
						}
						Grid{
							id:grid;
							property variant submodel:model.part;
							columns: Math.round(layout.width / root.__CELL_WIDTH);
							clip: true;
							width: parent.width;
							Repeater{
								model: grid.submodel;
								Item{
									width: root.__CELL_WIDTH;
									height: constant.graphicSizeMedium;
									Text{
										anchors.fill: parent;
										font.pixelSize: constant.fontMedium;
										color: model.url.length ? (root.inverted ? "white" : "black") : "red";
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

