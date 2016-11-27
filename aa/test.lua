local f = io.open("test", "r")
print(f)
print(f:read(1))
os.execute("sleep 10000")
