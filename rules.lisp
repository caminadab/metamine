(
	(=> (and true) true)
	(=> (and true A ...) (and A ...))
	(=> (and false ...) false)
	(=> (and X) X)

	; algebra
	(= (* A B ...) (* B A ...))
	(= (* A ...) (* ... A))
	(= (+ A B ...) (+ B A ...))
	(= (+ A ...) (+ ... A))

	(=> (* 1 A B ...) (* A B ...))
	(=> (* 1 A) A)
	(=> (* 0 A) 0)
	(=> (+ 0 A ...) (+ A ...))
	(=> (+ 0 A) A)
	(=> (+ A) A)
	(=> (/ A 1) A)
	(=> (/ A 0) oo)
	(=> (abs (- A)) A)
	(=>
		(+ A A ...)
		(+ (* 2 A) ...)
	)
	(=>
		(* A A ...)
		(* (^ A 2) ...)
	)
	(=> (- A B C) (- A C B))
	(=> (- A B ...) (- A ... B))

	; machten
	(=> (sqr A) (^ A 2))
	(=> (sqrt A) (^ A (/ 1 2)))
	(=> (cbrt A) (^ A (/ 1 3)))
	(=> (^ -1 0.5) i)
	(=> (sqr i) -1)
	(=>
		(* (^ M E) M ...)
		(* (^ M (+ 1 E)) ...)
	)

	(=>
		(* (^ M E) (^ M F) ...)
		(* (^ M (+ E F)))
	)


	; opties
	(=> (+- X) (| X (- X)))
	(=> (+ (| A B) C) (| (+ A C) (+ B C)))		; distribueren
	(=> (| (| A B) ...) (| A B ...))					; nivelleren
	(=> (| A)	A)															; eentje maar
	(=> (| A A ...) (| A ...))								; dubbelen filteren

	(= (+ A ...) (+ ... A))
	(= (+ A B ...) (+ B A ...))
	(= (| A ...) (| ... A))
	(= (| A B ...) (| B A ...))								; dubbelen filteren

	(= (and A B ...) (and B A ...))
	(= (and A ...) (and ... A))

	; reeksen
	(=>
		(+ (.. A B))
		(/ (- (sqr b) (sqr a)) 2)
	)
	(=> (.. A A) none)

	; vergelijkingen
	(=
		(= A (* B ...))
		(= B (/ A ...))
	)
	(=
		(= A (+ B ...))
		(= B (- A ...))
	)
	(= (=? A B) (=? B A))
	(=> (= A A) true)
	(=> (=? A A) true)

	; trigonometrie
	(= pi (/ tau 2))
	(=>
		(sin (+ A tau))
		(sin A)
	)

	; typen
;	(=>
;		(and
;			(: V FROM)
;			(= (>> FROM TO) CONV)
;			(>> V CONV)
;		)
;	)

	; A op B = B op A
)
