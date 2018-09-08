(
  (:= stip1 (' stip)) 
  (:= stip0_0 (+ (stip1 0) 10)) 	; lus, i=0
  (:= stip0_1 (+ (stip1 1) 10)) 	; lus, i=1
  (:= stip_0 (=> toets-rechts stip0_0)) 	; lus, i=0
  (:= stip_1 (=> toets-rechts stip0_1)) 	; lus, i=1
  (:= stip1_0 2) 	; lijst
  (:= stip1_1 2) 	; lijst
  (:= stip0_0 (* 100 stip1_0)) 	; lus, i=0
  (:= stip0_1 (* 100 stip1_1)) 	; lus, i=1
  (:= stip_0 (=> start stip0_0)) 	; lus, i=0
  (:= stip_1 (=> start stip0_1)) 	; lus, i=1
  (:= stip ([] stip_0 stip_1))	; resultaat oprollen
)