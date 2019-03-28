var AcfunParser = function(){

	this.PATTERN = /^https?:\/\/www.acfun.(cn|com|tv)\/v\/a?c?(\d+)\/?/;

	var AC_DETAIL_FMT = "http://apipc.app.acfun.cn/v2/videos/%1";
	var AC_VIDEO_SID_FMT = "http://www.acfun.cn/video/getVideo.aspx?id=%1";
	var AC_PLAYER_FMT = "http://player.acfun.cn/flash_data?vid=%1&ct=%2&ev=%3&sign=%4&time=%5";

	var STREAMTYPES_PREFER_ARRAY = [
		"flvhd",
		"mp4hd",
		"mp4hd2",
		"mp4hd3",
	];

	var accept_index = -1;

	function CheckV2Error(obj)
	{
		if(obj.hasOwnProperty("errorid"))
		{
			if(obj.errorid !== 0)
				return AcfunParser.prototype.ResponseError(obj.errorid, obj.errordesc);
		}
		return false;
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

	// AJAX
	function GetJSONP(url, success, fail, data)
	{
		if(AcfunParser.prototype.NL_DBG)
			console.log(url);

		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function() {
			if (xhr.readyState == XMLHttpRequest.DONE) {
				if(AcfunParser.prototype.NL_DBG)
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

	// base64.decode
	function na(a) {
		if (!a) return "";
		var a = a.toString(),
			c, b, f, i, e, h = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1];
		i = a.length;
		f = 0;
		for (e = ""; f < i;) {
			do c = h[a.charCodeAt(f++) & 255]; while (f < i && -1 == c);
			if (-1 == c) break;
			do b = h[a.charCodeAt(f++) & 255]; while (f < i && -1 == b);
			if (-1 == b) break;
			e += String.fromCharCode(c << 2 | (b & 48) >> 4);
			do {
				c = a.charCodeAt(f++) & 255;
				if (61 == c) return e;
				c = h[c]
			} while (f < i && -1 == c);
			if (-1 == c) break;
			e += String.fromCharCode((b & 15) << 4 | (c & 60) >> 2);
			do {
				b = a.charCodeAt(f++) & 255;
				if (61 == b) return e;
				b = h[b]
			} while (f < i && -1 == b);
			if (-1 == b) break;
			e += String.fromCharCode((c &
						3) << 6 | b)
		}
		return e
	}

	// rc4
	function E(a, c) {
		for (var b = [], f = 0, i, e = "", h = 0; 256 > h; h++) b[h] = h;
		for (h = 0; 256 > h; h++) f = (f + b[h] + a.charCodeAt(h % a.length)) % 256, i = b[h], b[h] = b[f], b[f] = i;
		for (var q = f = h = 0; q < c.length; q++) h = (h + 1) % 256, f = (f + b[h]) % 256, i = b[h], b[h] = b[f], b[f] = i, e += String.fromCharCode(c.charCodeAt(q) ^ b[(b[h] + b[f]) % 256]);
		return e
	}

	function GetCidList(obj)
	{
		var arr = [];
		for(var i in obj.videos)
		{
			var e = obj.videos[i];
			arr.push({
				sourceId: (e.videoId || e.sourceId).toString(),
				title: e.title,
			});
		}
		return arr;
	}

	// Main get video streamtypes function
	this.GetVideoStreamtypes = function(avid, success, fail)
	{
		var aid_url = AC_DETAIL_FMT.arg(avid);

		var ajax_final_func = function(text, d)
		{
			var json = JSON.parse(text);
			var data = json.data;
			var b64_d_data = /*base64_decode*/na(data);
			var rc4_d_data = /*rc4*/E("8bdc7e1a", b64_d_data);
			var youku_json = JSON.parse(rc4_d_data);

			var r = {
				json: youku_json,
				data: d,
			}
			success(r);
		};
		var ajax_suc_func = function(text, data){
			var obj = JSON.parse(text),
			if(obj.sourceType !== "zhuzhan")
				fail(AcfunParser.prototype.ResponseError("Content source is not from zhuzhan", data.index));
			else
			{
				var sourceId = obj.sourceId.toString();
				var sign = obj.encode.toString();
				var contentId = obj.contentId.toString();
				var streams_url = AC_PLAYER_FMT.arg(sourceId).arg(85).arg(3).arg(sign).arg(Date.now().toString()) + "&__Referer=" + contentId;
				GetJSONP(streams_url, ajax_final_func, ajax_fail_func, data);
			}
		};
		var ajax_fail_func = function(code, text)
		{
			var msg = AcfunParser.prototype.ResponseError(code, text);
			fail(msg);
		};
		var get_cid_func = function(text){
			var json = JSON.parse(text);
			var r = CheckV2Error(json);
			if(r)
				fail(r);
			else
			{
				var pages = GetCidList(json.vdata);
				for(var i in pages)
				{
					if(accept_index !== -1 && i != accept_index) continue;
					var c = pages[i];
					if(!c.sourceId) continue;
					var part_url = AC_VIDEO_SID_FMT.arg(c.sourceId);
					var data = {
						index: i,
						title: c.title
					};
					GetJSONP(part_url, ajax_suc_func, ajax_fail_func, data);
					if(accept_index !== -1) break;
				}
			}
		};
		GetJSONP(aid_url, get_cid_func, ajax_fail_func);
	}

	// Make streamtypes model
	this.MakeStreamtypesModel = function(vid, model)
	{
		var make_model_func = function(obj){
			var d = obj.data;
			var stream = obj.json.stream;
			var stmp = [];
			stream.forEach(function(element){
				stmp.push(element.stream_type);
			});
			var type = GetPreferStreamtype(stmp);
			for(var i in stream)
			{
				var element = stream[i];
				if(type === element.stream_type)
				{
					var arr = [];
					if(Array.isArray(element.segs)){
						for(var i = 0; i < element.segs.length; i++){
							var url = element.segs[i].url;
							arr.push({
								title: d.index, 
								name: url ? i : "" + i + "*",
								url: url,
								value: i,
								duration: element.segs[i].total_milliseconds_video,
								size: element.segs[i].size,
							});
						}
					}
					var item = {
						name: d.title,
						index: parseInt(d.index),
						size: element.size,
						duration: element.milliseconds_video || element.duration * 1000,
						part: arr
					};
					model.append(item);
					break;
				}
			}
		};

		this.GetVideoStreamtypes(vid, make_model_func, AcfunParser.prototype.ShowStatusText);
	}

	this.Fetch = function(videoId, t, p) { // t is content index, not stream type.
		var type = t ? parseInt(t) : 0;
		accept_index = type;
		var part = typeof(p) === "number" ? p : 0;
		var get_streamtypes_func = function(obj){
			var d = obj.data;
			var stream = obj.json.stream;
				var stmp = [];
				stream.forEach(function(element){
					stmp.push(element.stream_type);
				});
			var st = GetPreferStreamtype(stmp);
			for(var s in stream)
			{
				if(stream[s].stream_type === st)
				{
					var url = stream[s].segs[part].url;
					if (url) {
						AcfunParser.prototype.Play(url);
						console.log("url -> " + url);
					} else {
						AcfunParser.prototype.ShowStatusText("Not found!");
					}
					break;
				}
			}
		}; // get_streamtypes_func end
		this.GetVideoStreamtypes(videoId, get_streamtypes_func, AcfunParser.prototype.ShowStatusText);
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

AcfunParser.prototype = new VideoParser();
AcfunParser.prototype.constructor = AcfunParser;
AcfunParser.prototype.source = "acfun";
