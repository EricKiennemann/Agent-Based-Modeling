;define global variables
globals [
  number-of-lanes        ; number of lanes on the road
  lanes                  ; a list of the y coordinates of different lanes
  road-length-m          ; length of the road in m
  frame-rate             ; number of images(ticks) per second
  max-speed-kmh          ; max-authorised speed for all cars in km/h
  max-accel-kmhs         ; max possible acceleration in km/h/s
  max-decel-kmhs         ; upper bound for deceleration
  min-decel-kmhs         ; lower bound for deceleration
  reactivity-time        ; reactivity time in case of danger in second
  conv-kmh-patch         ; conversion from km/h to patch
  conv-kmh-dist-security ; conversion of km/h into security distance in patch unit
  average-speed          ; average top-speed and initial speed of normal cars
  variance-speed         ; max delta around average top-speed and initial speed for normal car
  ticks-change-lane      ; number of ticks necessary to overtake or cute-back
  dy-move                ; delta y patch when overtaking
  dist-min-between-car   ; minimum distance between cars in m
  dist-min-patch         ; minimal distance between 2 car in patch unit
  config-file            ; filepath of the config file
  truck-file             ; filepath of the truck file
  late-create-cars       ; number of cars to be created as soon as possible to reach the expected flow
  ticks-between-cars     ; number of ticks between each creation of a car in "flow" mode
  min-speed-flow         ; minimal speed when creating a car in "flow mode"
  rate-accel             ; rate of change around the average acceleration for the cars
  rate-decel             ; rate of change around the average decelaration for the cars
  rate-react-time        ; rate of change around the average reactivity time for the cars
  previous-flow?         ; memorize the last value for flow? variable
  previous-accel         ; memorize the last value for acceleration variable
  previous-decel         ; memorize the last value for deceleration variable
  previous-reac-time     ; memorize the last value for reactivity-time variable
]

;two kinds of turtle
;cars   : "normal" cars
;trucks : used to introduce perturbetaion in the normal flow
breed [cars car ]
breed [trucks truck ]

; common parameters to all the turtles
turtles-own [
  speed             ; the current speed of the car
  top-speed         ; the maximum speed of the car (different for all cars)
  target-lane       ; the desired lane of the car
  patience          ; the driver's current level of patience
  patience-car      ; level of patience of the car
  overtaking?       ; overtaking in progress
  cut-back?         ; cut-back in progress
  mvt-step          ; current mouvement step (during overtake or cut-back)
  default-color     ; default color when not selected
  mode-flow         ; define is the car is in "mode flow" or "mode loop"
  car-accel         ; car specific acceleration in km/h/s
  car-decel         ; car specific deceleration in km/h/s
  car-reac-time     ; car specific reaction-time in second
  change-lane?      ; turtle can change of lane ?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   BEFORE SETUP  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;reset config/truck file and sliders/button parameters to default value
to reset
  set truck-config "None"
  set truck-file FALSE
  set config-file FALSE
  set number-of-cars 30
  set acceleration 10
  set previous-accel acceleration
  set deceleration 35
  set previous-decel deceleration
  set max-patience 20
  set flow? TRUE             ; new cars by flow or by number
  set previous-flow? flow?
  set flow-cars 1200         ; flow of cars arriving
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   SETUP PHASE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ; the global variables are not cleared to keep the config file name and truck file name
  ; the other global variables are initialised either with the file or the init-constant/calculate constant procedure
  clear-ticks clear-turtles clear-patches clear-drawing clear-all-plots clear-output
  set-default-shape cars "car"
  set-default-shape trucks "truck"

  ; if a config-file has been selected before setup then use this config file
  ; only for desktop version of netlogo
  ifelse config-file != FALSE and config-file != 0 and file-exists? config-file [
    load-config-file
  ]
  ; if not use the standard values for init
  [ init-constant ]
  ; calculate usefull variables
  calculate-constant
  ; draw the road
  draw-road
  ; if a truck-file has been selected before setup then use this truck file otherwise no truck is created
  ; only for desktop version of netlogo
  ifelse truck-config = "None" [
    if truck-file != FALSE and truck-file != 0 and file-exists? truck-file [
      load-truck-file
    ]
  ]
  ; initialise with one of the 2 availables truck config
  [ init-truck ]

  ;if "mode loop" create the number of cars expected
  if flow? = FALSE [ create-cars-nb ]

  ;reset time
  reset-ticks
end

;initialise the truck depending on the value of the chooser truck-config
to init-truck
  ifelse truck-config = "Closed lane" [
    ; setup trucks to simulate a closed lane
    let x 0
    let y last lanes
    ; fill half a lane with trucks to "close" the lane
    repeat (world-width - 1) / 2 [
      create-trucks 1 [
        set mode-flow flow?
        setxy x y
        set color white
        set default-color white
        set target-lane pycor
        set heading 90
        set top-speed 0
        set speed top-speed
        set car-accel acceleration
        set car-decel deceleration
        set car-reac-time reactivity-time
        set patience-car max-patience
        set patience patience-car
        set overtaking? FALSE         ; overtaking in progress
        set cut-back?   FALSE         ; cut-back in progress
        set mvt-step 0
        set change-lane? FALSE
      ]
      set x x + 1
    ]
  ]
  [
    ; setup truck to simulate a "One obstacle per lane"
    ; on each lane create a random truck
    foreach lanes [
      y ->
      let x (random (world-width - 1)) - (world-width - 1) / 2
      let truck-speed 0

      ; create the truck
      create-trucks 1 [
        set mode-flow flow?
        setxy x y
        set color white
        set default-color white
        set target-lane pycor
        set heading 90
        set top-speed truck-speed
        set speed top-speed
        set car-accel acceleration
        set car-decel deceleration
        set car-reac-time reactivity-time
        set patience-car max-patience
        set patience patience-car
        set overtaking? FALSE         ; overtaking in progress
        set cut-back?   FALSE         ; cut-back in progress
        set mvt-step 0
        set change-lane? FALSE
      ]
    ]
  ]
end

; initialise the values (see glgobal for all the definitions)
to init-constant
  set number-of-lanes 3
  set frame-rate 25          ; number of images(ticks) per second
  set road-length-m 1000     ; length of the road in m
  set max-speed-kmh 130      ; max-authorised speed for all cars
  set max-accel-kmhs 10
  set reactivity-time 2      ; reactivity time in case of danger in second
  set average-speed 110      ; average top-speed and initial speed of normal cars
  set variance-speed 20      ; max delta around average top-speed and initial speed for normal car
  set ticks-change-lane 4    ; number of ticks necessary to change lane
  set dist-min-between-car 5 ; minimum distance between cars in m
  set min-speed-flow 80
  set rate-accel 0.1         ; rate of change around the average acceleration for the cars
  set rate-decel 0.1         ; rate of change around the average decelaration for the cars
  set rate-react-time 0.1    ; rate of change around the average reactivity time for the cars

end

; load the constant values from the <config-file> file
to load-config-file
  file-open config-file
  let flow-binary file-read
  ifelse flow-binary = 1 [set flow? TRUE]
  [set flow? FALSE]
  set flow-cars file-read
  set number-of-cars file-read
  set acceleration file-read
  set deceleration file-read
  set max-patience file-read
  set number-of-lanes file-read
  set frame-rate file-read                   ; number of images(ticks) per second
  set road-length-m file-read                ; length of the road in m
  set max-speed-kmh file-read                ; max-authorised speed for all cars
  set max-accel-kmhs file-read
  set reactivity-time file-read              ; reactivity time in case of danger in second
  set average-speed file-read                ; average top-speed and initial speed of normal cars
  set variance-speed file-read               ; max delta around average top-speed and initial speed for normal car
  set ticks-change-lane file-read            ; number of ticks necessary to overtake
  set dist-min-between-car file-read
  set min-speed-flow file-read
  set rate-accel file-read                   ; rate of change around the average acceleration for the cars
  set rate-decel file-read                   ; rate of change around the average decelaration for the cars
  set rate-react-time file-read              ; rate of change around the average reactivity time for the cars
  file-close
end

; calculate the usefull constants
to calculate-constant
  set conv-kmh-patch (world-width / (3.6 * frame-rate * road-length-m ))                  ; conversion coefficient between km/h and patch
  set conv-kmh-dist-security ( world-width / ( 3.6 * road-length-m))                      ; conversion coefficient between speed(km/h) and security speed (patch/s unit)
  set max-decel-kmhs (max-speed-kmh / reactivity-time )                                   ; max decelaration in km/h/s
  set min-decel-kmhs (max-speed-kmh / reactivity-time )   / 2                             ; min decelaration in km/h/s
  set dy-move 2 / ticks-change-lane                                                       ; delta y patch when overtaking
  set late-create-cars 0                                                                  ; number of car to be created to achieve expected car flow
  set dist-min-patch dist-min-between-car * world-width / road-length-m
end

; load truck config-file and create trucks
to load-truck-file
  file-open truck-file
  ; loop till the end of the file
  while [ not file-at-end? ] [
    ; for each truck read position on the road(x,y) and speed
    let x file-read
    let y file-read
    let truck-speed file-read
    let truck-change-lane file-read
    ifelse truck-change-lane = 1 [set truck-change-lane TRUE]
    [set truck-change-lane FALSE]
    ; transform the lane number into an index used in the lane list variable
    let lane-index (2 * y - 1 - number-of-lanes)

    ; create the truck
    create-trucks 1 [
      set mode-flow flow?
      setxy x lane-index
      set color white
      set default-color white
      set target-lane pycor
      set heading 90
      set top-speed truck-speed
      set speed top-speed
      set car-accel acceleration
      set car-decel deceleration
      set car-reac-time reactivity-time
      set patience-car max-patience
      set patience patience-car
      set overtaking? FALSE         ; overtaking in progress
      set cut-back?   FALSE         ; cut-back in progress
      set mvt-step 0
      set change-lane? truck-change-lane
    ]
  ]
  file-close
end

; function used to draw the road on the view
to draw-road
  ask patches [
    ; the road is surrounded by green grass of varying shades
    set pcolor green - random-float 0.5
  ]
  ; build a list of number-of-lanes items, centered on 0 and spaced by 2 patches
  set lanes n-values number-of-lanes [ n -> (2 / 2 ) * (number-of-lanes - (n * 2) - 1) ]
  ask patches with [ abs pycor <= number-of-lanes * (2 / 2 ) ] [
    ; the road itself is varying shades of grey
    set pcolor grey - 2.5 + random-float 0.25
  ]
  ; draw the line on the road
  draw-road-lines
end

; function to draw the lines on the road
to draw-road-lines
  let y (last lanes) - 1 ; start below the "lowest" lane
  while [ y <= first lanes + 1 ] [
    if not member? y lanes [
      ; draw lines on road patches that are not part of a lane
      ifelse abs y = number-of-lanes
        [ draw-line y yellow 0 ]  ; yellow for the sides of the road
        [ draw-line y white 0.5 ] ; dashed white between lanes
    ]
    set y y + 1 ; move up one patch
  ]
end

; draw the line itself
to draw-line [ y line-color gap ]
  ; We use a temporary turtle to draw the line:
  ; - with a gap of zero, we get a continuous line;
  ; - with a gap greater than zero, we get a dasshed line.
  create-turtles 1 [
    setxy (min-pxcor - 0.5) y
    hide-turtle
    set color line-color
    set heading 90
    repeat world-width [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

; create the new cars in "mode loop" simulation
; use the "number-of-cars" slider to define when new cars
; should be created
to create-cars-nb
  let nb-cars number-of-cars / number-of-lanes
  foreach lanes [
    x -> create-cars-per-lane x nb-cars ]
end

;create the cars on each lane
to create-cars-per-lane [y-lane nb-cars]

  ; make sure we don't have too many cars for the room we have on the road
  let road-patches patches with [ pycor = y-lane ]

  create-cars (nb-cars) [
    move-to one-of free road-patches
    set target-lane pycor
    set heading 90
    set top-speed (average-speed  + (random-float (variance-speed)) * 2 - variance-speed)
    set speed  top-speed - variance-speed  +  (random-float variance-speed)
    set default-color car-color
    set color default-color
    set mode-flow FALSE
    set patience-car 2 + random max-patience
    set patience patience-car
    set car-accel acceleration * (1 + triangle-random rate-accel)
    set car-decel deceleration * (1 + triangle-random rate-decel)
    set car-reac-time reactivity-time * (1 + triangle-random rate-react-time)
    set overtaking? FALSE       ; overtaking in progress
    set cut-back?   FALSE      ; cut-back in progress
    set mvt-step 0
    set change-lane? auth-change-lane?
  ]

end

; report the patches without any car
to-report free [ road-patches ]
  let this-car self
  report road-patches with [
    not any? turtles-here with [ self != this-car ]
  ]
end

; calculate the triangle random number associated to number
to-report triangle-random [ number ]
  report (0.5 + random-float 0.5 - random-float 0.5) * number
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;    GO PHASE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  ;update variable that are using sliders value
  update-slider-variable

  ; create the cars on the road
  ; at each tick evaluate if new car need to be created depending on the requested number of cars
  ; car creation procedure depends on "mode flow" or "mode loop" simulation (see documentation)
  if flow? = TRUE [ create-cars-flow ]


  ; move forward cars and truck ... if possible
  ask turtles [ move-forward ]



  ; select the turtles that are not doing overtaking or cut-back and check if it can cut-back and check authorised to change lane ?
  ask turtles with [ not-moving and change-lane? = TRUE ] [ check-to-cut-back ]
  ; select the turtles that are not doing overtaking or cut-back and which patience is over, and check if it can overtake ?
  ; and check authorised to change lane
  ask turtles with [ patience <= 0 and not-moving and change-lane? = TRUE] [ check-target-lane ]

  ; depending on the previous check realise cut-back or overtaking (cut-back is prioritary)
  ask turtles with [ overtaking? = TRUE] [ move-to-target-lane ]
  ask turtles with [ cut-back? = TRUE] [ cut-to-target-lane ]

  ;move the clock
  tick
end

; update the variable that are using sliders values
to update-slider-variable
  set ticks-between-cars (frame-rate * 3600 / flow-cars)
  ; if the average acceleration change, change it for all the cars
  if acceleration != previous-accel [
    ask cars [
      set car-accel acceleration * (1 + triangle-random rate-accel)
    ]
    ask trucks [
      set car-accel acceleration
    ]
  ]
  ; if the average deceleration change, change it for all the cars
  if deceleration != previous-decel [
    ask cars [
      set car-decel deceleration * (1 + triangle-random rate-decel)
    ]
    ask trucks [
      set car-decel deceleration
    ]
  ]

  ; if the flow-mode is changed
  if flow? != previous-flow? [
    ask turtles [
      set mode-flow flow?
    ]
    set previous-flow? flow?
  ]
end

; create the new cars in "mode flow" simulation
; rely on flow "flow-cars" slider to define when new cars
; should be created
to create-cars-flow

  let local-lanes lanes  ; list of lanes on the road

  ; check if it is time to create a car. If yes add one to the car to be created
  if remainder ticks int(ticks-between-cars) = 0 [ set late-create-cars late-create-cars + 1]
  let to-create late-create-cars

  ; try to create at maximum one car per lane at each tick
  set to-create min list to-create number-of-lanes
  ;if there are cars to be created
  if to-create > 0 [
     ; try to create the number of car needed
     repeat to-create [
        ; start creating the car
        create-cars 1 [
        set heading 90
        ; position the car on the left of the road
        setxy (- world-width / 2 + 0.5 ) last local-lanes
        set speed  0
        set car-reac-time reactivity-time * (1 + triangle-random rate-react-time)
        ; calculate the maximum of security distance
        let dist security-distance max-speed-kmh
        ;select the cars ahead that are in this maximum security distance
        let blocking-cars other turtles in-cone dist 0
        ; select the closest car inside this security distance
        let blocking-car min-one-of blocking-cars [ distance myself ]
        ; for closest car, calculate its distance
        ifelse  blocking-car != nobody [
          set top-speed (average-speed  + (random-float (variance-speed)) * 2 - variance-speed)
          set dist distance blocking-car
          set speed min list  ( speed-from-distance dist) (top-speed - variance-speed  +  (random-float variance-speed))
        ]
        [
          set top-speed (average-speed  + (random-float (variance-speed)) * 2 - variance-speed)
          set speed  top-speed - variance-speed  +  (random-float variance-speed)
        ]
        ; adapt the speed of the created car to this distance (used as a security distance)
        set speed speed-from-distance dist
        ; if the speed is too low (under min-speed-flow parameter)
        ; kill the created vehicule ... and try at next tick
        ifelse speed < min-speed-flow [
          die ] [
          ; finish the initialisation of the car
          set default-color car-color
          set color default-color
          set patience-car 2 + random max-patience
          set patience patience-car
          set car-accel acceleration * (1 + triangle-random rate-accel)
          set car-decel deceleration * (1 + triangle-random rate-decel)
          set overtaking? FALSE       ; overtaking in progress
          set cut-back?   FALSE      ; cut-back in progress
          set mvt-step 0
          set change-lane? auth-change-lane?
          ; decrease the number of car to be created
          set late-create-cars late-create-cars - 1
          set mode-flow flow?
        ]
      ]
      ; go to the next lane (on the left) if more cars need to be created
      set local-lanes but-last local-lanes
    ]
    ; if impossible to create enough cars to achieve right flow
    ; decrease min-speed-flow of 10 km/h
    if late-create-cars > number-of-lanes [
      set min-speed-flow min-speed-flow - 10
      if min-speed-flow < 10 [ set min-speed-flow 10]
    ]
  ]
end



; report TRUE when a turtle is not overtaking or cutting back
to-report not-moving
 report (cut-back? = FALSE) and (overtaking? = FALSE)
end

; procedure to define the moving forward of a turtle
; take in account other cars position to decide
to move-forward
  ; test if the car is in "mode flow" or "mode loop"
  ;let mode-flow FALSE
  ifelse (mode-flow = FALSE) [
    ; we are in mode loop, no need to take in account the "end of the road",
    ; netlogo do it since the world is closed
    ; list the cars inside the security distance
    let blocking-cars other turtles in-cone security-distance speed 0
    ; selected the closest car inside security distance
    let blocking-car min-one-of blocking-cars [ distance myself ]
    ; if there is a car inside security distance
    ifelse blocking-car != nobody [
      ;slow down to try to "rebuild" the security distance
      slow-down-car
      ; every time you slow down, you loose a little patience
      set patience patience - 1
    ]
    ;if the road is free
    [
      ;try to speed up
      speed-up-car;
    ]
    ; move forward of a value depending on your speed
    forward kmh-to-patch speed
  ]
  [
    ; we are in mode flow, we need to take in account the "end of the road",
    ; and to kill cars when they reach it

    ; calculate if we are at the end of the road
    let deltax kmh-to-patch speed
    ifelse xcor + dx > world-width / 2 [
      ; the turtle is at the end of the road, it is killed
      die
    ]
    [
      ;not yet at the end of the road
      ; list the cars inside the security distance; do not consider the closed world
      let blocking-cars other turtles in-cone min list (security-distance speed) (world-width / 2 - xcor) 0
      ; selected the closest car inside security distance
      let blocking-car min-one-of blocking-cars [ distance myself ]
      ; if there is a car inside security distance
      ifelse blocking-car != nobody [
        ;slow down to try to "rebuild" the security distance
        slow-down-car
        ; every time you hit the brakes, you loose a little patience
        set patience patience - 1
      ]
      ;if the road is free
      [
        ;try to speed up
        speed-up-car;
      ]
      ; move forward of a value depending on your speed
      forward kmh-to-patch speed
    ]
  ]
end


; return the closest car to the actual car looking in a direction,
;at a distance and with an open angle
to-report detect-car [ dist angle direction ]
  set heading direction
  let blocking-cars other turtles in-cone dist angle
  let blocking-car min-one-of blocking-cars [ distance myself ]
  set heading 90
  report blocking-car
end

; reduce the speed of a car
to slow-down-car ; turtle procedure
  set speed (speed - car-decel / frame-rate)
  if speed < 0 [ set speed 0 ]
end

; increase the speed of a car
; the speed can't be above top-speed
; if the top-speed expected is reach the patience is set to
; maximal value again
to speed-up-car ; turtle procedure
  set speed (speed + car-accel / frame-rate)
  if speed >= top-speed [
    set speed top-speed
    ; the road is free; your patience is max again
    set patience patience-car
  ]
end

; check if the lane on the left is free
; in order to overtake
to check-target-lane ;
  ; if the car is not already on the left lane
  if ycor != first lanes [
    let my-position position ycor lanes
    ; define the position of the lane on the left
    set target-lane item (my-position - 1) lanes
    ;move temporary the turtle to check for overtaking
    hide-turtle
    let save-ycor ycor
    setxy xcor target-lane
    ; calculate the security distance available in case of overtaking
    let sec-dist security-distance speed
    ; front-car is the car in front inside distance security
    let front-car detect-car  sec-dist 0 90
    ; back car is the car behind inside distance security
    let back-car detect-car sec-dist 0 270
    ;come back to initial position
    setxy xcor save-ycor
    ; overtaking is possible if no car behind and no car ahead
    if (front-car = nobody) and (back-car = nobody) [
      set overtaking?  TRUE
      set patience patience-car
    ]
    show-turtle
  ]
end

; check if the lane on the right is free
; in order to cut-back
to check-to-cut-back ;
  ; if the car is not already on the right lane
  if ycor != last lanes [
    let my-position position ycor lanes
    ; define the position of the lane on the right
    set target-lane item (my-position + 1) lanes

    ;move temporary the turtle to check for cutting back
    hide-turtle
    let save-ycor ycor
    setxy xcor target-lane
    ; calculate the security distance available in case of overtaking
    let sec-dist security-distance speed
    ; front-car is the car in front inside distance security
    let front-car detect-car  sec-dist 0 90
    ; back car is the car behind inside twice the minimal distance between cars
    let back-car detect-car (dist-min-patch * 2) 0 270
    setxy xcor save-ycor
    ; cut-back is possible if no car behind and no car ahead
    if (front-car = nobody) and (back-car = nobody) [
      set cut-back?  TRUE
      set patience patience-car
    ]
    show-turtle
  ]
end
; realize the overtaking
to move-to-target-lane ;
  ; the over taking is done in ticks-change-lane ticks
  setxy xcor ycor + dy-move
  if ycor = target-lane [
    set overtaking? FALSE
  ]
end

;realize the cut-back
to cut-to-target-lane ;
  ; the cut-back is done in ticks-change-lane ticks
  setxy xcor ycor - dy-move
  if ycor = target-lane [
    set cut-back? FALSE
  ]
end

; convert km/h in patch/tick
to-report kmh-to-patch [ kmh ]
  report kmh * conv-kmh-patch
end

; give the security distance for
; a given speed in km/h
; the result is in patch unit
; dist-min-patch is the minimum security distance between
; 2 cars
to-report security-distance [ kmh ]
  let dist  kmh * conv-kmh-dist-security * car-reac-time
  if dist < dist-min-patch [
    set dist  dist-min-patch ]
  report dist
end

; convert a distance between car (patch unit)
; into the allowed speed in km/h
to-report speed-from-distance [ dist ]
  let to-speed  dist / ( conv-kmh-dist-security * car-reac-time)
  report to-speed
end

; report a car color
to-report car-color
  ; give all cars a blueish color, but still make them distinguishable
  report one-of [ blue cyan sky ] + 1.5 + random-float 1.0
end
@#$#@#$#@
GRAPHICS-WINDOW
219
10
1227
155
-1
-1
8.0
1
10
1
1
1
0
1
0
1
-62
62
-8
8
1
1
1
ticks
50.0

BUTTON
10
50
75
85
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
150
50
215
85
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
80
50
145
85
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
1125
215
1230
260
Mean speed
mean [speed] of cars
2
1
11

SLIDER
11
228
216
261
number-of-cars
number-of-cars
number-of-lanes
number-of-lanes * world-width / 5
30.0
number-of-lanes
1
NIL
HORIZONTAL

PLOT
219
165
684
410
Car Speeds
Time
Speed
0.0
300.0
0.0
0.5
true
true
"" ""
PENS
"mean" 1.0 0 -10899396 true "" "if ticks != 0 [plot mean [ speed ] of cars]"
"max" 1.0 0 -11221820 true "" "if ticks != 0 [plot max [ speed ] of cars]"
"min" 1.0 0 -13345367 true "" "if ticks != 0 [plot min [ speed ] of cars]"

SLIDER
11
268
216
301
acceleration
acceleration
0
max-accel-kmhs
10.0
0.01
1
km/h/s
HORIZONTAL

SLIDER
11
303
216
336
deceleration
deceleration
min-decel-kmhs
max-decel-kmhs
35.0
0.1
1
km/h/s
HORIZONTAL

PLOT
687
165
1122
410
Cars Per Lane
Time
Cars
0.0
0.0
0.0
0.0
true
true
"set-plot-y-range (floor (count cars * 0.4)) (ceiling (count cars * 0.6 + 1))\nforeach range length lanes [ i ->\n  create-temporary-plot-pen (word (i + 1))\n  set-plot-pen-color item i base-colors\n]" "foreach range length lanes [ i ->\n  set-current-plot-pen (word (i + 1))\n  plot count cars with [ round ycor = item i lanes ]\n]"
PENS

SLIDER
11
338
216
371
max-patience
max-patience
1
100
20.0
1
1
NIL
HORIZONTAL

SWITCH
11
376
216
409
auth-change-lane?
auth-change-lane?
0
1
-1000

MONITOR
1125
165
1229
210
Nb of cars
count cars
17
1
11

BUTTON
10
10
75
43
load config
set config-file user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
80
10
145
43
load truck
set truck-file user-file\nset truck-config \"None\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
193
216
226
flow-cars
flow-cars
0
6000
1200.0
60
1
car/h
HORIZONTAL

SWITCH
11
158
216
191
flow?
flow?
0
1
-1000

BUTTON
150
10
215
43
reset all
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1125
265
1229
310
Cars to be created
late-create-cars
17
1
11

CHOOSER
10
109
215
154
truck-config
truck-config
"None" "Closed lane" "One obstacle per lane"
2

@#$#@#$#@
## WHAT IS IT?

This model aims at answering various questions regarding road traffic. It is a framework that can be updated to take in account different scenarios. 
In this actual version it is possible to simulate the following scenarios :

* impact on the traffic of a slow car/truck on the first lane
* impact of a closed lane (for instance the right lane) on the traffic
* creation of a bottleneck when the road is totally closed
 

## HOW TO USE IT

### General view

First adjust the zoom to your screen so that you can see the whole road on your screen

There are two main ways to use it :

* out of the box : for simple simulation
	- adjust the parameters you want with the sliders (see below slider description) and the chooser (to choice "trucks")
	- SETUP button to set up the lanes and the cars (3 lanes by default)
	- GO to start up moving
	- GO once button drives the cars for just one tick of the clock.

* setup file : for more advanced built-in scenario
	- ajust same parameters as in out of the box scenarios
	- plus internal parameters
	- plus add specific vehicules to simulate close line, slow vehicules ...

For both way of using it there are two simulation mode available :

* "mode flow" where : 
	- the cars are killed at the end of the road
	- new cars are created depending on the flow-cars slider value

* "mode loop" where :
	- the car arriving at the end of the road start back at the beginning
	- the cars are created at tick 0 with the number of cars given by number-of-cars slider

### Setup files

* **reset** button : 
	- should be used the first time using the simulation before **setup**.
	- it initialize all the values of sliders and chooser to default values
	- it allows also to cancel the selection of configuration file and come back to "out of the box" way of playing

* **load config** button :
	- to be done before **setup**
	- is used to load a setup file
	- the fields available in this setup file are described in the config_sample.txt file
	- never suppress a line or change the order of the parameters
	- some parameters in the setup file can be changed after loading using sliders (see below sliders description)

* **load truck** button :
	- to be done before **setup**
	- is used to load a truck file
	- the fields available in this truck file are described in the truck_sample.txt file (exemple of a closed lane)
	- never suppress a line or change the order of the parameters
	- initialise the chooser truck-config to "None"

* **setup** button :
	- create the road
	- create the trucks on the road
	- create the cars if in "mode loop"

### Chooser / Sliders / Switch description

The chooser / sliders / switch parameters are the following :

* The **truck-config** chooser makes it possible to add pre defined "truck" configuration. Three choices are available :
	- "None" : no truck is added
	- "Closed lane" : trucks are added to simulate a closed lane
	- "One obstacle per lane" : one obstacle is randomly added to each lane to disturb the fow

* The **Flow?** switch detemrine if we are on "mode flow" or "mode loop" 

* The **flow-cars** slider define the flow of created car in the "mode flow". All the cars are created on theleft of the road. This parameter can be changed during the GO phase

* The **number-of-cars** slider controls the number of cars on the road. This is a SETUP parameter that can't be changed during the  GO. It only applies to "mode loop"

* The **acceleration** slider controls the rate at which cars accelerate when there are no cars ahead.(unit : km/h/s). Can be used in GO mode.
This is a global parameter for all the cars but each car has a specific acceleration build from this **acceleration** time a triangle random acceleration (between 0 and 1). The formula for each car is "car accelerarion" = "acceleration" * (1 + rate-accel * "random triangle"). rate-accel is a global parameter setup (see below)


* The **deceleration** slider controls the rate at which cars decelerate when there is a car close ahead.(unit km/h/s). Can be used in GO mode
This is a global parameter for all the cars but each car has a specific deceleration build from this **deceleration** time a triangle random deceleration (between 0 and 1). The formula for each car is "car deceleration" = "decelaration" * (1 + rate-decel * "random triangle"). rate-decel is a global parameter setup (see below)


* The **max-patience** slider controls how many times a car can slow down or be under its expected speed before a driver loses their patience and tries to change lanes.
This is a global parameter for all the cars but each car has a specific patience build from the formula : 2 + random **max-patience**

* The **auth-change-lane** is a switch that enable or not cars to change lane (overtake or cut-back)

### Other parameters that can be changed with configuration file


* **number-of-lanes** (default = 3) : number of lanes on the road
	only one way is simulated by this tool. The maximum number of lanes is 8
* **frame-rate** (default = 25) : used to make the conversion between time and ticks :   number of images(ticks) per second
* **road-length-m** (default = 1000m) : length of the road in m. On the screen the length of the road is always the same. This parameter changes the length in m of each patch
* **max-speed-kmh** (default = 130 km/h)  max-authorised speed for all cars : also used to calculate the maximum decelaration (max-speed-kmh / reactivity-time / frame-rate)
* **max-accel-kmhs** (default = 10 km/h/s)  maximum of accelaration speed for all cars. Upper bound for acceleration slider.
* **reactivity-time** (default = 2s) :  reactivity time in case of danger in second.Used to calculate security distance between cars
This is a global parameter for all the cars but each car has a specific reactivity time build from this **reactivity-time** time a triangle random reactivity-time (between 0 and 1). The formula for each car is "car reactivity time" = "reactivity-time" * (1 + rate-react-time * "random triangle"). rate-react-time is a global parameter setup (see below)
* **average-speed** (default =  110 km/h)    ; average top-speed (= expected speed for all the cars). Used with variance-speed to define the initial and top-speed of each car (see THINGS TO NOTICE)
* **variance-speed** (default = 20 km/h) : max delta around average top-speed 
* **ticks-for-overtaking (default = 4)** : number of ticks necessary to overtake or cut-back (to go from one lane to the other)
* **dist-min-between-car** (default =  5m) : minimum distance between cars in m
* **min-speed-flow** (default = 60km/h)  : minimal speed when creating a car in "flow mode"
* **rate-accel** (default = 0.1) : rate of change around the average acceleration for the cars (see sliders description for explanation)
* **rate-decel** (default = 0.1) : rate of change around the average decelaration for the cars (see sliders description for explanation)
* **rate-react-time** (default = 0.1) : rate of change around the average reactivity time for the cars (see above for global description)

### Graphs

The YCOR OF CARS plot shows a histogram of how many cars are in each lane, as determined by their y-coordinate. The histogram also displays the amount of cars that are in between lanes while they are trying to change lanes.

The CAR SPEEDS plot displays four quantities over time:

- the maximum speed of any car - CYAN
- the minimum speed of any car - BLUE
- the average speed of all cars - GREEN

### Monitor

Three parameters are monitored :

* Nb of Cars : the number of cars present on the road (do not take in account the "trucks")
* Mean speed : the mean speed for all the cars
* Cars to be created : in "mode flow" the number of car still to create if the programme do not manage to create cars quickly enough


## THINGS TO NOTICE

### Setup

* the setup do not clear all the globals variables. Some global variables are initialized during setup bu not all.
* the following variables are not initialized by setup but can be initialized by **reset** button :

	- truck-file
	- config-file 
	- number-of-cars 
	- acceleration 
	- deceleration 
	- max-patience  
	- flow?           
	- flow-cars   

### Go

* The way cars are created depends of the mode :

	- on "mode flow" the flow-cars parameter define the frequency of creation of a car. On each tick this frequency is checked. If a car must be created, it is created on the rightest lane with the highest speed possible. The security distance with the car ahead is checked. If the security distance is too small then the car is killed and the creation process is tried again at next tick.
If the flow is high it can be difficult to create cars quickly enough so the systems first try to create the cars on the other lanes; if it is still too slow then it reduces the car creation speed to reduce security distance. Finally if it is still not quick enough then the variable late-create-cars (which is monitored increases)
	- on "mode loop" cars are created during the setup and no other cars are created during go phase. The cars are created randomly on the road with an equal number on each lane. The cars are created on empty patches.

	- the "trucks" are created using the datas in the "truck config file"

* rules to overtake / cut-back

	- to overtake a car must have a patience equal or lower to 0. Then in the same tick the car is moved to the next lane and checks on secutity distance are made with the car ahead and below if everything is ok the overtaking process starts. The process it self takes a number of ticks driven by the ticks-change-lane parameter.
	- the cut-back process is mainly the same. The main difference is that there is no patience parameter. Cut-back can be done immediatly

## THINGS TO TRY

Three configuration files are delivered :

* impact on the traffic of a slow car/truck on the first lane (truck_slow.txt and config_sample.txt)
* impact of a closed lane (for instance the right lane) on the traffic (truck_closed_line.txt and config_sample.txt)
* impact of a totally closed road (truck_closed_road.txt and config_5000m.txt)

But the number of scenario is infinite : just play with the parameters and the configuration file

## EXTENDING THE MODEL

A lot of improvment can be made :

* add a 2nd way lane to simulate the "curiosity bottleneck" for instance
* add crossroads
* add more specific behaviors : for instance people that always stay on the line or never cut-back
* simulate accident
.....


## NETLOGO FEATURES

* loading config files
* the weblogo version is available here : https://storage.googleapis.com/netlogo/car_flow_simulation.html
on the web version it is not possible to load config file and truck file. It is still possible to modify the parameters directly in the code and to add in the code more "truck" configurations.


## RELATED MODELS

This model has been build from the "NetLogo Traffic 2 Lanes model"

* Wilensky, U. & Payette, N. (1998).  NetLogo Traffic 2 Lanes model.  http://ccl.northwestern.edu/netlogo/models/Traffic2Lanes.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

using the NetLogo software :

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


Other models related to "traffic" :

- "Traffic Basic": a simple model of the movement of cars on a highway.

- "Traffic Basic Utility": a version of "Traffic Basic" including a utility function for the cars.

- "Traffic Basic Adaptive": a version of "Traffic Basic" where cars adapt their acceleration to try and maintain a smooth flow of traffic.

- "Traffic Basic Adaptive Individuals": a version of "Traffic Basic Adaptive" where each car adapts individually, instead of all cars adapting in unison.

- "Traffic Intersection": a model of cars traveling through a single intersection.

- "Traffic Grid": a model of traffic moving in a city grid, with stoplights at the intersections.

- "Traffic Grid Goal": a version of "Traffic Grid" where the cars have goals, namely to drive to and from work.

- "Gridlock HubNet": a version of "Traffic Grid" where students control traffic lights in real-time.

- "Gridlock Alternate HubNet": a version of "Gridlock HubNet" where students can enter NetLogo code to plot custom metrics.



## COPYRIGHT AND LICENSE

Using the NetLogo software :

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>cars-quicker - cars-slower</metric>
    <enumeratedValueSet variable="number-of-lanes">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="acceleration" first="0" step="0.002" last="0.01"/>
    <enumeratedValueSet variable="max-patience">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-cars" first="30" step="10" last="80"/>
    <steppedValueSet variable="deceleration" first="0" step="0.02" last="0.1"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
