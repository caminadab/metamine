(
	(=> (and true) true)
	(=> (and true ...) (and ...))
	(=> (and false ...) false)
	(=> (and X) X)

	(=> (+- X) (| X (- X)))
	(=> (+ (| A B) C) (| (+ A C) (+ B C)))		; distribueren
	(=> (| (| A B) ...) (| A B ...))					; nivelleren
	(=> (| A)	A)															; eentje maar
	(=> (+ 0 A B ...) (+ A B ...))
	(=> (+ 0 A) A)
	(=> (| A A ...) (| A ...))								; dubbelen filteren

	(= (+ A ...) (+ ... A))
	(= (+ A B ...) (+ B A ...))
	(= (| A ...) (| ... A))
	(= (| A B ...) (| B A ...))								; dubbelen filteren
)
