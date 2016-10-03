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

interface Node {
	@property long size();
	@property bool isDir();
	@property string[] children();
	@property Node child(string path);
	@property long read(ubyte[] buf, ulong offset);
}

abstract class File : Node {
	override bool isDir() { return false; }
	override string[] children() { throw new FuseException(errno.ENOENT); }
	override Node child(string path) { throw new FuseException(errno.ENOENT); }
}

abstract class Dir : Node {
	override long size() { return 0; }
	override bool isDir() { return true; }
	override long read(ubyte[] buf, ulong offset) { return 0; }
}

class EmptyFile : File {
	long size() { return 0; }
	long read(ubyte[] buf, ulong offset) { return 0; }
}

class Real : Node {
	string path;
	
	this (string path) {
		this.path = path;
		writeln(path);
	}
	
	string[] children() {
		string[] files;
		foreach (DirEntry entry; dirEntries(path, SpanMode.shallow))
			files ~= baseName(entry.name);
		return files;
	}
	
	bool isDir() {
		return std.file.isDir(path);
	}
	
	long size() {
		return getSize(path);
	}
	
	long read(ubyte[] buf, ulong offset) {
		auto f = std.stdio.File(path, "rb");
    	f.seek(offset);
    	auto slice = f.rawRead(buf);
    	return slice.length;
	}	
	
	Node child(string file) {
		if (!isDir())
			throw new FuseException(errno.ENOENT);
			
		auto total = path ~ file;
			
		if (!exists(total))
			throw new FuseException(errno.ENOENT);
		else
			return new Real(total);
	}
}

/**
 * A simple directory listing using dfuse
 */
import std.concurrency;

class Filesystem : Operations {
	string cachedir = "/var/cache/satis";
	Node[string] virtual;
	Node[string] partial;
	bool[string] locked; // locked directories and files
	Tid[][string] waiting;
	
	void lock(string path) {
		locked[path] = true;
	}
	
	void unlock(string path) {
		if (path in waiting) {
			foreach (tid; waiting[path])
				send(tid, true);
			waiting.remove(path);
		}
		locked.remove(path);
	}
	
	bool islocked(string path) {
	   	// find final file
	   	auto els = array(pathSplitter(path));
	   	auto total = "";
		
		for (int i = 0; i < els.length; i++) {
			if (locked[total])
				return true;
			total ~= "/" ~ els[i];
		}
		return false;
	}
	
	// wait for file to get unlocked
	void wait(string path) {
		if (path !in waiting)
			waiting[path] = [];
		waiting[path] ~= thisTid;
		
		// now wait...
		receiveOnly!bool();
	}
	
	Node find(string path) {
    	writeln(path);
		try {
			// directory or file can be locked
			if (islocked(path))
				wait(path);
				
			// virtual files (partial, requestables, network objects)
			if (path in virtual)
				return virtual[path];
			
			// complete cached files
			if (exists(cachedir ~ path))
				return new Real(cachedir ~ path);
					
			throw new FuseException(errno.ENOENT);
		} catch (Exception e) {
			throw new FuseException(errno.ENOENT);
		}
    }
	
    override void getattr(const(char)[] path, ref stat_t s)
    {
    	writeln(path);
    	auto file = find(path.idup);
    		
    	s.st_size = file.size();
    	if (file.isDir())
    		s.st_mode = S_IFDIR;
    	else
    		s.st_mode = S_IFREG;
    }
    
    override bool access(const(char)[] path, int mode) {
    	writeln(path);
    	return true;
    }

    override string[] readdir(const(char)[] path)
    {
    	writeln(path);
    	auto file = find(path.idup);
    	
    	if (!file.isDir)
        	throw new FuseException(errno.ENOENT);
        	
        auto files = [".", ".."];
        files ~= file.children;
		return files;
    }
    
    ulong read(const(char)[] path, ubyte[] buf, ulong offset) {
    	writeln(path);
    	auto file = find(path.idup);
    	return file.read(buf, offset);
    }
}

void mount(string dir)
{    
	auto fs = new Filesystem();
	//fs.add("films", films);
	
    // yes foreground, yes threading
    auto fuse = new Fuse("SATIS", true, false);
    fuse.mount(fs, dir, []);
}
