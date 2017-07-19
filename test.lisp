(=? 0 (* a 0))

(and
	;# rekenen
	(=? 6 (+ 1 2 3))
	(=? 0 (- 3 2 1))
	(=? 1 (+ 1 (- 2 2)))
	(=? 6 (* 1 2 3))
	(=? 1 (/ 4 2 2))
	(=? oo (/ 1 0))


	; basis algebra
	(=? 0 (* a 0))

	;# opties
	(=? (+- 1) (| 1 -1))
	(=?
		(+ (| 1 2) 3)
		(| 4 5)
	)

	;# vergelijkingen

	; b=a/c = a=bc
	(=?
		(= a (* b c))
		(= b (/ a c))
	)


	;# machten
	(=? (sqrt 9) 3)
	(=? (cbrt 8) 2)
	(=? (sqrt -1) i)
	(=? (sqrt -9) (* i 3))


	;# trigonometrie
	(=? (sin (+ a tau)) (sin a))

	; typen
;	(=?
;		(and
;			(= (>> number zero) 0)
;			(= a 1)
;			(: a number)
;			a
;		)
;		0
;	)

)
