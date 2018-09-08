(
  (:= a0 (sincos nu)) 
  (:= a_0 (+ 1 (a0 0))) 	; lus, i=0
  (:= a_1 (+ 1 (a0 1))) 	; lus, i=1
  (:= stip_0 (* 100 a_0)) 	; lus, i=0
  (:= stip_1 (* 100 a_1)) 	; lus, i=1
  (:= stip ([] stip_0 stip_1))	; resultaat oprollen
)