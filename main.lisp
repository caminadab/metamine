(
  (:= a0 (sin nu)) 
  (:= a (+ 1 a0)) 
  (:= stip0_0 a) 	; lijst
  (:= stip0_1 a) 	; lijst
  (:= stip_0 (* 100 stip0_0)) 	; lus, i=0
  (:= stip_1 (* 100 stip0_1)) 	; lus, i=1
  (:= stip ([] stip_0 stip_1))	; resultaat oprollen
)