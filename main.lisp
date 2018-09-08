(
  (:= a1 (= nu start)) 
  (:= a0 (=> a1 0)) 
  (:= a4 (' a)) 
  (:= a6 (' a)) 
  (:= a7 (/ 1 60)) 
  (:= a5 (+ a6 a7)) 
  (:= a3 (=> a4 a5)) 
  (:= a8 (=> toets-spatie-aan 0)) 
  (:= a2 (| a3 a8)) 
  (:= a (| a0 a2)) 
  (:= stip0_0 a) 	; lijst
  (:= stip0_1 a) 	; lijst
  (:= stip_0 (* 100 stip0_0)) 	; lus, i=0
  (:= stip_1 (* 100 stip0_1)) 	; lus, i=1
  (:= stip ([] stip_0 stip_1))	; resultaat oprollen
)