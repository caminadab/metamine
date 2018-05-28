(
  (= toetsRechts 0) 
  (= toetsLinks 0) 
  (= toetsOmhoog 0) 
  (= toetsOmlaag 0) 
  (
    = 
    links 
    (
      [] 
      (+ 5 toetsRechts-toetsLinks) 
      toetsOmhoog
    )
  ) 
  (= rechts ([] 15 0)) 
  (= bal ([] 10 10)) 
  (= scherm ([] 1280 1024)) 
  (= veld 20) 
  (
    = 
    links 
    (* (/ linksScherm scherm) veld)
  ) 
  (
    = 
    linksScherm 
    (* (/ links veld) scherm)
  ) 
  (
    = 
    scherm 
    (/ linksScherm (/ links veld))
  ) 
  (
    = 
    veld 
    (/ links (/ linksScherm scherm))
  ) 
  (
    = 
    rechts 
    (* (/ rechtsScherm scherm) veld)
  ) 
  (
    = 
    rechtsScherm 
    (* (/ rechts veld) scherm)
  ) 
  (
    = 
    scherm 
    (/ rechtsScherm (/ rechts veld))
  ) 
  (
    = 
    veld 
    (/ rechts (/ rechtsScherm scherm))
  ) 
  (= bal (* (/ balScherm scherm) veld)) 
  (= balScherm (* (/ bal veld) scherm)) 
  (= scherm (/ balScherm (/ bal veld))) 
  (= veld (/ bal (/ balScherm scherm))) 
  (= balScherm (cirkels 2)) 
  (
    = 
    cirkels 
    ([] linksScherm rechtsScherm balScherm)
  ) 
  (= linksScherm (cirkels 0)) 
  (= rechtsScherm (cirkels 1)) 
  (= stdout (cat cirkels)) 
  (= beweeg-snelheid 6) 
  (= spring-snelheid 15) 
  (= speler-radius (. 1 2)) 
  (= bal-radius (. 0 8)) 
  (= net-grootte ([] (. 0 3) (. 2 0))) 
  (= zwaartekracht 16) 
  (= veld 20) 
  (
    = 
    links-start 
    ([] (- (/ veld 2) (/ veld 4)) 0)
  ) 
  (
    = 
    rechts-start 
    ([] (+ (/ veld 2) (/ veld 4)) 0)
  ) 
  (= dt (/ 1 60)) 
  (
    = 
    beweeg-snelheid 
    (/ xsp ([] 1 1 (- 1)))
  ) 
  (
    = 
    xsp 
    (* ([] 1 1 (- 1)) beweeg-snelheid)
  ) 
  (
    = 
    spring-snelheid 
    (- (- ysp zwaartekracht))
  ) 
  (
    = 
    ysp 
    (+ (- spring-snelheid) zwaartekracht)
  ) 
  (
    = 
    zwaartekracht 
    (- ysp (- spring-snelheid))
  ) 
  (= links-snelheid ([] xsp ysp)) 
  (
    = 
    dt 
    (
      / 
      (- links links-start) 
      (som links-snelheid)
    )
  ) 
  (
    = 
    links 
    (
      + 
      links-start 
      (* (som links-snelheid) dt)
    )
  ) 
  (
    = 
    links-start 
    (- links (* (som links-snelheid) dt))
  ) 
  (= enter ([] 10)) 
  (
    = 
    stdout 
    (
      || 
      (tekst (links 0)) 
      (|| enter (|| (tekst (links 1)) enter))
    )
  )
)