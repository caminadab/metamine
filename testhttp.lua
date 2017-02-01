local demo = client('127.0.0.1:'..PORT)
demo.output = enchant('GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n')
return demo
