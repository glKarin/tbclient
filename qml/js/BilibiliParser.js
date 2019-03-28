var BilibiliParser = function()
{
	this.PATTERN = /^https?:\/\/www\.bilibili\.(cn|com|tv)\/video\/av(\d+)\/?/;

	var AVID_FMT = 'https://api.bilibili.com/x/web-interface/view?aid=%2';
	var API_FMT = 'https://api.bilibili.com/x/player/playurl?avid=%1&cid=%2&type=&otype=json&fnver=0&fnval=16&pn=%3';
	var REFERER = "https://www.bilibili.com";

	var STREAMTYPES_PREFER_ARRAY = {
			"_p80": "高清 1080P",
			"_p64": "高清 720P",
			"_p32": "清晰 480P",
			"_p16": "流畅 360P",
	};

	var sTitle = "";

	// AJAX
	function GetJSONP(url, success, fail, data)
	{
		if(BilibiliParser.prototype.NL_DBG)
			console.log(url);

		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function() {
			if (xhr.readyState == XMLHttpRequest.DONE) {
				if(BilibiliParser.prototype.NL_DBG)
					console.log(xhr.responseText);
				if (xhr.status == 200)
				{
					success(xhr.responseText, data);
				} else {
					fail(xhr.status);
				}
			}
		};

		xhr.open("GET", url);
		xhr.send();
	}

	function SortDashVideo(video)
	{
		var arr = [];
		for(var i in video)
		{
			var v = video[i];
			var q = parseInt(v.id);
			var has = false;
			for(var j in arr)
			{
				var a = arr[j];
				if(a.quality == q)
				{
					a.video.push(v);
					has = true;
					break;
				}
			}
			if(!has)
			{
				var a = {
					quality: q,
					video: [v],
				};
				arr.push(a);
			}
		}
		arr.sort(function(a, b){
			return a.quality - b.quality;
		});
		return arr;
	}

	function GetCidList(json){
		var pages = [];
		var data = json["data"];
		if(Array.isArray(data["pages"]) && data["pages"].length > 0)
			pages = data["pages"];
		else
			pages.push({'cid': data['cid']});

		sTitle = json['data'].title || "";
		return pages;
	};

	// Get preferred streamtype
	function GetPreferStreamtype(arr)
	{
		return Math.min.apply(null, arr);
	}

	// Make preferred streamtypes array
	function SortStreamtypes(arr)
	{
		var tmp = [];
		var m = Math.max.apply(null, arr);
		while(tmp.length < arr.length)
		{
			for(var i in arr)
			{
				var t = arr[i];
				if(tmp.indexOf(t) >= 0) continue;
				if(t < m) m = t;
			}
			tmp.push(m);
		}
		return tmp;
	}



	// Main get video streamtypes function
	this.GetVideoStreamtypes = function(avid, success, fail)
	{
		var aid_url = AVID_FMT.arg(avid);

		var ajax_suc_func = function(text, data){
			var json = {
				json: JSON.parse(text),
				data: data,
			};
			success(json);
		};
		var ajax_fail_func = function(code, text)
		{
			var msg = BilibiliParser.prototype.ResponseError(code, text);
			fail(msg);
		};
		var get_cid_func = function(text){
			var json = JSON.parse(text);
			if(json.code == 0)
			{
				var pages = GetCidList(json);
				for(var i in pages)
				{
					var cid = pages[i].cid.toString();
					if(!cid) continue;
					var part_url = API_FMT.arg(avid).arg(cid).arg(16);
					var data = {
						title: pages[i].part,
						index: i,
					};
					GetJSONP(part_url, ajax_suc_func, ajax_fail_func, data);
				}
			}
			else // {"code":62002,"message":"稿件不可见","ttl":1}
				ajax_fail_func(json.code, json.message);
		};
		GetJSONP(aid_url, get_cid_func, ajax_fail_func);
	}

	// Make streamtypes model
	this.MakeStreamtypesModel = function(vid, model)
	{
		var make_model_func = function(json){
			var obj = json.json;
			var d = json.data;
			var data = obj["data"];
			var total_size = 0;
			var arr = [];
			var title = d.title || sTitle;

			if (data && Array.isArray(data['durl']))
			{
				var durl = data["durl"];
				for(var i in durl)
				{
					var e = durl[i];
					arr.push({
						title: d.index || 0, 
						name: e.url ? i : "" + i + "*",
						url: e.url,
						value: i,
						duration: e.length,
						size: e.size,
					});
					total_size += e.size;
				}
				var item = {
					name: title,
					index: parseInt(d.index) || 0,
					size: total_size,
					duration: data.timelength,
					part: arr
				};
				model.append(item);
			} else { // dash
				var urls = SortDashVideo(data["dash"].video);
				var audio = data["dash"].audio;
				var first = urls[0];
				var video = first.video;
				for(var i in video)
				{
					var e = video[i];
					arr.push({
						title: d.index || 0, 
						name: e.baseUrl ? i : "" + i + "*",
						url: e.baseUrl, // + " " + audio[i].baseUrl;
						value: i,
						duration: 0,
						size: 0,
					});
					total_size += 0;
				}
				var item = {
					name: title,
					index: parseInt(d.index) || 0,
					size: total_size,
					duration: data.timelength,
					part: arr
				};
				model.append(item);
				//BilibiliParser.prototype.ShowStatusText(BilibiliParser.prototype.ResponseError("The 'durl' not found in response data"));
			}
		};

		this.GetVideoStreamtypes(vid, make_model_func, BilibiliParser.prototype.ShowStatusText);
	}

	this.Fetch = function(videoId, t, p) { // t is content index, not stream type.
		var type = t ? parseInt(t) : 0;
		var part = typeof(p) === "number" ? p : 0;
		var get_streamtypes_func = function(json){
			var obj = json.json;
			var data = obj["data"];

			if (data && Array.isArray(data['durl']))
			{
				var durl = data["durl"];
				if(type < durl.length)
				{
					var url = durl[type].url;

					if (url) {
						console.log("url -> " + url);
						BilibiliParser.prototype.Play(url);
					} else {
						BilibiliParser.prototype.ShowStatusText("Not found!");
					}
				}
				else
					BilibiliParser.prototype.ShowStatusText(BilibiliParser.prototype.ResponseError("Content index is out of range on this avid"));
			} else { // dash
				var urls = SortDashVideo(data["dash"].video);
				var audio = data["dash"].audio;
				var first = urls[0];
				var video = first.video;
				if(type < video.length)
				{
					var url = video[type].baseUrl; // + " " + audio[type].baseUrl;

					if (url) {
						console.log("url -> " + url);
						BilibiliParser.prototype.Play(url);
					} else {
						BilibiliParser.prototype.ShowStatusText("Not found!");
					}
				}
				else
					BilibiliParser.prototype.ShowStatusText(BilibiliParser.prototype.ResponseError("Content index is out of range on this avid"));
			}
		}; // get_streamtypes_func end

		this.GetVideoStreamtypes(videoId, get_streamtypes_func, BilibiliParser.prototype.ShowStatusText);
	}

	this.GetVideoIdFromUrl = function(url)
	{
		if (!url.match(this.PATTERN)) {
			return false;
		}
		var videoId = url.match(this.PATTERN)[2];
		return videoId;
	}

};

BilibiliParser.prototype = new VideoParser();
BilibiliParser.prototype.constructor = BilibiliParser;
BilibiliParser.prototype.source = "bilibili";
