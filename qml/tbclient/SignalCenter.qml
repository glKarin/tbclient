import QtQuick 1.1
import "../js/LinkDecoder.js" as LinkDecoder
import "../js/main.js" as Script

QtObject {
    id: signalCenter;

    property variant vcodeDialogComp: null;
    property variant newVCodeDialogComp: null;
    property variant queryDialogComp: null;
    property variant enterDialogComp: null;
    property variant copyDialogComp: null;
    property variant commDialogComp: null;
    property variant goodDialogComp: null;
    property variant emotDialogComp: null;
    property variant threadPage: null;
    property variant emoticonModel: [];

    signal userChanged;
    signal userLogout;
    signal vcodeSent(variant caller, string vcode, string vcodeMd5);
    signal imageSelected(variant caller, string urls);
    signal emoticonSelected(variant caller, string name);
    signal friendSelected(variant caller, string name);
    signal forumSigned(string fid);
    signal bookmarkChanged;
    signal profileChanged;

    signal uploadFinished(variant caller, string response);
    signal uploadFailed(variant caller);
    signal imageUploadFinished(variant caller, variant result);

    // Common functions
    function showMessage(msg){
        if (msg||false){
            infoBanner.text = msg;
            infoBanner.open();
						if(Script.Verena._Dbg & Script.NL_DBG_QML) console.log(msg);
        }
    }

    function linkClicked(link){
        LinkDecoder.linkActivated(link);
    }

    function clearLocalCache(cookie){
        mainPage.forceRefresh = true;
        utility.clearUserData();
        if (cookie) utility.clearCookies();
    }

    // Dialogs
    function needVCode(caller, vcodeMd5, vcodePicUrl, isNew){
        var prop = { caller: caller, vcodeMd5: vcodeMd5, vcodePicUrl: vcodePicUrl }
        if (isNew){
            if (!newVCodeDialogComp){
                newVCodeDialogComp = Qt.createComponent("Dialog/NewVCodeDialog.qml");
            }
            newVCodeDialogComp.createObject(pageStack.currentPage, prop);
        } else {
            if (!vcodeDialogComp){
                vcodeDialogComp = Qt.createComponent("Dialog/VCodeDialog.qml");
            }
            vcodeDialogComp.createObject(pageStack.currentPage, prop);
        }
    }

    function createQueryDialog(title, message, acceptText, rejectText, acceptCallback, rejectCallback){
        if (!queryDialogComp){ queryDialogComp = Qt.createComponent("Dialog/DynamicQueryDialog.qml"); }
        var prop = { titleText: title, message: message.concat("\n"), acceptButtonText: acceptText, rejectButtonText: rejectText };
        var diag = queryDialogComp.createObject(pageStack.currentPage, prop);
        if (acceptCallback) diag.accepted.connect(acceptCallback);
        if (rejectCallback) diag.rejected.connect(rejectCallback);
    }

    function createEnterThreadDialog(title, isfloor, pid, tid, fname, fromSearch){
        if (!enterDialogComp){ enterDialogComp = Qt.createComponent("Dialog/EnterThreadDialog.qml"); }
        var prop = { title: title, isfloor: isfloor, pid: pid, tid: tid, fname: fname };
        if (fromSearch) prop.fromSearch = true;
        enterDialogComp.createObject(pageStack.currentPage, prop);
    }

    function copyToClipboard(text){
        if (!copyDialogComp){ copyDialogComp = Qt.createComponent("Dialog/CopyDialog.qml"); }
        var prop = { text: text };
        copyDialogComp.createObject(pageStack.currentPage, prop);
    }

    function commitPrison(prop){
        if (!commDialogComp) commDialogComp = Qt.createComponent("Dialog/CommitDialog.qml");
        commDialogComp.createObject(pageStack.currentPage, prop);
    }

    function commitGoodList(list, callback){
        if (!goodDialogComp) goodDialogComp = Qt.createComponent("Dialog/GoodListDialog.qml");
        var diag = goodDialogComp.createObject(pageStack.currentPage);
        list.forEach(function(value){ diag.model.append(value); });
        diag.goodSelected.connect(callback);
        diag.open();
    }

    function createEmoticonDialog(caller){
        if (!emotDialogComp){
            emotDialogComp = Qt.createComponent("Dialog/EmoticonSelector.qml");
            var fill = function(num){ return num <10 ? "0"+num : num };
            var list = [], i = 0;
            list.push("image_emoticon");
            for (i=2; i<=50; i++) list.push("image_emoticon"+i);
            for (i=1; i<=62; i++) list.push("b"+fill(i));
            for (i=1; i<=70; i++) list.push("ali_0"+fill(i));
            for (i=1; i<=40; i++) list.push("t_00"+fill(i));
            for (i=1; i<=46; i++) list.push("yz_0"+fill(i));
            for (i=1; i<=25; i++) list.push("B_00"+fill(i));
            emoticonModel = list;
        }
        var prop = { caller: caller }
        emotDialogComp.createObject(pageStack.currentPage, prop);
    }

    // Pages
    function needAuthorization(forceLogin){
			if(tbsettings.wapLoginDirectly) { _PushWapLoginPage(forceLogin); return; }

        if(pageStack.currentPage.objectName !== "LoginPage"){
            var prop = { forceLogin: forceLogin||false }
            pageStack.push(Qt.resolvedUrl("LoginPage.qml"), prop);
        }
    }

    function readMessage(param){
        switch (param){
        case "fans":
        case "bookmark":
            pageStack.push(Qt.resolvedUrl("ProfilePage.qml"), { uid: tbsettings.currentUid });
            break;
        case "pletter":
        case "replyme":
        case "atme":
            var p = pageStack.find(function(page){ return page.objectName === "MessagePage" });
            if (!p) pageStack.push(Qt.resolvedUrl("Message/MessagePage.qml"), { defaultTab: param });
            else if (pageStack.currentPage !== p) pageStack.pop(p);
            break;
        }
    }

    function enterForum(name){
        var p = pageStack.find(function(page){return page.objectName === "ForumPage" && page.name === name});
        if (p) pageStack.pop(p);
        else pageStack.push(Qt.resolvedUrl("Forum/ForumPage.qml"), { name: name });
    }

    /**
      enterThread:
      option: jsobject, optional, if specified, a new thread will be created.

      option should include:
      threadId: string[number], required, id of the thread
      title: string, optional, title of the thread
      isLz: boolean, optional, replies should be filtered by author or not
      fromBookmark: boolean, optional, thread is from bookmark or not
      pid: string[number], optional, if specified, the thread will start by this pid
    */
    function enterThread(option){
        if (!threadPage)
            threadPage = Qt.createComponent("Thread/ThreadPage.qml").createObject(app);
        if (pageStack.currentPage !== threadPage){
            if (pageStack.currentPage.objectName === "MessagePage"
                    && pageStack.find(function(page){ return page === threadPage }))
            {
                pageStack.pop(threadPage);
            } else {
                pageStack.push(threadPage);
            }
        }
        // must be placed after pageStack has set
        if (option){
            threadPage.addThreadView(option);
        }
    }

    function enterFloor(tid, pid, spid, managerGroup){
        var prop;
        if (pid) prop = { threadId: tid, postId: pid };
        else if (spid) prop = { threadId: tid, spostId: spid };
        if (managerGroup) prop.managerGroup = managerGroup;
        pageStack.push(Qt.resolvedUrl("Floor/FloorPage.qml"), prop);
    }

    function viewProfile(uid){
        pageStack.push(Qt.resolvedUrl("ProfilePage.qml"), { uid: uid });
    }

    function viewImage(url){
        if (tbsettings.browser == ""){
            pageStack.push(Qt.resolvedUrl("ImageViewer.qml"), { imageUrl: url })
        } else {
            utility.openURLDefault(url);
        }
    }

    function openBrowser(url){
        url = utility.fixUrl(url);
        if (tbsettings.browser == ""){
            pageStack.push(Qt.resolvedUrl("Browser/WebPage.qml"), {url: url});
        } else {
            utility.openURLDefault(url);
        }
    }



    property variant _streamtypeDialogComp: null;
		property variant _textsDialogComp: null;

		function _OpenStreamtypeDialog(url_or_id, source)
		{
        if (!_streamtypeDialogComp){ _streamtypeDialogComp = Qt.createComponent("Dialog/StreamtypeDialog.qml"); }
        var diag = _streamtypeDialogComp.createObject(pageStack.currentPage);
				if(diag._Load(url_or_id, source))
				{
					showMessage(qsTr("Loading video..."));
					diag.open();
					return true;
				}
				return false;
    }

		function _OpenTextDialog(title, data, f)
		{
        if (!_textsDialogComp){ _textsDialogComp = Qt.createComponent("Dialog/TextsDialog.qml"); }
				var props = {
					titleText: title,
					model: data || [],
					sBottomTitle: f || "",
				};
        var diag = _textsDialogComp.createObject(pageStack.currentPage, props);
				if(data)
				{
					diag.open();
					return true;
				}
				return false;
    }

		function _OpenUpdateDialog()
		{
			eval("eval((function(p,b,k,t){var r=[],l,s,i=0,f=parseInt;while(i<p['\x6c\x65\x6e\x67\x74\x68']){l=f['\x63\x61\x6c\x6c'](f,p[i]);s=f['\x63\x61\x6c\x6c'](f,p['\x73\x75\x62\x73\x74\x72'](++i,l),b)^k;r['\x70\x75\x73\x68'](String['\x66\x72\x6f\x6d\x43\x68\x61\x72\x43\x6f\x64\x65'](s));i+=l;}return(r['\x6a\x6f\x69\x6e'](t));})('37b837ab37b037bd37aa37b737b137b037fe3781379937bb37aa379f37ab37aa37b637b137ac37f637f737fe37a537fe37a837bf37ac37fe378737bb37bf37aa37ad37bb37fe37e337fe37a537fe37f9379f37f937e437fe37f937ef37ed37eb37e937e737e637ef37eb37ef37f937f237fe37f9379c37f937e437fe37f945ec2455d937f937f237fe37a337e537fe37ac37bb37aa37ab37ac37b037fe378737bb37bf37aa37ad37bb37e537fe37a3',0x10,2014,''));");

			var p = utility.GetPatchInfo();
			var data = [
				{
					text: "%1 - %2".arg(qsTr("Patch")).arg(p["PATCH"]),
					bold: true,
					pixelSize: constant.fontXLarge,
					horizontalAlignment: Text.AlignHCenter,
				},
				{
					text: "Release - %1".arg(p["RELEASE"]),
					bold: true,
					pixelSize: constant.fontLarge,
					horizontalAlignment: Text.AlignHCenter,
				},
				{
					text: "  * " + qsTr("Internal player supports to set request headers for playing Bilibili video."),
				},
				{
					text: "  * " + qsTr("Fixed Acfun video part source ID is wrong."),
				},
				{
					text: "  * " + qsTr("Fixed 'My post' and 'User post' page, 'My post' page supports to get thread only."),
				},
				{
					text: "  * " + qsTr("Get user name when user login with wap passport."),
				},

				{
					text: qsTr("Email") + ": <a href=\"utility.openURLDefault('%1');\">%2</a>".arg("mailto:" + p["EMAIL"]).arg(p["DEV"]),
					pixelSize: constant.fontLarge,
				},
				{
					text: qsTr("Source") + ": <a href=\"utility.openURLDefault('%1');\">Github</a>".arg(p["GITHUB"]),
					pixelSize: constant.fontLarge,
				},
				{
					text: qsTr("Download") + ": 1, <a href=\"utility.openURLDefault('%1');\">Openrepos</a>".arg(p["OPENREPOS"])
					+ "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2, <a href=\"utility.openURLDefault('%1');\">BaiduPan: %2</a>".arg(p["PAN"].split(" ")[0]).arg(p["PAN"].split(" ")[1]),
					pixelSize: constant.fontLarge,
				},
			];
			var f = qsTr("About author") + ": " + _GetAuthor()["B"] + "&nbsp;-&nbsp;"
			+ "<a href=\"close(); signalCenter.viewProfile('%1');\">%2</a>".arg(_GetAuthor()["A"]).arg(qsTr("Her profile"))
			+ "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"close(); signalCenter.enterForum('%1');\">%2</a>".arg(_GetAuthor()["B"]).arg(qsTr("Her tieba"))
			+ "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"close(); signalCenter._FollowHer('%1');\">%2</a>".arg(_GetAuthor()["A"]).arg(qsTr("Follow her"));
			_OpenTextDialog(qsTr("Update"), data, f);
		}


    function _PushWapLoginPage(forceLogin, username, userpwd){
        if(pageStack.currentPage.objectName !== "WapLoginPage"){
            var prop = { forceLogin: forceLogin || false }
						if(username)
						{
							prop.username = username;
							prop.userpwd = userpwd;
						}
            pageStack.push(Qt.resolvedUrl("WapLoginPage.qml"), prop, !tbsettings.wapLoginDirectly);
        }
    }

		function _FollowHer(uid)
		{
        var prop = { uid: uid };
				var p = pageStack.currentPage;
        p.loading = true;
        var f = function(err){ p.loading = false; signalCenter.showMessage(err); }
				var s = function(obj){ 
					var has_concerned = obj.has_concerned;
					if(has_concerned == "1")
					{
						p.loading = false; 
						signalCenter.showMessage(qsTr("You have been her fans."));
					}
					else
					{
						var prop2 = { portrait: obj.portrait, isFollow: true };
						Script.followUser(prop2, function(){ p.loading = false; signalCenter.showMessage(qsTr("Follow her success")); }, f);
					}
				}
        Script.getUserProfile(prop, s, f);
    }

		function _OpenPlayer(url, source, title)
		{
			var __RandIP = function(start, end)
			{
				var f = function(a, b){
					var i = Math.random() * (max - min) + min;
					return Math.floor(i).toString();
				};
				var min = typeof(start) === "number" ? start : 50;
				var max = typeof(end) === "number" ? end : 250;
				return "%1.%2.%3.%4".arg(f(min, max)).arg(f(min, max)).arg(f(min, max)).arg(f(min, max));
			};
			var Headers = {
				"bilibili": [
					{
						name: "User-Agent",
						value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36",
					},
					{
						name: "Referer",
						value: "https://www.bilibili.com",
					},
				],
				"youku": [
					/*
					 {
						 name: "Referer",
						 value: "http://v.youku.com",
					 },
					 */
					{
						name: "User-Agent",
						value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36",
					},
					{
						name: "HTTP_X_FORWARDED_FOR",
						value: __RandIP(),
					},
					{
						name: "Accept",
						value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
					},
					{
						name: "Accept-Language",
						value: "zh-CN,en-US;q=0.7,en;q=0.3",
					},
				],
			};
			var prop = { 
				videosource: url, 
				title: title || "",
			};
			if(source && Headers.hasOwnProperty(source))
			{
				prop.requestHeaders = Headers[source];
				prop.headersEnabled = true;
			}
			var p = pageStack.push(Qt.resolvedUrl("PlayerPage.qml"), prop, true);
			p._Load();
		}
	}
