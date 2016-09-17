
/+
string cachedir = "/var/cache/sas";
auto key = "71d77d4d2e3d993480c20e9629616500";

string tmdburi(string req) {
	return "https://api.themoviedb.org/3" ~ req ~ "?language=nl&api_key="~key;
}

string imageuri(string image) {
	return "https://image.tmdb.org/t/p/original" ~ image ~ "?api_key=" ~ key;
}

string cachefilmdir(string id) {
	return cachedir ~ "/video/" ~ id ~ "/";
}

string date() {
	auto today = Clock.currTime(UTC());
	auto date = cast (Date) today;
	auto fmt = date.toISOExtString();
	return fmt;
}


string datefilmpath() {
	string fmt = date();
	auto dir = cachedir ~ "/films/popular/" ~ fmt;
	return dir;
}


void cachevideo(string id) {
	writeln("metadata film #" ~ id);
	
	// info
	auto request = tmdburi("/movie/" ~ id);
	auto filmdir = cachefilmdir(id);
	mkdirRecurse(filmdir);
	
	// info
	auto json = get(request);
	std.file.write(filmdir ~ "info.json", json);
	auto info = parseJSON(json);
	
	// title
	std.file.write(filmdir ~ "title.txt", info["title"].str());
	std.file.write(filmdir ~ "overview.txt", info["overview"].str());
	
	// images
	auto posterpath = info["poster_path"].str();
	auto backdroppath = info["backdrop_path"].str();
	
	// download poster
	download(imageuri(posterpath), filmdir ~ "poster.jpg");
	download(imageuri(backdroppath), filmdir ~ "backdrop.jpg");
}

string[] cachepopular() {
	auto path = datefilmpath();
	
	auto popular = parseJSON(get(tmdburi("/movie/popular")));
	string[] ids;
	
	foreach (JSONValue result; popular["results"].array) {
		auto id = to!string(result["id"].integer());
		ids ~= id;
//		symlink("/mnt/satis/video/" ~ id, dir ~ id);
	}
	auto val = to!JSONValue(ids);
	auto json = toJSON(&val);
	std.file.write(path~".json", json);
	
	return ids;
		
}


class VideoDir : Node {
	string id;
	this(string id) { this.id = id; }
	override long size() { return 0; }
	override bool isDir() { return true; }
	override string[] children() { return ["overview.txt", "title.txt", "backdrop.jpg", "poster.jpg", "info.json"]; }
	override SasFile child(string file) {
		string cached = cachedir~"/video/"~id~"/"~file;
		if (!exists(dirName(cached)))
			cachevideo(id);
		return new RealFile(cached);
	}
	override long read(ubyte[] buf, ulong offset) { return 0; }
}
	

class PopularFile : SasFile {
	string json;
	string cached;
	
	this () {
		cached = cachedir~"/films/popular/"~date()~".json";
		if (!exists(cached))
			cachepopular();
		json = cast(string)std.file.read(cached);
	}
	
	long size() { return json.length; }
	long read(ubyte[] buf, ulong offset) {
		auto f = std.stdio.File(cached, "rb");
    	f.seek(offset);
    	auto slice = f.rawRead(buf);
    	return slice.length;
	}		
}	

class TorrentsDir : SasDir {
	Bittorrent bt;

	string[] children() {
		return ["13241fe16a2797b2a41b7822bde970274d6b687c","trackers.list"];
	}
	
	SasNode child(string hash) {
		if (hash == "trackers.list")
			return new RealFile(cachedir ~ "/torrent/trackers.list");
		else if (hash.length == 40)
			return new TorrentDir(bt, hash);
		else
			throw new FuseException(errno.ENOENT);
	}
	
	this (Bittorrent bt) {
		this.bt = bt;
	}
}+/
