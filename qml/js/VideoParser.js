var VideoParser = function()
{
	this.NL_DBG = 0;
	this.source = "";
	this.PATTERN = "";

	this.GetVideoStreamtypes = function(videoId, success, fail) { }
	this.MakeStreamtypesModel = function(vid, model) { }
	this.Fetch = function(videoId, t, p) { }
	this.Start = function(vid, type, part){
		this.Fetch(vid, type, part);
	}
	this.GetVideoIdFromUrl = function(url) {
		return false;
	}
	this.Query = function(url) {
		var videoId = this.GetVideoIdFromUrl(url);
		if (!videoId) {
			this.ShowStatusText("Invalid url!");
			return;
		}
		this.Fetch(videoId);
	}
	this.Play = function(videoUrl) {
		PlayVideo(videoUrl, this.source);
	}
	this.ShowStatusText = function(text) {
		signalCenter.showMessage(text);
	}
};

Qt.include("AcfunParser.js");
Qt.include("YoukuParser_new.js");
Qt.include("BilibiliParser.js");

function InstanceParser(source)
{
	var parser = null;
	switch(source)
	{
		case "youku":
			parser = new Youku2Parser();
			break;
		case "bilibili":
			parser = new BilibiliParser();
			break;
		case "acfun":
			parser = new AcfunParser();
			break;
		default:
			break;
	}
	return parser;
}

function GetStreamtypesById(source, vid, model)
{
	var parser = null;

	parser = InstanceParser(source);
	if(parser)
	{
		parser.MakeStreamtypesModel(vid, model);
		return true;
	}
	else
	{
		signalCenter.showMessage("[%1]: %2 -> %3".arg("ERROR").arg(qsTr("Source is not supported")).arg(source));
		return false;
	}
}

function GetUrlHost(url)
{
	var start = url.indexOf("://");
	var s = start !== -1 ? url.substr(start + 3) : url;
	var end = s.indexOf("/");
	return end !== -1 ? s.substring(0, end) : s;
}

function GetStreamtypes(url, model)
{
	var source = "";
	var parser = null;

	var host = GetUrlHost(url);
	//console.log(host);

	if(host.indexOf("youku") !== -1)
		source = "youku";
	else if(host.indexOf("bilibili") !== -1)
		source = "bilibili";
	else if(host.indexOf("acfun") !== -1)
		source = "acfun";
	
	parser = InstanceParser(source);
	if(parser)
	{
		var vid = parser.GetVideoIdFromUrl(url);
		if(vid)
		{
			parser.MakeStreamtypesModel(vid, model);
			var r = {
				id: vid,
				source: source,
			};
			return r;
		}
		else
		{
			signalCenter.showMessage("[%1]: %2 -> %3 %4".arg("ERROR").arg(qsTr("Url is invalid")).arg(source).arg(url));
			return false;
		}
	}
	else
	{
		signalCenter.showMessage("[%1]: %2 -> %3".arg("ERROR").arg(qsTr("Url is not supported")).arg(url));
		return false;
	}
}

function PlayVideo(videoUrl, source) {
	var UsingInternalPlayerSources = [
		"bilibili"
	];
	if(source && UsingInternalPlayerSources.indexOf(source) >= 0)
		signalCenter._OpenPlayer(videoUrl);
	else
		utility.launchPlayer(videoUrl);
}

function ParseVideo(source, vid, type, part)
{
	var parser = null;

	parser = InstanceParser(source);
	if(parser)
	{
		parser.Start(vid, type, part);
		return true;
	}
	else
	{
		signalCenter.showMessage("[%1]: %2 -> %3".arg("ERROR").arg(qsTr("Source is not supported")).arg(source));
		return false;
	}
}

