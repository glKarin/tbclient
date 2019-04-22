import QtQuick 1.1
import com.nokia.meego 1.1
import "Component"
import "Silica"

MyPage {
    id: page;

    title: qsTr("Video");

    tools: ToolBarLayout {
        BackButton {}

				Row{
					width: childrenRect.width;
					height: childrenRect.height;
					anchors.verticalCenter: parent.verticalCenter;
					visible: st.model.count > 1;
					ToolButton{
						text: qsTr("Sort asc");
						onClicked: {
							st._SortStreamType("ASC");
						}
					}
					ToolButton{
						text: qsTr("Sort desc");
						onClicked: {
							st._SortStreamType("DESC");
						}
					}
				}
    }

    QtObject {
			id: internal;
			property string source;
				property variant aSourceList: [
					{
						name: qsTr("Url"),
						value: "url",
					},
					{
						name: qsTr("Youku"),
						value: "youku",
					},
					{
						name: qsTr("Acfun"),
						value: "acfun",
					},
					{
						name: qsTr("Bilibili"),
						value: "bilibili",
					},
				];

				function _SetSource(s)
				{
					source = s;
					internal._MakeInputFocus();
				}

				function _Parse(text)
				{
					loading = true;
					st._Clear();
					if(source && source !== "url")
					{
						st._ParseId(source, text);
					}
					else
					{
						st._ParseUrl(text);
					}
					loading = false;
				}

				function _MakeInputFocus()
				{
					searchInput.forceActiveFocus();
					searchInput.platformOpenSoftwareInputPanel();
				}

    }

    ViewHeader {
        id: viewHeader;
        title: page.title;
        onClicked: view.scrollToTop();
    }

    Item {
        id: searchItem;
        anchors.top: viewHeader.bottom;
        width: parent.width;
				height: constant.graphicSizeLarge;
				z: 1;
        SearchInput {
            id: searchInput;
            anchors {
                left: parent.left; leftMargin: constant.paddingLarge;
                right: searchBtn.left; rightMargin: constant.paddingMedium;
                verticalCenter: parent.verticalCenter;
            }
            placeholderText: qsTr("Please input a video ID or url");
						onCleared: {
							internal._MakeInputFocus();
						}
            //onTypeStopped: {}
						platformSipAttributes: SipAttributes {
							actionKeyLabel: qsTr("OK");
							actionKeyHighlighted: actionKeyEnabled;
							actionKeyEnabled: searchInput.text !== "";
						}
						Keys.onReturnPressed:{
							searchBtn.clicked();
						}
        }
        Button {
            id: searchBtn;
            anchors {
                right: parent.right; rightMargin: constant.paddingLarge;
                verticalCenter: parent.verticalCenter;
            }
						enabled: searchInput.text !== "";
            platformStyle: ButtonStyle { buttonWidth: buttonHeight; }
            iconSource: "image://theme/icon-m-toolbar-mediacontrol-play"+(theme.inverted?"-white":"");
            onClicked: {
							if (searchInput.text !== "")
							internal._Parse(searchInput.text);
							else
							signalCenter.showMessage(qsTr("Please input video ID or url"));
            }
        }
    }

    SilicaListView {
        id: view;
				anchors { 
					left: parent.left;
					right: parent.right;
					top: searchItem.bottom;
				}
        height: constant.graphicSizeMedium;
				model: internal.aSourceList;
				clip: true;
        pressDelay: 120;
        cacheBuffer: 2000;
				orientation: ListView.Horizontal;
        delegate: forumDelegate;
        Component {
            id: forumDelegate;
            Item {
                id: root;
                width: 180;
                height: view.height;
								clip: true;
                BorderImage {
                    id: background;
                    anchors {
                        fill: parent;
                        margins: constant.paddingSmall;
                    }
                    border {
                        left: 10; top: 10;
                        right: 10; bottom: 10;
                    }
                    source: "gfx/bg_pop_choose_"+(mouseArea.pressed?"s":"n")+constant.invertedString;
                }
                Text {
                    anchors {
                        leftMargin: 16;
												rightMargin: 16;
												fill: background;
                    }
                    text: modelData.name;
										font: parent.ListView.isCurrentItem ? constant.titleFont : constant.labelFont;
										color: parent.ListView.isCurrentItem ? constant.colorTextSelection : constant.colorLight;
                    wrapMode: Text.Wrap;
										horizontalAlignment: Text.AlignHCenter;
										verticalAlignment: Text.AlignVCenter;
                    elide: Text.ElideRight;
                    maximumLineCount: 2;
                }
                MouseArea {
                    id: mouseArea;
                    anchors.fill: parent;
										onClicked: {
											view.currentIndex = index;
											internal._SetSource(modelData.value);
										}
                }
            }
        }
    }

		Streamtype{
			id: st;
			anchors{
				top: view.bottom;
				left: parent.left;
				right: parent.right;
				bottom: parent.bottom;
			}
			visible: model.count > 0;
			inverted: !tbsettings.whiteTheme;
		}

	}
