/+

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
+/
