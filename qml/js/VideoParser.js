var VideoParser = function()
{
	this.NL_DBG = 0;
	this.source = "";

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
		utility.launchPlayer(videoUrl);
	}
	this.ShowStatusText = function(text) {
		showMessage(text);
	}
};

Qt.include("YoukuParser_new.js");

function InstanceParser(source)
{
	var parser = null;
	switch(source)
	{
		case "youku":
			parser = new Youku2Parser();
			break;
		default:
			break;
	}
	return parser;
}

function GetStreamtypes(url, model)
{
	var source = "";
	var parser = null;

	if(url.indexOf("youku.com") !== -1)
		source = "youku";
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
			showMessage("[%1]: %2 -> %3 %4".arg("ERROR").arg(qsTr("Url is invalid")).arg(source).arg(url));
			return false;
		}
	}
	else
	{
		showMessage("[%1]: %2 -> %3".arg("ERROR").arg(qsTr("Source is not supported")).arg(url));
		return false;
	}
}

function PlayVideo(videoUrl) {
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
		showMessage("[%1]: %2 -> %3".arg("ERROR").arg(qsTr("Source is not supported")).arg(source));
		return false;
	}
}

