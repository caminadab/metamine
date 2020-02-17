-- registers voor argumenten van syscalls
local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
-- registers voor argumenten van abicalls
local abiregs = { 'rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9'} -- r10 is static chain pointer in case of nested functions
-- registers op volgorde van bruikbaarheid (~6 general purpose registers)
--local registers = { 'r12', 'r13', 'r14', 'r15', 'r10', 'r9', 'r8', 'rcx', 'rdx', 'rsi', 'rdi', 'rax' }
local registers = { 'rax', 'rbx', 'rcx', 'rdx', 'r10', 'r9', 'r8', 'rcx', 'rdx', 'rsi', 'rdi', 'rax' }

local cmp = {
	['>'] = 'g',
	['>='] = 'ge',
	['='] = 'e',
	['!='] = 'ne',
	['<='] = 'le',
	['<'] = 'l',
}

local op2asm = {
	['+'] = 'add $1, $2',
	['-'] = 'sub $1, $2',
	['·'] = 'imul $1, $2',
	['/'] = 'div $1, $2',
}

function asmgen(im)
	focus = 1
	local arg2focus = {} -- int → int
	local L = {}

	local function asmnaam(focus)
		if focus <= 6 then
			return registers[focus]
		else
			return 'de stack ofzo?'
		end
	end

	local function ins2asm(ins)
		if fn(ins) == 'fn' then
			local res = 'fn'..atoom(arg(ins))..':'
			L[#L+1] = res
		elseif tonumber(atoom(ins)) then
			L[#L+1] = '  mov rax, '..atoom(ins)
			L[#L+1] = '  mov -8[rsp], rax'
			L[#L+1] = '  add rsp, 8'
		elseif atoom(ins) == 'eind' then
			L[#L+1] = '# eind'
		else
			L[#L+1] = '  mov rbx, -8[rsp]'
			L[#L+1] = '  mov rax, -16[rsp]'
			L[#L+1] = '  add rbx, rax'
		end
	end

	assert(fn(im[1]) == 'fn', 'main moet een functie zijn')

	L[#L+1] = [[
  .intel_syntax noprefix
  .text
  .global	start

.section .text

start: ]]


	for i = 2, #im-1 do
		local ins = im[i]
		ins2asm(ins)
	end

	L[#L+1] = [[
.section .rodata

.groet:
  .string "hoi.txt"
]]

	return table.concat(L,"\n")
end
