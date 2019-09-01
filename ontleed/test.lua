require 'ontleed'

function unlisp(x)
	local t = {}
	local function U(y)
		if y.v then
			t[#t+1] = y.v
			return
		end
		t[#t+1] = y.f.v
		t[#t+1] = '('
		for i,v in ipairs(y) do
			U(v)
			t[#t+1] = ' '
		end
		t[#t] = ')'
	end
	U(x)
	return table.concat(t)
end

function file(name, data)
	if not data then
		local f = io.open(name, 'r')
		if not f then return false, 'bestand niet gevonden: '..name  end --error('file-not-found ' .. name) end
		data = f:read("*a")
		f:close()
		return data
	else
		local f = io.open(name, 'w')
		assert(f, 'onopenbaar: '..name)
		f:write(data)
		f:close()
	end
end

local a = "als a dan b eind"
assert(unlisp(ontleed(a)) == '⋀(⇒(a b))', unlisp(ontleed(a)))


local tests = file('TESTS')
for code in tests:gmatch('(.-)\n\n') do
	local taal,moet = code:match('(.*)\n([^n]-)$')
	if taal and moet then
	print(taal, moet)
	local lisp = unlisp(ontleed(taal))
	assert(lisp == moet, string.format('ontleed("%s") moet %s zijn maar is %s', taal, moet, lisp))
end
end



local tests = {
	{"als ja dan 1 anders 0", "=>(ja 1 0)"},
	{"als ja dan\na = 2\neind", "=>(ja EN(=(a 2)))"},
	{"als ja dan\na = 2\nanders\na = 3\neind", "=>(ja EN(=(a 2)) EN(=(a 3)))"},

	-- idk
	{"a = \"♕\"", "=(a [](9813))"},
	{"wit.", ".(wit)"},
	--TODO{"a = [\n]", "=(a []())"},
	{"a = [\n\tb\n]", "=(a [](b))"},
	{"a = [\n\tb\n\tc\n]", "=(a [](b c))"},

	{"sin(a) * b", "(* (sin a) b)"},

	-- functies!
	{"sin a", "(sin a)"},
	{"sin[tau]", "(sin tau)"},
	{"sin[3*4]", "(sin (* 3 4))"},
	{"sin(a) * b", "(* (sin a) b)"},
	{"sin(a,b)", "(sin (, a b))"},
	{"sin a * 3", "(* (sin a) 3)"},

	-- unaire opn
	{"-a", "(- a)"},
	{"a * -b", "(* a (- b))"},
	{"a + - -b", "(+ a (- (- b)))"},
	{"a * (-b)", "(* a (- b))"},
	{"((-b))", "(- b)"},
	{"-a - b", "(- (- a) b)"},
	{"a - -b", "(- a (- b))"},
	{"-a - b", "(- (- a) b)"},
	{"- #a", "(- (# a))"},

	-- zelfde level
	{"a + b", "(+ a b)"},
	{"a + b + c", "(+ (+ a b) c)"},
	{"a + b - c", "(- (+ a b) c)"},
	{"a + b + c - d - e - f", "(- (- (- (+ (+ a b) c) d) e) f)"},

	-- moeilijker
	{"a + b*3^i", "(+ a (* b (^ 3 i)))"},
	{"a + b^i", "(+ a (^ b i))"},
	{"a^2 + b^2 + c^2 + d^2", "(+ (+ (+ (^ a 2) (^ b 2)) (^ c 2)) (^ d 2))"},
	{"a * b ^ c + d", "(+ (* a (^ b c)) d)"},
	{"a*b+c^d/e^f", "(+ (* a b) (/ (^ c d) (^ e f)))"},
	{"a+b^c/d", "(+ a (/ (^ b c) d))"},
	{"a*b+c^d/e^f - 8", "(- (+ (* a b) (/ (^ c d) (^ e f))) 8)"},
	{"a=b+c", "(= a (+ b c))"},
	{"((a + b))", "(+ a b)"},
	{"(((a + b)))", "(+ a b)"},

	{"a + b * c", "(+ a (* b c))"},
	{"a * b + c", "(+ (* a b) c)"},
	{"(a + b) * c", "(* (+ a b) c)"},

	{"a+b*c", "(+ a (* b c))"},
	{"(a+b)*c", "(* (+ a b) c)"},
	{"(a + b) * c", "(* (+ a b) c)"},
	{"(a + b) * c / (d - e)", "(/ (* (+ a b) c) (- d e))"},
	{"((((a))))", "a"},
	{"a", "a"},

	-- regels
	{"a = 1\nb = 2", "(\n (= a 1) (= b 2))"},
	{"\na = 1\n\n\nb = 2\n\n", "(\n (= a 1) (= b 2))"},
	{"\na = 1\n\n\nb = 2\n\nc=3\n", "(\n (\n (= a 1) (= b 2)) (= c 3))"},

	{"a =\n\t3", "=(a co(3))"},
	{"a =\n\t0 → 1\n\t1 → 2", "=(a co(->(0 1) ->(1 2)))"},
	{"a =\n\t3\nb = 1", "EN(=(a co(3)) =(b 1))"},
	{"a =\n\t3\n\nb = 1", "EN(=(a co(3)) =(b 1))"},

	-- zieke blokken h3l
	{"priem als #delers = 2", "=>(=(#(delers) 2) priem)"},
	{"p: priem als\n\ta", "=>(a :(p priem))"},
	{"als a dan b", "=>(a b)"},
	{"als a dan\n\tb", "=>(a b)"},
	{"als\n\ta\ndan\n\tb", "=>(a b)"},
	--{"als\n\ta\n\tb\ndan\n\tc\n\td", "=>(/\\(a b) /\\(c d))"},
	--{"als a dan\n\tb = 10\nanders\n\tb = 20", "en(=>(a =(b 10)) =>(!(a) =(b 20)))"},
	--{"als a \n\tb", "=>(a b)"},

	-- integratie
	{"\n", "EN"},
	{"\n\n", "EN"},
	{"a = 10", "EN(=(a 10))"},

	-- fouten
	{"a ==", "a"},

	-- operatoren
	{"a = (+)", "=(a +)"},
	{"a = (*)", "=(a *)"},
	{"a = 3 (-) 2", "=(a -(3 2))"},
	{"a = (#) (-) (^)", "=(a -(# ^))"},

	-- regels
	{"a = 1\nb = 2", "/\\(=(a 1) =(b 2))"},
	{"a\nb\nc", "/\\(a b c)"},

	-- trivia
	{"a = 1", "=(a 1)"},
	{"a = b + 1", "=(a +(b 1))"},
	{"b = f(a)", "=(b f(a))"},
	{"b = f a", "=(b f(a))"},
	{"a = (p => b)", "=(a =>(p b))"},
	{"a : getal", ":(a getal)"},
	{"a = (b > c)", "=(a >(b c))"},
	{"a = (b of c)", "=(a of(b c))"},
	{"(a > 0) => b := 3", "=>(>(a 0) :=(b 3))"},
	{"a = 1 + #b", "=(a +(1 #(b)))"},
	{"a = 3\nb b b\nc = 0", "/\\(=(a 3) b(b b) =(c 0))"},

	-- funcs
	{"f = a -> a", "=(f ->(a a))"},
	{"f = a -> a + 1", "=(f ->(a +(a 1)))"},
	{"f = a,b -> c", "=(f ->(,(a b) c))"},
	{"f = int,int -> int", "=(f (-> (, int int) int))"},
	{"f = intd,intd -> intq", "=(f ->(,(intd intd) intq))"},
	{"f = int^2,int^2 -> int", "=(f ->(,(^(int 2) ^(int 2)) int))"},
	
	-- blok
	{
		"a = {\n\t0 -> 1\n\tbeeld dt -> a(net) + dt\n}",
		"((= a ({} (-> 0 1) (-> (beeld dt) (+ (a net) dt))))"
	},

	-- fouten
	{"a = (3 =)", "=(a fout)"},
	{"a = 3\nb b b b\nc = 0", "(/\\ (= a 3) fout (= c 0))"},

	-- procent
	{"a = 99% - 22%", "=(a -(%(99) %(22)))"},
	{"a = sin 10%", "=(a sin(%(10)))"},
	{"a = -10% ^ b", "=(a -(^( %(10) b))))"},

	-- lijst
	{"a = []", "=(a [])"},
	{"a = [0]", "=(a [](0))"},
	{"a = [1,2]", "=(a [](1 2))"},
	{"a = 100 * [a,a]", "=(a *(100 [](a a)))"},

	-- set
	{"a = {}", "=(a {})"},
	{"a = {1,2}", "=(a {}(1 2))"},
	{"a = {b => c}", "=(a {}(=>(b c)))"},
	--{"a = {b => c, d => e}", "(= a ({} (=> b c) (=> d e)))"},

	-- hist
	{"a = b'", "=(a '(b))"},
	{"a = (a' + 1)", "=(a +('(a) 1))"},
	{"a = sin 10'", "=(a sin('(10)))"},

	-- multi
	{"a = b | c + 2", "=(a |(b +(c 2)))"},

	-- tekst
	{"a = \"hoi\"", "=(a [](104 111 105))"},
	{"\"hoi\" = a", "=([](104 111 105) a)"},

	-- (a b)
	{"a = sin x", "=(a sin(x))"},
	{"a : sin x", ":(a sin(x))"},
	{"sin x : a", ":(sin(x) a)"},
	{"a 0 : getal", ":(a(0) getal)"},
	{"a 0 : getal en a 1 : getal", "en(:(a(0) getal) :(a(1) getal))"},
	{"a mod b c", "(fout)"},
	{"f = a b c d", "=(f fout)"},
	{"a mod (b c)", "mod(a b(c))"},

	-- func,
	
	{"f = [a,b] -> [b,a+b]", "=(f ->([](a b) [](b +(a b))))"},
	{"fib = n -> (f^n [1,1]) 0", "=(fib ->(n ^((f(n) [](1 1)) 1)))"},
	{"a^n (1)", "(^(a n) 1)"},

	-- unicode
	{"a²", "^(a 2)"},
	{"f = a ∪ b", "=(f unie(a b))"},
	{"a = ★ + ★", "=(a +(_ _))"},
	{"a = ★ · ★", "=(a *(_ _))"},
	{"a = b² - 3", "=(a -(^(b 2) 3))"},
	{"¬ a", "!(a)"},
	{"a!", "faculteit(a)"},
	{"a = ' '", "=(a 32)"},
	{"a = \"   \"", "=(a [](32 32 32))"},
	{"a = Σ b + c", "=(a som(+(b c)))"},
	{"a = ((0,1), 2)", "=(a ,(,(0 1) 2))"},

	-- commentaar
	{"a = 0\n;hoi", "=(a 0)"},
	{";hoi\na = 0", "=(a 0)"},
	{"a =;- hoi -; 0", "=(a 0)"},

	-- komma's
	{"a = b(2, 3)", "=(a b(2 3))"}

}

for i,test in ipairs(tests) do
end
