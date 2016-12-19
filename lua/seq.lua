
	
	-- set
	function cs.first:update()			
		-- assign
		if not self.ref and next(cs.val) then
			print("ASSIGN")
			self.ref = cs.val[next(cs.val)]
			triggers(self.ref, self)
		end
		
		-- unassign
		if self.ref and not next(cs.val) then
			print("unassign")
			self.ref = nil
			self.text = '<none>'
			self.val = nil
			-- untrigger
		end
		
		-- copy
		if self.ref then
			self.text = self.ref.text
			self.val = self.ref.val
		end
	end
	triggers(cs, cs.first)