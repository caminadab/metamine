#!/usr/bin/luajit
package.path = package.path .. ";../?.lua"
require 'exp'
require 'lib'

require 'getopt'
require 'lisp'
require 'compile'

require 'rapport'
require 'typify'
require 'do'

require 'build.gen.js'
require 'build.gen.lua'
require 'build.gen.asm'

require 'build.codegen'
require 'build.assembleer'
require 'build.link'

opt,sources = getopt({...}, "o")

-- currently all source is concatenatd
for i,source in pairs(sources) do
	if source:sub(-5) ~= '.code' then
		sources[i] = source .. '.code'
	end
end

if #sources == 0 then
	print('no input files')
end

if opt.h or opt.help or #sources == 0 then
	print(
[[usage: mm [OPTIES...] [BESTANDEN...]
Compiles metamine code to an application.
Opties:
    -h, --help        print this help
    -v, --verbose     verbose output
    -g, --debug       generate debug information
    -d, --do          execute output
    -u, --uitvoer=UIT	output file

    -i      					generate intermediary code
    -n, --naakt       compile without library
    -j,	--javascript	compile to javascript
    -x,	--demo				compile to javascript applet
		
    -O								DON'T optimise output
    -D								profile compilation steps

    -S                generate assembly-code
    -R                generate extended rapport

    -B                print parsed syntax
		-R                print back-end tree
    -G                print info graph
    -K                print solved equations

    -Q                print solve information
    -W                print solve value
    -D                print solved defunc

    -T                print types
    -Y                print type graph

    -I                print intermediary code
    -L                print every instruction during exectution

    -A                print assembly code
    -H                print linker info
    -M                print mem allocation info
]])
	return
end

if not opt.n then
	sources[#sources+1] = 'lib/std.code'
else
	sources[#sources+1] = 'lib/n.code'
end

if opt.n then
	opt.u = true
end

if opt.d or opt.do0 then
	do0 = true
end
if opt.v or opt.verboos then
	verboos = true
end
if opt.javascript then opt.j = true end

if opt.R then verbozeRapport = true end
if opt.S then verbozeSyntax = true end
if opt.D then verbozeDeductie = true end
if opt.K then verbozeKennis = true end
if opt.W then verbozeOplos = true end
if opt.D then verbozeDefunc = true end
if opt.G then verbozeKennisgraaf = true end
if opt.W then verbozeWaarde = true end
if opt.C then verbozeControle = true end
if opt.I then verbozeIntermediair = true end
if opt.J then verbozeKijkgat = true end
if opt.A then verbozeAsm = true end
if opt.H then verbozeLinker = true end
if opt.M then verbozeOpslag = true end
if opt.B then verbozeBroncode = true end

if opt.T then verbozeTypes = true end
if opt.Y then verbozeTypegraaf = true end
if opt.i or opt.n then opt.veilig = true end

if opt.g or opt.debug or opt.ontkever then
	opt.g = true
	ontkever = true
	isdebug = true
end

local code = table.concat(map(sources, lees), '\n')

if verbozeBroncode then
	print('=== BRONCODE ===')
	print(code)
	print()
end

if verbozeSyntax then
	print('=== SYNTAX ===')
	local asb = parse(code)
	print(deparse(asb))
	print()
end

local app,fouten = compile(code, isdebug)
assert(app or #fouten > 0)

-- foutjuhhs
if #fouten > 0 then
	for i,fout in ipairs(fouten) do
		print(fout2ansi(fout))
	end
end
if not app then
	return
end

if verbozeControle then
	print('=== CONTROLEGRAAF ===')
	print(app)
	print()
end

if verbozeIntermediair then
	print('=== INTERMEDIAIRE CODE ===')
	for i, stat in ipairs(app) do
		print(unlisp(stat))
	end
	print()
end

-- nieuwe lage JS
if opt.j then
	uit = jsgen(app)
	file('a.js', uit)
	if opt.u then
		print(uit)
	end
	if opt.d then
		os.execute('js a.js')
	end
	return
end


-- intermediate
if opt.i or opt.im then
	-- doe
	if opt.d then
		if opt.L then
			print('=== START ===')
		end
		local main = doe(app)
		if opt.n then
			print(lenc(main))
			return
		end
		local vars, uit
		local nop = function () end
		local res = main{{}, true, socket.gettime(), nop, 100, -1, false, false, nop, nop, false, false, false, false}
-- main = (in.vars, start, nu, setcontext, uit.breedte, toets.code, toets.begint, toets.eindigt, toets.begin, toets.eind, muis.beweegt, muis.beweegt.naar, muis.klik.begin, muis.klik.eind) → (uit.vars, uit)
		vars, uit = res[1], res[2]
		io.write(lenc(uit))

		while true do
			nu = socket.gettime()
			local res = main{vars, false, socket.gettime(), nop, 100, -1, false, false, nop, nop, false, false, false, false}
			vars, uit = res[1], res[2]
			io.write(ansi.wisregel, ansi.regelbegin)
			io.write(lenc(uit), ' ')
			io.flush()
			socket.sleep(1/60)
		end

		if opt.L then
			print()
		end

	-- print
	else
		for i,stat in ipairs(app) do
			print(unlisp(stat))
		end
	end
	return

-- lua
elseif opt.l or opt.lua then
	local lua = luagen(app)

	-- doe makkelijk
	if opt.d and opt.n then
		local socket = require 'socket'
		local main = load(lua)()
		while true do
			nu = socket.gettime()
			io.write(ansi.wisregel, ansi.regelbegin)
			io.write(lenc(main), ' ')
			io.flush()
			socket.sleep(1/60)
		end

	-- doe moeilijk
	elseif opt.d then
		local socket = require 'socket'
		local vars = {}
		local mainfunc,err = load(lua)
		if not mainfunc then
			error(err)
		end
		local main = mainfunc()

		local vars, uit = table.unpack(main{vars, true, socket.gettime()})

		while true do
			nu = socket.gettime()
			io.write(ansi.wisregel, ansi.regelbegin)
			vars, res = table.unpack(main {vars, false, socket.gettime() })
			io.write(lenc(res), ' ')
			io.flush()
			socket.sleep(1/60)
		end

	-- alleen printen
	else
		print(lua)
	end

-- native
else

	local asm = asmgen(app)
	if opt.A then
		print('=== ASSEMBLY CODE ===')
		print(asm)
	end
	local elf = link(assembleer(asm, 'a'), 'a')
	file('a.elf', elf)
	os.execute('chmod +x a.elf')
	if doemeteen then
		print('== START ==')
		os.execute('./a.elf')
	end

end
