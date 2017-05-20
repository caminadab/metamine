(and
	; IF SIMPLIFICATIONS
	(=> (if (not C) T E)	(if C E T) )
	(=> (if true X Y)		X )
	(=> (if false X Y)		Y )
	(=> (if X Y Y) 			Y )
	(=> (if X false true)	(not X) )
	(=> (if X true false)	X )
	(=> (if C (if C T A) E)	(if C T A) )
	(=> (if C C E)			(or C E) )
	(=> (if C T C)			(and C T) )

	; EASY MATH
	(=> (+ 0 X)			X )
	(=> (* 0 X)			0 )
	(=> (* 1 X)			X )
	(=> (- X 0)			X )
	(=> (- 0 X)			(-X) )
	(=> (- X X)			0 )
	(=> (/ X 1)			X )
	(=> (/ 0 X)			0 )
	(=> (/ X 0)			1e100 )
	(=> (/ X X)			1 )
	(=> (% X X)			0 )
	(=> (% X 0)			0 )
	(=> (% 0 X)			0 )
	(=> (* (- A) (- B))	(* A B) )
	(=> (max A A)		A )
	(=> (min A A)		A )

	; LOGIC  RULES
	(=> (or true X)		true )
	(=> (or false X)	X )
	(=> (or X X)		X )
	(=> (and true X)	X )
	(=> (and false X)	false )
	(=> (and X X)		X )
	(=> (and X (not X))	false )
	(=> (xor true X)	(not X) )
	(=> (xor false X)	X )
	(=> (xor X X)		false )
	(=> (not (xor X Y))	(xor X Y) )

	; POWER RULES
	(<=> (* (^ A X) (^ A Y))	(^ A (+ X Y)) ) ; a^x * a^y = a^(x+y)
	(<=> (/ (^ A X) (^ A Y))	(^ A (- X Y)) ) ; a^x / a^y = a^(x-y)
	(<=> (/ A (^ B C))				(* A (^ B (- C))) ) ; a / b^x = a * b^-x
	(<=> (sqrt A)							(^ A 0.5) ) ; sqrt(x) = x^0.5
	(<=> (= b (sqrt a))				(and (>= a 0) (= (^ b 2) a)) ) ;
	(<=> (/ X A)							(* X (^ A -1)) ) ; x / a = x * a^-1

	; INT RANGE RULES
	(=> (+ (.. A B) (.. C D))	(.. (+ A C) (+ B D)) )
	(=> (+ X (.. A B))	(.. (+ X A) (+ X B)) )
	(=> (* X (.. A B))	(.. (* X A) (* X B)) )
	(=> (+ (.. A B) X)	(.. (+ X A) (+ X B)) )
	(=> (* (.. A B) X)	(.. (* X A) (* X B)) )
	(=> (.. X X)		X )
	(=> (sqrt (.. X Y))	(.. (sqrt X) (sqrt Y)) )
	(=> (.. (A B C) (A B C)) true)

	; RANGE RULES
	(=> (+ (to A B) (to C D))	(to (+ A C) (+ B D)) )
	(=> (+ X (to A B))	(to (+ X A) (+ X B)) )
	(=> (+ (to A B) X)	(to (+ X A) (+ X B)) )
	(=> (to X X)		X ) ; empty range
	(=> (max (to A B) C)	(to (max A C) (max B C)) )
	(=> (min (to A B) C)	(to (min A C) (min B C)) )

	(=> (sin (to A B)) (to -1 1) )
	(=> (cos (to A B)) (to -1 1) )
	(=> (atan (to A B) X) (to 0 tau) )

	(=> (> A B)			(< B A) )
	(=> (>= A B)		(<= B A) )

	(<=> (F A (| B C))	(| (F A B) (F A C)) )
	(=> (+ D (| A B))	(| (+ D A) (+ D B)) )
	(=> (- D (| A B))	(| (- D A) (- D B)) )
	(=> (- (| A B) D)	(| (- A D) (- D B)) )
	(=> (* D (| A B))	(| (* D A) (* D B)) )
	(=> (* (| A B) D)	(| (* D A) (* D B)) )
	(=> (/ D (| A B))	(| (/ D A) (/ D B)) )
	(=> (/ (| A B) D)	(| (/ D A) (/ D B)) )
	(=> (.. D (| A B))	(| (.. D A) (.. D B)) )
	(=> (.. (| A B) D)	(| (.. D A) (.. D B)) )
	(=> (sum (| A B)) (| (sum A) (sum B)) )
	(=> (< D (| A B))	(| (< D A) (< D B)) )
	(=> (<= D (| A B))	(| (<= D A) (<= D B)) )
	(=> (| X X)			X)
	(=> (+- X)			(| X (- X)) )
	(=> (| false X)		X)
	(=> (| X false)		X)
	(=> (| X true)		X)
	(=> (| true X)		X)
	(=> (F undefined)	undefined)
	(=> (F undefined A) undefined)
	(=> (F A undefined) undefined)

	(=> (and
		  (= A (| B C))
		  (< A D)
		)
		(|
		  (if (< B D) (= A B) false)
		  (if (< C D) (= A C) false)
		)
	)

	; COMMUTATIVITY
	(<=> (and (* A B) (: A number) (: B number)) (* B A) )
	(<=> (+ (* C A) (* C B))	(* C (+ A B)) )
	(<=> (/ A B)				(* A (/ 1 B)) )
	(<=>
		(and
			(commutative F)
			(F A (F B C))
		)
		(F B (F A C))
	)
	(<=> (and (commutative F) (F A B))	(F B A) )
	(=> (commutative
		  	(| and or xor min max + | =))
			true
	)

	(=> (+ (+ X Y) X) (+ (* X 2) Y) )
	(=> (/ (+ A B) C) (+ (/ A C) (/ B C)) )
	(=> (/ (* A B) B)	A)
	(=> (- (+ A B) A)	B)
	(=> (* (+ A B) C)	(+ (* A C) (* B C)) )

	; abs x => abs x : 0 to inf
	(=> (< (abs X) 0) false)
	(=> (= A (abs_ X)) (> A 0))
	(+ (- (abs X)) (abs X))
	
	; SUM AN INTEGER RANGE
	(=> (sum (.. A B))
		(*
		  (/ (+ B A) 2)
		  (+ 1 (- B A))
		)
	)
	(=> (sum X) X)

	; SOLVE QUADRATIC EQUATION
	(=> (= 0 (+
			   (* A (^ X 2))
			   (* B X)
			   C
			  )
		)

		(= X (/
		  (-
			(+- 
			  (sqrt
				(-
				  (^ B 2)
				  (* 4 (* A C))
				  )
				)
			  )
			B)
		  (* 2 A)
		) )
	)
)
