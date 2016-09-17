import bittorrent;
import bencode;
import std.file, std.stdio;
import core.thread;
import fuse;

int main(string[] args)
{
	auto magnet = new Magnet("magnet:?xt=urn:btih:13241fe16a2797b2a41b7822bde970274d6b687c&dn=Mad+Max%3A+Fury+Road+%282015%29+1080p+BrRip+x264+-+YIFY&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969&tr=udp%3A%2F%2Fzer0day.ch%3A1337&tr=udp%3A%2F%2Fopen.demonii.com%3A1337&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969&tr=udp%3A%2F%2Fexodus.desync.com%3A6969");

	//auto bt = new Bittorrent;
	//auto file = cast(data) read("spiderman.torrent");
	//auto torrent = new Torrent(bt, decode(file));
	
	// dht, peers, torrents
	
	//bt.save();
	
	
	//writeln(torrent.infohash);
	
	//foreach (file2; torrent.metadata.files)
	//	writeln(file2);
	
	mount();
	
	return 0;
}













	
void lol() {
	//new Thread(&webserve).start();
	
	//auto root = new StaticDir(cast(SasNode[string])[
	//	"video": new VideosDir(),
	//	"films": new StaticDir([
	//		"popular.json": new PopularFile(),
	//	]),
	//	
	//]);
	

	// filesystem
    //auto fs = new Fuse("SatisFS", true, true);
    //fs.mount(new SasFS(root), "/mnt/satis", []);
}

