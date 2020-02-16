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

	local function asmnaam(focus)
		if focus <= 6 then
			return registers[focus]
		else
			return 'de stack ofzo?'
		end
	end

	local function ins2asm(ins)

		if op2asm[atoom(ins)] then
			local naama = asmnaam(focus-2)
			local naamb = asmnaam(focus-1)
			return op2asm[atoom(ins)]:gsub('$1',naama):gsub('$2',naamb)

		elseif fn(ins) == 'fn' then
			local res = 'fn'..atoom(arg(ins))..':'
			arg2focus[atoom(arg(ins))] = focus
			focus = focus + 1
			return res

		elseif fn(ins) == 'arg' then
			local argfocus = arg2focus[atoom(arg(ins))]
			string.format('mov %s, %s', asmnaam(focus), asmnaam(argfocus))
			focus = focus + 1
			return res

		elseif fn(ins) == 'lijst' then
			return 'lijst'..atoom(arg(ins))..':'

		elseif atoom(ins) == 'eind' then
			-- niets

		elseif tonumber(atoom(ins)) then
			local res =  string.format('mov %s, %s', asmnaam(focus), atoom(ins))
			focus = focus + 1
			return res

		else
			error(unlisp(ins))
		end
	end

	--require 'bouw.gen.asmops'

	local L = {}
	L[#L+1] = [[
	.intel_syntax noprefix
	.text
	.global	start

.section .text

start: ]]

	for i, ins in ipairs(im) do
		L[#L+1] = ins2asm(ins)
	end

	L[#L+1] = [[.section .rodata

.groet:
	.string "hoi.txt"
]]

	return table.concat(L,"\n")
end
