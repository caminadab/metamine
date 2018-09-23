require 'html'

function tag(naam,id,props)
	if type(id) == 'table' then
		props = id
		id = nil
	end
	return function(inhoud)
		return function(t)
			t[#t+1] = '<'
			t[#t+1] = naam
			if id then
				t[#t+1] = ' id="'
				t[#t+1] = id
				t[#t+1] = '"'
			end
			if props then
				for k,v in pairs(props) do
					t[#t+1] = ' '
					t[#t+1] = k
					t[#t+1] = '='
					t[#t+1] = string.format('%q', v)
				end
			end
			t[#t+1] = '>'

			if type(inhoud) == 'string' then
				t[#t+1] = inhoud
			elseif type(inhoud) == 'table' then
				for i,v in ipairs(inhoud) do
					v(t)
				end
			elseif not inhoud then
				-- niets
			else
				t[#t+1] = tostring(inhoud)
			end

			t[#t+1] = '</'
			t[#t+1] = naam
			t[#t+1] = '>'
		end
	end
end

head = tag('head')
body = tag('body')
title = tag('title')
div = function (id,props)
	if id then return tag('div', id, props)()
	else return tag('div', props)() end
end
span = tag('span')
pre = tag('pre')
h1 = tag('h1')
css = tag('style')
canvas = function (id)
	return tag('canvas', id)()
end
js = tag('script')
jslib = function(src)
	return tag('script', {src=src})()
end

function html(s)
	local t = {'<!DOCTYPE html>'}
	for i,v in ipairs(s) do
		v(t)
	end
	return table.concat(t)
end

function rid()
	return 'x'..math.random()
end

function graaf2js(graaf, id, layout)
	local layout = layout or 'cose'
	-- punten
	local d = {}
	for punt in spairs(graaf.punten) do
		d[#d+1] = "{ data: {id: '"..punt.."'}, classes: 'waarde' },"
	end

	-- pijlen
	for pijl in spairs(graaf.pijlen) do
		local haspseudo = not next(pijl.van) or next(pijl.van, next(pijl.van))
		local pseudo
		if haspseudo then
			-- pseudo punt
			pseudo = rid()
			d[#d+1] = "{ data: {id: '"..pseudo.."'}, classes: 'hyper' },"
		else
			pseudo = next(pijl.van)
		end

		-- pijl (pseudo -> naar)
		d[#d+1] = [[
			{
				data: {
					id: ']]..rid()..[[',
					source: ']] .. pseudo .. [[',
					target: ']] .. pijl.naar .. [[',
				}
			},
		]]

		if haspseudo then
			for van in spairs(pijl.van) do
				local id = 'x'..math.random()
				d[#d+1] = [[
					{
						data: {
							id: ']]..id..[[',
							source: ']] .. van .. [[',
							target: ']] .. pseudo .. [[',
						}
					},
				]]
			end
		end
	end
	local data = table.concat(d)

	-- alles
	return [[
		cytoscape({
			container: document.getElementById(']]..id..[['),
			style: [
				{
					selector: '.waarde',
					style: {
							shape: 'hexagon',
							'background-color': 'blue',
							label: 'data(id)'
					}
				},
				{
					selector: 'edge',
					style: {
						'curve-style': 'bezier',
						'target-arrow-shape': 'triangle',
					}
				},
				{
					selector: '.hyper',
					style: {
							shape: 'none',
							'background-color': 'black',
							label: '',
							width: '10px',
							height: '10px',
					}
				},
			],
			layout: {
				name: ']]..layout..[[',
				transform: function (node, pos) { return {x: pos.y, y: pos.x} },
			},
			elements: [
				]]..data..[[
			]
		});
	]]
end

require 'noem'
function rapport(code)
	local code = code
	local feiten = ontleed(code)
	local feiten = deduceer(feiten)
	local afh,map = berekenbaarheid(feiten)
	local infostroom = afh:sorteer({}, 'uit')

	local deel = tag('div', nil, {class='deel'})

	return html {
		head {
			title 'Rapport',
			css [[
				.deel {
					width: calc(100% - 50px);
					height: calc(100vh - 50px);
					border-style: solid;
					border-width: 4px;
					border-color: black;
					margin: 8px;
					display: inline-block;
				}

				pre { font-size: 20px; font-weight: bold; }
			]],
			jslib 'https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.2.16/cytoscape.min.js',
			jslib 'https://cdn.rawgit.com/cpettitt/dagre/v0.7.4/dist/dagre.min.js',
    	jslib 'https://cdn.rawgit.com/cytoscape/cytoscape.js-dagre/1.5.0/cytoscape-dagre.js',
		},
		body {
			deel { pre(code) },
			div('afh', {class='deel'}),
			div('infostroom', {class='deel'}),
			js (graaf2js(afh, 'afh')),
			js (graaf2js(infostroom, 'infostroom', 'dagre')),
		}
	}
end
