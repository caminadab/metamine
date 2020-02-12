require 'exp'

function jsgen(sfc)
	local focus = 1
	for i, ins in ipairs(sfc) do
		insgen(ins)
		varnaam(focus)
	end
end
