
function oplos(kennis)
	local graaf,map = infograaf(kennis)
	local stroom = sorteer(graaf)

	for punt in stroom:topologisch() do
	end
end
