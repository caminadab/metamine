require 'combineer'

local function tag(naam,id,props,autoclose)
	if type(id) == 'table' then
		props = id
		id = nil
	end
	return function(inhoud)
		-- schrijffunctie
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

			if not autoclose then
				t[#t+1] = '</'
				t[#t+1] = naam
				t[#t+1] = '>'
			end
		end
	end
end

head = tag('head')
meta_charset = tag('meta',nil,{charset="utf-8"},true)
body = tag('body')
title = tag('title')
div = function (id,props)
	if id then return tag('div', id, props)()
	else return tag('div', props)() end
end
span = tag('span')
pre = tag('pre')
tabel = tag('table')
tr,th,td = tag'tr', tag'th', tag'td'
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

function graaf2js(graaf, id, layout, map)
	local layout = layout or 'cose'
	-- punten
	local d = {}
	for punt in spairs(graaf.punten) do
		d[#d+1] = "{ data: {id: "..string.format('%q', tostring(punt)).."}, classes: 'waarde' },"
	end

	-- pijlen
	for pijl in spairs(graaf.pijlen) do
		local haspseudo = not next(pijl.van) or next(pijl.van, next(pijl.van))
		local pseudo
		if haspseudo then
			-- pseudo punt
			pseudo = rid()
			local exp = '' --unparseInfix(map[pijl])
			d[#d+1] = "{ data: {id: " .. string.format('%q',pseudo) .. ", exp: 'ok'}, classes: 'hyper' },"
		else
			pseudo = next(pijl.van)
		end

		-- pijl (pseudo -> naar)
		d[#d+1] = [[
			{
				data: {
					id: ']]..rid()..[[',
					source: ]] .. string.format('%q', pseudo) .. [[,
					target: ]] .. string.format('%q', tostring(pijl.naar)) .. [[,
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
							source: ]] .. string.format('%q', van) .. [[,
							target: ]] .. string.format('%q', pseudo) .. [[,
						}
					},
				]]
			end
		end
	end
	local data = table.concat(d)

	-- alles
	return id..[[ = cytoscape({
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
							label: 'data(exp)',
							shape: 'none',
							'background-color': 'black',
							'font-size': '8px',
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

function stroom2html(stroom, naam)
	return graaf2html(stroom, naam, 'dagre')
end

-- vt: (code, kennisgraaf, infostroom)
function graaf2html(graaf, naam, type)
	local deel = tag('div', nil, {class='deel'})

	return html {
		head {
			meta_charset(),
			title(naam),
			css [[
				.deel {
					width: calc(100% - 50px);
					height: calc(100vh - 50px);
					border-style: solid;
					border-width: 4px;
					border-color: black;
					margin: 8px;
					display: inline-block;
					overflow: scroll;
				}

				pre { font-size: 20px; font-weight: bold; }
			]],
			jslib 'https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.2.16/cytoscape.min.js',
			jslib 'https://cdn.rawgit.com/cpettitt/dagre/v0.7.4/dist/dagre.min.js',
    	jslib 'https://cdn.rawgit.com/cytoscape/cytoscape.js-dagre/1.5.0/cytoscape-dagre.js',
			jslib 'http://code.jquery.com/jquery-2.0.0.min.js',
			jslib 'http://cdn.jsdelivr.net/qtip2/3.0.3/basic/jquery.qtip.min.js',
		},
		body {
			--deel { pre(vt.code) },
			--deel { pre(unlisp(feiten)) },
			--deel { pre(unlisp(dfeiten)) },
			--div('afh', {class='deel'}),
			--div('infostroom', {class='deel'}),
			--deel { typetabel },
			div('afh', {class='deel'}),
			js (graaf2js(graaf, 'afh', type, map)),
			--js (graaf2js(vt.infostroom, 'infostroom', 'dagre', map)),
			js [[
				infostroom.on('mouseover', 'node', function(event) {
					var node = event.cyTarget || [];
					$(this).each(function() {$(this).qtip({content:'hello'});});
					$.qtip({
					content: 'hello',
						show: {
							event: event.type,
							//ready: true
						},
						hide: {
							event: 'mouseout unfocus'
						}
					}, event);
				});
			]]
		}
	}
end
