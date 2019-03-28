import QtQuick 1.1
import QtWebKit 1.0 //import com.yeatse.tbclient 1.0
import com.nokia.meego 1.1
import "Component"
import "../js/main.js" as Script

MyPage {
	id: page;

	property bool forceLogin: false;
	property string __WapUrl: "wap.baidu.com/?uid";
	property bool __UsingToolbar: true;
	property bool __HasInit: false;

	property string username: "";
	property string userpwd: "";
	// property bool autosubmit: true;

	objectName: "WapLoginPage";

	title: qsTr("Login");

	tools: ToolBarLayout {
		ToolIcon {
			platformIconId: "toolbar-back";
			onClicked: forceLogin||pageStack.depth <= 1 ? Qt.quit() : pageStack.pop();
		}

		ToolIcon{
			platformIconId: "toolbar-tab-previous";
			enabled: __UsingToolbar;
			visible: enabled;
			onClicked:{
				webview.back.trigger();
			}
		}
		ToolIcon{
			platformIconId: "toolbar-tab-next";
			enabled: __UsingToolbar;
			visible: enabled;
			onClicked:{
				webview.forward.trigger();
			}
		}
		ToolIcon{
			platformIconId: webview.progress === 1.0 ? "toolbar-refresh" : "toolbar-stop";
			enabled: __UsingToolbar;
			visible: enabled;
			onClicked:{
				if(webview.progress === 1.0)
				{
					webview.reload.trigger();
				}
				else
				{
					webview.stop.trigger();
				}
			}
		}
	}

	function loadFinishedSlot()
	{
		var url = webview.url.toString();
		if(Script.Verena._Dbg & Script.NL_DBG_QML) console.log(url);
		if(url.indexOf(__WapUrl) !== -1)
		{
			login();
		}
		else if(url === Script.Verena._WapPassportUrl)
		{
			init();
		}
	}

	function init()
	{
		if(__HasInit) return;

		if(username !== "")
		{
			var script = "(function(){ var login_username_ele = document.getElementById('login-username'); if(!login_username_ele) { console.log('[ERROR]: Username input not found in web page!'); return; } else { login_username_ele.value = '%1'; }     var _pwd = '%2';     if(_pwd !== '') { var login_password_ele = document.getElementById('login-password'); if(!login_password_ele) { console.log('[ERROR]: Password input not found in web page!'); return; } else { login_password_ele.value = _pwd; }     if(false) { var login_formWrapper_ele = document.getElementById('login-formWrapper'); if(!login_formWrapper_ele) { console.log('[ERROR]: Form not found in web page!'); } else { login_formWrapper_ele.submit(); }}}})()".arg(username).arg(userpwd);
			webview.evaluateJavaScript(script);
			__HasInit = true;
		}
	}

	function login(){
		function s(){
			loading = false;
			signalCenter.showMessage(qsTr("Login success!"));
			if(tbsettings.wapLoginDirectly)
			{
				pageStack.pop();
			}
			else
			{
				pageStack.pop(undefined, true);
        if(pageStack.currentPage.objectName === "LoginPage") pageStack.pop();
			}
		}
		function f(err, obj){
			loading = false;
			signalCenter.showMessage(err);
		}
		_GetUserProfile_DOM(s, f);
	}

	function _GetUserProfile(_E, suc_func, fail_func)
	{
		var pf = function(s){
			var start = s.lastIndexOf("/");
			var end = s.lastIndexOf(".");
			return (start !== -1 && end !== -1) ? s.substring(start + 1, end) : s;
		};
		var f = function(err, obj){
			fail_func(err);
		};
		var s =function(data){
			var name = data.pass_info ? (data.pass_info.displayname || data.pass_info.un) : (data.user_bdname || data.nick);
			if(_E["name"] === "" || (_E["name"] !== name && name !== "")) _E["name"] = name;
			if(_E["id"] === "") _E["id"] = data.pass_info ? data.pass_info.uid : data.user_bdid;
			if(Script.Verena._Dbg & Script.NL_DBG_QML)
			{
				console.log("  * Get user profile with API");
				for(var k in _E) console.log(k, _E[k], typeof(_E[k]));
			}
			Script.WapLogin(_E, suc_func, fail_func);
		};
		Script.GetUserProfile(s, f);
	}

	function _GetUserProfile_DOM(suc_func, fail_func)
	{
		var cookies = utility.GetCookie(Script.Verena._WapPassportUrl);
		if(cookies && cookies["BDUSS"])
		{
			var script = "(function(){ var login_ele = document.getElementsByClassName('login')[0]; if(!login_ele) { console.log('[ERROR]: Username not found in web page!'); }     var head_icon_ele = document.getElementsByClassName('head-icon')[0]; if(!head_icon_ele) { console.log('[ERROR]: Portrait not found in web page!'); }      var commonBase_ele = document.getElementById('commonBase'); if(!commonBase_ele) { console.log('[ERROR]: UID not found in web page!');}     var r = { name: login_ele ? login_ele.innerText : '', portrait: head_icon_ele ? head_icon_ele.src.split('/').pop() : '',  id: commonBase_ele ? commonBase_ele.getAttribute('data-pid').split('_')[0] : '' };     return r; })()";
			var _E = webview.evaluateJavaScript(script);

			if(_E)
			{
				_E["BDUSS"] = cookies["BDUSS"].toString();
				_E["passwd"] = userpwd;
				if(_E["name"] === "" && username !== "") _E["name"] = username;
				if(Script.Verena._Dbg & Script.NL_DBG_QML)
				{
					console.log("  * Get user profile with DOM");
					for(var k in _E) console.log(k, _E[k], typeof(_E[k]));
				}
				if(_E["name"] === "" || _E["id"] === "")
				{
					_GetUserProfile(_E, suc_func, fail_func);
				}
				else
				{
					Script.WapLogin(_E, suc_func, fail_func);
				}
			}
			else
			{
				fail_func("[%1]: %2 -> %3".arg("ERROR").arg(qsTr("JavaScript eval fail")).arg(script));
			}
		}
		else
		{
			fail_func("[%1]: %2!".arg("ERROR").arg(qsTr("BDUSS not found in cookies")));
		}
	}

	ViewHeader {
		id: viewHeader;
		title: page.title;
	}

	ProgressBar{
		id: progressbar;
		anchors{
			leftMargin: 40;
			rightMargin: 40;
			left: parent.left;
			right: parent.right;
			verticalCenter: viewHeader.bottom;
		}
		maximumValue: 1;
		minimumValue: 0;
		value: webview.progress;
		visible: value !== 1.0;
		z:2;
	}

	Flickable{
		id:flick;
		anchors { fill: parent; topMargin: viewHeader.height; }
		contentWidth: Math.max(width,webview.width);
		contentHeight: Math.max(height,webview.height);
		clip:true;
		WebView{
			id:webview;
			preferredWidth: flick.width;
			preferredHeight: flick.height;
			settings.autoLoadImages:tbsettings.wapLoginPageShowImage ? true : (url.toString().indexOf(Script.Verena._WapPassportUrl) !== -1 ? true : false);
			/*
			onLinkClicked:{
				//linkClicked(link);
			}
			*/
			onAlert:{
				showMessage(message);
			}
		 url: Script.Verena._WapPassportUrl;
			onZoomTo: doZoom(zoom,centerX,centerY)
			onContentsSizeChanged: {
				contentsScale = Math.min(1,flick.width / contentsSize.width)
			}
			onLoadFinished: 
			{
				loadFinishedSlot();
			}
			onLoadStarted: {
				flick.contentX = 0
				flick.contentY = 0
			}
			onDoubleClick: {
				return;
				if (!heuristicZoom(clickX,clickY,2.5)) {
					var zf = flick.width / contentsSize.width
					if (zf >= contentsScale)
					zf = 2.0*contentsScale // zoom in (else zooming out)
					doZoom(zf,clickX*zf,clickY*zf)
				}
			}
			function doZoom(zoom,centerX,centerY)
			{
				if (centerX) {
					var sc = zoom*contentsScale;
					scaleAnim.to = sc;
					flickVX.from = flick.contentX
					flickVX.to = Math.max(0,Math.min(centerX-flick.width/2,webview.width*sc-flick.width))
					finalX.value = flickVX.to
					flickVY.from = flick.contentY
					flickVY.to = Math.max(0,Math.min(centerY-flick.height/2,webview.height*sc-flick.height))
					finalY.value = flickVY.to
					quickZoom.start()
				}
			}
		}
		SequentialAnimation {
			id: quickZoom

			PropertyAction {
				target: webview
				property: "renderingEnabled"
				value: false
			}
			ParallelAnimation {
				NumberAnimation {
					id: scaleAnim
					target: webview
					property: "contentsScale"
					easing.type: Easing.Linear
					duration: 200
				}
				NumberAnimation {
					id: flickVX
					target: flick
					property: "contentX"
					easing.type: Easing.Linear
					duration: 200
					from: 0  
					to: 0  
				}
				NumberAnimation {
					id: flickVY
					target: flick
					property: "contentY"
					easing.type: Easing.Linear
					duration: 200
					from: 0  
					to: 0  
				}
			}
			PropertyAction {
				id: finalX
				target: flick
				property: "contentX"
				value: 0  
			}
			PropertyAction {
				id: finalY
				target: flick
				property: "contentY"
				value: 0 
			}
			PropertyAction {
				target: webview
				property: "renderingEnabled"
				value: true
			}
		}

	}
	ScrollDecorator{
		flickableItem:flick;
	}
}

