var Youku2Parser = function()
{
	this.PATTERN = /^https?:\/\/v.youku.com\/v_show\/id_([0-9a-zA-Z]+)(_.*)?\.html/;

	var CCODE = "0521";
	var CLIENT_IP = "192.168.1.1";
	var CKEY = "DIl58SLFxFNndSV1GFNnMQVYkx1PP5tKe1siZu/86PR1u/Wh1Ptd+WOZsHHWxysSfAOhNJpdVWsdVJNsfJ8Sxd8WKVvNfAS8aS8fAOzYARzPyPc3JvtnPHjTdKfESTdnuTW6ZPvk2pNDh4uFzotgdMEFkzQ5wZVXl2Pf1/Y6hLK0OnCNxBj3+nb0v72gZ6b0td+WOZsHHWxysSo/0y9D2K42SaB8Y/+aD2K42SaB8Y/+ahU+WOZsHcrxysooUeND";

	var ETAG_URL = "https://log.mmstat.com/eg.js";
	var GETVIDEO_URL_FMT = "https://ups.youku.com/ups/get.json?vid=%1&ccode=%2&client_ip=%3&utid=%4&client_ts=%5&ckey=%6"; // &password=%7

	var STREAMTYPES_PREFER_ARRAY = [
		"3gphd",
		"flv",
		"mp4",
			"mp4hd",
			"flvhd",
				// "3gp",
				"mp4hd2",
				"mp4hd2v2",
					"hd2",
					"hd2v2",
						"mp4hd3",
						"mp4hd3v2",
							"hd3",
							"hd3v2",
	];

	// AJAX
	function GetJSONP(url, success, fail)
	{
		if(Youku2Parser.prototype.NL_DBG)
			console.log(url);

		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function() {
			if (xhr.readyState == XMLHttpRequest.DONE) {
				if(Youku2Parser.prototype.NL_DBG)
					console.log(xhr.responseText);
				if (xhr.status == 200)
				{
					success(xhr.responseText, xhr.getAllResponseHeaders());
				} else {
					fail(xhr.status);
				}
			}
		};

		xhr.open("GET", url);
		xhr.send();
	}

	// Make preferred streamtypes array
	function SortStreamtypes(arr)
	{
		var tmp = [];
		for(var k in STREAMTYPES_PREFER_ARRAY)
		{
			var t = STREAMTYPES_PREFER_ARRAY[k];
			if(arr.indexOf(t) >= 0){
				tmp.push(t);
			}
		}
		return tmp;
	}

	// Get preferred streamtype
	function GetPreferStreamtype(arr)
	{
		for(var k in STREAMTYPES_PREFER_ARRAY)
		{
			var t = STREAMTYPES_PREFER_ARRAY[k];
			if(arr.indexOf(t) >= 0){
				return t;
			}
		}
		return null;
	}

	// Check response
	function CheckError(obj)
	{
		if(obj.data.hasOwnProperty("error"))
		{
			var error = obj.data.error;
			var m = error.note;
			if(error.hasOwnProperty("vid"))
				m += "(%1)".arg(error.vid);
			return Youku2Parser.prototype.ResponseError(error.code, m);
		}
		return false;
	}

	// Get utid
	function GetCna(json, header)
	{
		// find in response header
		var arr = header.split("\r\n");
		for(var i in arr)
		{
			var a = arr[i].split(": ");
			var etag = a[0].toLowerCase();
			if(etag === "etag")
			{
				var utid = a[1].split('"')[1];
				utid = encodeURI(utid);
				return utid;
			}
		}
		return false;
	}

	function RemakeCdnUrl(url_in)
	{
		if(!url_in)
			return "";
		var dispatcher_url = "vali.cp31.ott.cibntv.net";
		if(url_in.indexOf(dispatcher_url) != -1)
			return url_in;
		else if(url_in.indexOf("k.youku.com") != -1)
			return url_in;
		else
		{
			var parts = url_in.split("://", 2);
			var parts_2 = parts[1].split("/");
			parts_2[0] = dispatcher_url;
			var url_out_2 = parts_2.join("/");
			return parts[0] + "://" + url_out_2;
		}
	}

	function HandleVID(vid)
	{
		if(!vid)
			return vid;
		if(vid.length === 17 && vid.indexOf("==") === 15)
		{
			return vid.substring(0, 15);
		}
		return vid;
	}



	// Main get video streamtypes function
	this.GetVideoStreamtypes = function(videoId, success, fail)
	{
		//var url = "http://v.youku.com/player/getPlaylist/VideoIDS/" + videoId + "/Pf/4/ctype/12/ev/1?__";
		//var url = "http://play.youku.com/play/get.json?vid=" + videoId + "&ct=12";

		var ajax_fail_func = function(code, text)
		{
			var msg = Youku2Parser.prototype.ResponseError(code, text);
			fail(msg);
		};
		var ajax_suc_func = function(text, header){
			var json = JSON.parse(text);
			var r = CheckError(json);
			if(r)
				fail(r);
			else
				success(json);
		};

		var get_utid_func = function(json, header){
			var utid = GetCna(json, header);
			var ts = (new Date().getTime() / 1000).toString();
			var url = GETVIDEO_URL_FMT.arg(videoId).arg(CCODE).arg(CLIENT_IP).arg(utid).arg(ts).arg(encodeURI(CKEY));

			GetJSONP(url, ajax_suc_func, ajax_fail_func);
		};

		GetJSONP(ETAG_URL, get_utid_func, ajax_fail_func);
	}

	// Make streamtypes model
	this.MakeStreamtypesModel = function(vid, model)
	{
		var make_model_func = function(obj){
			if(obj.data){
				if(Array.isArray(obj.data.stream)){
					var stream = obj.data.stream;
					var stmp = [];
					stream.forEach(function(element){
						stmp.push(element.stream_type);
					});
					var pft = SortStreamtypes(stmp);
					stream.forEach(function(element, index){
						var type = element.stream_type;
						var arr = [];
						if(Array.isArray(element.segs)){
							for(var i = 0; i < element.segs.length; i++){
								var url = RemakeCdnUrl(element.segs[i].cdn_url);
								arr.push({
									title: type, 
									name: url ? i : "" + i + "*",
									url: url,
									value: i,
									duration: element.segs[i].total_milliseconds_video,
									size: element.segs[i].size,
								});
							}
						}
						var item = {
							name: type,
							index: pft.indexOf(type),
							size: element.size,
							duration: element.milliseconds_video,
							part: arr
						};
						model.append(item);
					});
				}
			}
		};

		this.GetVideoStreamtypes(vid, make_model_func, Youku2Parser.prototype.ShowStatusText);
	}

	this.Fetch = function(videoId, t, p) {
		var type = t ? t : "";
		var part = typeof(p) === "number" ? p : 0;
		var get_streamtypes_func = function(obj){
			var stream = obj.data.stream;
			if(type === "")
			{
				var stmp = [];
				stream.forEach(function(element){
					stmp.push(element.stream_type);
				});
				type = GetPreferStreamtype(stmp);
			}
			for(var s in stream)
			{
				if(stream[s].stream_type === type)
				{
					var url = stream[s].segs[part].cdn_url;
					if (url) {
						var link = RemakeCdnUrl(url);
						/*
							 var q = link.indexOf("?");
							 if(q !== -1)
							 link = link.substring(0, q);
							 */
						console.log("url -> " + link);
						Youku2Parser.prototype.Play(link);
					} else {
						Youku2Parser.prototype.ShowStatusText("Not found!");
					}
					break;
				}
			}
		}; // get_streamtypes_func end

		this.GetVideoStreamtypes(videoId, get_streamtypes_func, Youku2Parser.prototype.ShowStatusText);
	}

	this.GetVideoIdFromUrl = function(url)
	{
		if (!url.match(this.PATTERN)) {
			return false;
		}
		var videoId = url.match(this.PATTERN)[1];
		return videoId;
	}

};

Youku2Parser.prototype = new VideoParser();
Youku2Parser.prototype.constructor = Youku2Parser;
Youku2Parser.prototype.source = "youku";
