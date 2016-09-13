import dfuse.fuse;
import std.net.curl;
import std.file;
import std.path;
import std.algorithm, std.conv, std.stdio;
import std.json;
import std.array;
import std.datetime;
import core.thread;
import http;
import bittorrent;
import bencode;

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

interface SasNode {
	@property long size();
	@property bool isDir();
	@property string[] children();
	@property SasNode child(string path);
	@property long read(ubyte[] buf, ulong offset);
}

abstract class SasFile : SasNode {
	override bool isDir() { return false; }
	override string[] children() { throw new FuseException(errno.ENOENT); }
	override SasNode child(string path) { throw new FuseException(errno.ENOENT); }
}

abstract class SasDir : SasNode {
	override long size() { return 0; }
	override bool isDir() { return true; }
	override long read(ubyte[] buf, ulong offset) { return 0; }
}

class StaticDir : SasDir {
	SasNode[string] childs;
	
	this (SasNode[string] children) {
		this.childs = children;
	}
	
	//override bool isDir() { return true; }
	string[] children() {
		string[] children = [];
		foreach (name,file; childs)
			children ~= name;
		return children;
	}
	SasNode child(string path) { return childs[path]; }
	
}

class VideosDir : SasNode {
	override long size() { return 0; }
	override bool isDir() { return true; }
	override string[] children() { return ["1", "2", "3", "4", "5"]; }
	override SasNode child(string id) { return new VideoDir(id); }
	override long read(ubyte[] buf, ulong offset) { return 0; }
}

class VideoDir : SasNode {
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

class RealFile : SasFile {
	string path;
	this (string path) { this.path = path; }
	long size() { return getSize(path); }
	long read(ubyte[] buf, ulong offset) {
		auto f = std.stdio.File(path, "rb");
    	f.seek(offset);
    	auto slice = f.rawRead(buf);
    	return slice.length;
	}		
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

class SymLink : SasNode {
	SasNode link;
	this (string path) {
		if (std.file.isDir(readLink(path)))
			link = new RealDir(path);
		else
			link = new RealFile(path);
	}
	string[] children() { return link.children(); }
	bool isDir() { return link.isDir(); }
	SasNode child(string file) { return link.child(file); }
	long size() { return link.size(); }
	long read(ubyte[] buf, ulong offset) {
		return link.read(buf, offset);
	}
}

class EmptyFile : SasFile {
	long size() { return 0; }
	long read(ubyte[] buf, ulong offset) { return 0; }
}

class RealDir : SasDir {
	string path;
	
	this (string path) { this.path = path; }
	
	string[] children() {
		string[] files;
		foreach (DirEntry entry; dirEntries(path, SpanMode.shallow))
			files ~= baseName(entry.name);
		return files;
	}
	
	SasNode child(string file) {
		auto total = path ~ file;
		if (!exists(total))
			throw new FuseException(errno.ENOENT);
		return new EmptyFile;
		//if (isSymlink(total))
		//	return new SymLink(total);
		//else if (std.file.isDir(total))
		//	return new RealDir(total);
		//else
		//	return new RealFile(total);i
	}
}

class TorrentDir : SasDir {
	string hash;
	Bittorrent bt;
	Torrent torrent;
	this (Bittorrent bt, string hash) {
		this.bt = bt;
		this.hash = hash;
		this.torrent = new Torrent(bt, hash);
	}
	string[] children() {
		return ["hoi", "hey"];
	}
	SasNode child(string path) {
		if (path == "hoi" || path == "hey")
			return new EmptyFile;
		else
			throw new FuseException(errno.ENOENT);
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
}
/**
 * A simple directory listing using dfuse
 */
class SasFS : Operations
{
	SasDir root;
	this (SasDir root) { this.root = root; }
	
	SasNode find(string path) {
		try {
	    	// find final file
	    	auto els = array(pathSplitter(path));
	    	
	    	SasNode file = root;
	    	for (int i = 1; i < els.length; i++)
	    		file = file.child(els[i]);
	    	return file;
	    } catch (Error e) {
	    	throw new FuseException(errno.ENOENT);
	    }
    }
	
    override void getattr(const(char)[] path, ref stat_t s)
    {
    	auto file = find(path.idup);
    		
    	s.st_size = file.size();
    	if (file.isDir())
    		s.st_mode = S_IFDIR;
    	else
    		s.st_mode = S_IFREG;
    }
    
    override bool access(const(char)[] path, int mode) {
    	return true;
    }

    override string[] readdir(const(char)[] path)
    {
    	auto file = find(path.idup);
    	
    	if (!file.isDir)
        	throw new FuseException(errno.ENOENT);
        	
        auto files = [".", ".."];
        files ~= file.children;
		return files;
    }
    
    ulong read(const(char)[] path, ubyte[] buf, ulong offset) {
    	auto file = find(path.idup);
    	return file.read(buf, offset);
    }
}

void mount(Bittorrent bt)
{
	auto root = new StaticDir([
//		"video": new VideosDir(),
		"torrent": new TorrentsDir(bt),
	]);
    /* foreground=true, threading=false */
    auto fs = new Fuse("SasFS", true, true);
    fs.mount(new SasFS(root), "/mnt/sas", []);
}
