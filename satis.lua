srv = server(10101)
cli = client('127.0.0.1:10101')
cli.output = 'hoi'

i = srv.clients.input