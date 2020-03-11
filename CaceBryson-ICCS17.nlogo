;;  The impact of ecological constraints on a model of altruistic communication --

;; This version of the simulation was written by Joanna Bryson while a fellow of the Konrad Lorenz Institute for Evolution and Cognition Research, while on sabbatical from the University of Bath.
;; It is based on a simulation by Cace and Bryson (2005, 2007).

;; Changes since journal submission:
;;                                        March 2017 by JJB: tidied for ICCS
;;                                  15 December 2007 by JJB: enable exploration of different niche sizes.
;;                                  01 January  2008 by JJB: mutation for Boyd.
;;                                  09 February 2009 by JJB: remove predation experiments, Cace's old file code (pre-Behaviour Spaces) for PNAS archive
;;                                  31 January  2010 by JJB: fix comments clarifying food growth, update to NetLogo 4.1 (didn't require code change)
;;                                        July  2010 by JJB & WEML:  new BehavSpace code to run viscosity checks
;;                                    September 2010 by JJB: caught weird food consumption bug working on derived simulation; didn't impact results but reran figures anyway.
;;				       November 2011 by JJB: change experiment names for HBES submission

;;    globalvars from sliders etc.:
;;
;;            starting-proportion-altruists   ;; the chance that a turtle will be a comunicator
;;            food-depletes?    ;; determines whether there is a cost to sharing knowledge -- does the food deplete if someone else eats it?
;;            food-replacement-rate       ;; how many turns until food grows back -- originally 35
;;            ratio-of-special-foods      ;; 2 is raised to this and multiplied by food-replacement-rate.  Originally 1/16th == -4
;;            run-dist          ;; approx distance moved per turn , see below
;;            travel-mode       ;; exact distance; levi flight; smooth distribution; or warp
;;            num-food-strat              ;; number of types of things to eat (& know about)
;;            lifespan                    ;; the maximum turtle age
;;            travel-mode                 ;; one of run (continuous), warp (jump anywhere), only-freeriders-warp
;;            start-num-turtles                 ;; num soc-turtles in initial population
;;            simulation-runtime          ;; how many timesteps the simulation runs
;;            broadcast-radius            ;; how far away soc-turtles can receive / observe knowledge transmission.  Ivana's default was 1
;;            mutation?          ;; if off, none
;;            freq-of-mutation   ;; if mutation? on, then 1 in 10 raised to this will be a different species than their parents


;;     Ivana wrote code for this, but had it set to 0 for the paper.  If we ever experiment with it, make into a slider.
;;            knowledge-transfer          ;; for every item, the probability that the parent will teach the child

;;            World size for submitted HBES figures is 85 x 85 with patches of 8.0, font size 10.  A smaller world runs faster, but the results
;;                  have higher variance since the effects are all probabilistic / population-based.


globals [
  extra-list                  ;; holds the values for the different types of food
  regular                     ;; holds the value for the regular type of food, accesible to all
  show-knowledge
  p-knowhow                   ;; the chance that a turtle will know how to exploit a new foodtype at birth (FIXME should be a slider)
  num-special-food-strat      ;; num-food-strat - 1, often useful.
  expected-graph-max          ;; what we expect the Y axis to run to on the big combined plot
  foodstrat-graph-const       ;; multiplier based on num-food-strat for the combined plot
  tc                          ; social turtle colour
  ktc                         ; turtles-that-know-something-you-are-looking-at colour
  subpops
  subpops-patches
]


patches-own [ here-list ]   ;;hold a value describing the type of food that is on this patch, -1 if empty

turtles-own [
  language
  homesubpop
  destsubpop
  lastsubpop
  migrating
]


to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-globals
  setup-patches
  setup-agents
end

to setup-globals
  set expected-graph-max 8000       ;; hard coded from looking at graphs
  set regular 5                     ;;;default food's value, this could also be user defined.

  set extra-list (n-values num-special-food-strat [ (regular * 2) ])  ;; special are worth twice as much
  set extra-list (fput regular extra-list)

  set show-knowledge 0
  set p-knowhow 0.05        ;; this is a significant value in the simulation, the probability an agent learns something on its own.  Should be a slider.
  set tc 97                 ;; color for ignorant turtles when using the "show knowledge" buttons
  set ktc 125               ;; color for turtles who know what you want to check on, as per previous line
;  set knowledge-transfer 0   ; see comment about this at the top of the file.  Variable not used now.

  set subpops []
  repeat subpop-count [set subpops lput randsubpop subpops]
  set subpops-patches ( patch-set ( map [x -> patch (item 0 x) (item 1 x)] subpops ) )

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;patches
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; at setup time, we run what happens normally a few times to get some food grown up
to setup-patches
  ask patches [
    ifelse(any? subpops-patches in-radius (subpop-radius)) [
      set pcolor 41
    ][
      set pcolor 42
    ]
  ]
  ask subpops-patches [ set pcolor (60) ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;turtles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report randsubpop
  report list round ((random world-width) - world-width / 2) round ((random world-height) - world-height / 2)
end

to setup-agents
  foreach subpops setup_subpop
end

to setup_subpop [subpop]

  crt turtles-per-pop [setup_turtle (subpop)]
end


to setup_turtle[subpop]
  setxy (random-normal 0 subpop-radius / 3 + item 0 subpop)                 ;; randomize the turtle locations
     (random-normal 0 subpop-radius / 3  + item 1 subpop)
  set language []
  repeat language-count [set language lput 0.00001 language]
  set language replace-item 0 language 1
  set color tc
  set homesubpop subpop
  set destsubpop false
  set lastsubpop patch (item 0 subpop) (item 1 subpop)
  set migrating false
  update-color
end


to go
  tick
  ask (turtles) [
    ;take-food
    ;if (random energy) > 30 [give-birth ]   ; "30" should really be a variable too; this is bad style to bury a parameter like this. Determines amount of investment per child
    ;set energy (energy - 1)
    move-somewhere
    ;set age (age + 1)
    ;live-or-die
    communicate

  ]
  ask (turtles) [
  ]

  if remainder ticks 8 = 0 [update-plot]   ; only update plots one tick in 8.  Note you can comment this out to make it run faster too.
                                           ; if (count turtles = 0) [(show (word "turtles became extinct at:" ticks)) stop] ;; never happens so excised for speed
                                           ;  if (ticks = simulation-runtime) [(show "time's up!") stop]
end

to communicate
  let lang language
  ask one-of turtles in-radius broadcast-radius [talkwith lang]
end

to talkwith [otherlang]
  let intermediate (map get_lang language otherlang)
  if (random-float 100 < alpha)[
    let index random (length language)
    ;pick random index in language, calculate a random value from its current value and beta using normal distribution and replace the index with the random value
    let new_value random-normal (item index intermediate) beta
    set intermediate replace-item  index intermediate (max (list new_value 0.00001))
  ]
  let meaninter sum intermediate
  set language map [x -> x / meaninter] intermediate
  update-color
end

to update-color
  set color (position (max language) language + 1) * 10 + 5
end


to-report get_lang [value1 value2]
  if (value1 + value2 = 0.00002) [
    report 0.00001
  ]
  report max (list random-normal ((value1 + value2) / 2) beta 0.00001)
end

;;;;;;;;;;HOW TO MOVE;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; two parmeters from interface affect this
;;            run-dist          ;; approx distance moved per turn , see below
;;            travel-mode       ;; exact distance; levi flight; smooth distribution; or warp
to move-somewhere
  let near subpops-patches in-radius subpop-radius

  ifelse (migrating)[ ;; if migrating
    if(any? near and one-of near = destsubpop)[ ;; if near destination
      set lastsubpop one-of near
      set migrating false
    ]
  ][
    ifelse(random-float 100 < migration-chance)[ ;; if migrate
      set destsubpop one-of subpops-patches
      set migrating true
      face destsubpop
    ][;; if at home
      ifelse(not any? near)[
        face lastsubpop
        rt (random (90) - 45)
      ][
        rt random 360
      ]
    ]
  ]

  move-forward
end

to-report inradiusofpop
  report any? subpops-patches in-radius subpop-radius
end

to move-forward
  ifelse (travel-mode = "warp") [
    warp
  ][; else not warp
    fd ifelse-value (travel-mode = "gamma distribution") [
      gamma-flight run-dist ; Was Levy Flight -- see Edwards et al 2007
    ][
      ifelse-value (travel-mode = "exact distance") [
        run-dist
      ][
        random-float run-dist ; not exact, so else "smooth distribution"
      ]
    ] ; not gamma-flight
  ] ; not warp
end

to warp
  setxy (random world-width) (random world-height);; randomize the turtle locations
end

; this is all from Edwards et al 2007 (more natural than Levy Flight) via Dr. Lowe
to-report gamma-flight [len]
  let mn len / 2
  let gm (len ^ 2) / 12  ; yes I know the parens should be redundant
  let delta (mn ^ 2 ) / gm
  let lambda mn / gm
  ; let out 0 ; for debugging -- normally report directly

  ;alpha and lambda are what netlogo calls its gamma parameters, but they don't document what they really are.
  ;alpha is really shape, and lambda is really rate.

  report (random-gamma delta lambda)
  ;output-print out  ; for debugging, delete later
  ;report out

end


;;;;;;;;;; DISPLAY ;;;;;;;;;;;;;;;;;;;;;;
;; every time the flip-button is pressed
;; the value of show-knowledge is incremented by one untill its greater then the
;; number of different things in the environment, then it is set back to 1
;; the value of show-knowledge corresponds to the turtles' knowledge-slots

;to flip-color
;
;if (num-special-food-strat != 0)
; [ set show-knowledge (show-knowledge + 1)
;   if show-knowledge > num-special-food-strat [set show-knowledge 1]
;   ask turtles [ update-looks-knowhow ]
; ]
;end

;to knowledge-gradient
;
;set show-knowledge (num-special-food-strat + 42)
;ask turtles [ update-looks-gradient ]
;end

;to update-looks-knowhow
;ifelse (show-knowledge > num-special-food-strat) [ update-looks-gradient ]
;                                                 [ set color ifelse-value (item (show-knowledge - 1) knowhow = 1)[ktc][tc] ]
;end

;to update-looks-gradient
;let k (sum knowhow)
;set color ifelse-value (k = 0)[tc] [ifelse-value
;                       (k = 1)[106] [ifelse-value
;                       (k = 2)[116 ] [ifelse-value
;                       (k = 3)[126] [ifelse-value
;                       (k = 4)[136] ; k > 4
;                              [9] ]]]]
;
;end

;to update-patches-food
;set color (((only-one (item (show-knowledge - 1) (butfirst (herelist)))) * 10 * show-knowledge) + 14 )
;end

to color-off
set show-knowledge 0
set color tc
end



;;;;;;;;;;;;;;;UTILITIES, AUXILLARY REPORTERS AND PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; some of these were used only in early analysis, might be fun for others.

;;takes 2 lists and outputs one list that is 'adjusted'
;;the list describing the food available at a certain patch is
;;adjusted according to the list describing turtle knowhow
;; assumes turtle ate everything it knew how to eat!
;;adds 1 to item n of list l
to-report add-food [n l]
report (replace-item n l ((item n l) + 1 ) )
end

;;takes a list and returns the list of non-zero item-numbers
;n is the counter
to-report non-zero [l n]
if l = [] [report []]
ifelse (first l = 1) [report fput n (non-zero butfirst l (n + 1))] [report non-zero butfirst l (n + 1)]
end


;;sum over lots of lists
to-report sum-list [lijst-van-lijsten]
if (lijst-van-lijsten = []) [report []]
report sum2 (first lijst-van-lijsten) (sum-list (but-first lijst-van-lijsten))
end

;;sum over 2 lists
to-report sum2 [list1 list2]
if (list2 = []) [report list1]
report (map [ [?1 ?2] -> ?1 + ?2 ] list1 list2)
end

to-report safe-mean[lll]
  ifelse(length lll > 0)[report mean lll][report 0]
end

;to-report avg-know
;  report safe-mean [knowhow] of turtles
;end

to-report field
report (world-width  * world-height)
end

;reports 1 if n > 0
to-report only-one [n]
ifelse (n > 0) [report 1] [report 0]
end

;returns some information on the knowledge spread and the amount of food
;to show-values
;let soc-turtles (turtle-set )
;let n 0
;  let t 0
;
;set n 0
;set t ((count soc-turtles) / 100)
;print (word "time: " ticks ", agents: " round (t * 100))
;repeat num-special-food-strat
;    [ print ( word
;               count soc-turtles with [ item n knowhow = 1]
;               " agents know item " (n + 1)
;               " (" precision ((count soc-turtles with [ item n knowhow = 1]) / t) 3 "%)")
;      print ( word
;               count soc-turtles with [ (sum knowhow) = (n + 1) ]
;               " agents know " (n + 1) " items"
;               " (" precision ((count soc-turtles with [ sum knowhow = (n + 1) ]) / t) 3 "%)")
;      print ( word
;               count patches with [ item (n + 1) here-list = 1 ]
;               "patches have food type " (n + 1))
;      set n (n + 1)
;               ]
;print (word (count patches with [first here-list = 1]) " patches with regular food")
;print (word (count soc-turtles with [sum knowhow =  0]) " agents know nothing")
;print (word "total food = " (((count patches with [first here-list = 1]) * 5)
;                            + ((count patches with [sum butfirst here-list = 1]) * 10)))
;print (word "patches with regular food " (count patches with [first here-list = 1])
;            " (" precision (((count patches with [first here-list = 1]) / field) * 100) 2 "%)")
;end


;;;;;;;;;;;;;;;THE PLOTTING PART;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-plot
;update-plot-all
;update-plot-offspring
; update-speaking-cost-over-time
;update-type-of-food
end

;to update-plot-all
;let c 0
;;locals [c r]
;set-current-plot "plot-all"
;set-current-plot-pen "turtles"
;  plot count turtles
;set-current-plot-pen "reg-food"
;  plot ceiling ( 0.2 * (count patches with [ here-list = 1 ]))
;set-current-plot-pen "know"
;  if (count turtles != 0) [ plot ceiling (100 * (avg-know))]
;end

;plots the age of the turtles having offspring
to update-plot-offspring
set-current-plot "offspring"
set-current-plot-pen "age"
set-plot-pen-mode 2
end
@#$#@#$#@
GRAPHICS-WINDOW
376
20
1192
517
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
1
1
-50
50
-30
30
0
0
1
ticks
30.0

BUTTON
25
10
115
49
setup
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
143
12
206
45
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
1

PLOT
1410
111
1906
456
plot-all
NIL
NIL
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"turtles" 1.0 0 -13345367 true "" ""
"reg-food" 1.0 0 -2674135 true "" ""
"know" 1.0 0 -10899396 true "" ""
"spec-food" 1.0 0 -955883 true "" ""
"prop. talk" 1.0 0 -7500403 true "" ""

BUTTON
243
13
313
46
go 1x
go
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
12
238
168
271
run-dist
run-dist
0
5
0.5
0.25
1
NIL
HORIZONTAL

CHOOSER
198
236
335
281
travel-mode
travel-mode
"exact distance" "gamma distribution" "smooth distribution" "warp"
1

SLIDER
11
117
199
150
turtles-per-pop
turtles-per-pop
0
1000
140.0
10
1
NIL
HORIZONTAL

SLIDER
11
276
175
309
broadcast-radius
broadcast-radius
0
10
1.1
.1
1
NIL
HORIZONTAL

SLIDER
9
75
181
108
start-know
start-know
1.0
2.0
1.0
0.00001
1
NIL
HORIZONTAL

SLIDER
11
194
183
227
alpha
alpha
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
187
194
359
227
beta
beta
0
.9
0.07
0.01
1
NIL
HORIZONTAL

SLIDER
11
153
183
186
subpop-count
subpop-count
1
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
188
153
360
186
subpop-radius
subpop-radius
0
10
2.9
0.1
1
NIL
HORIZONTAL

SLIDER
85
436
285
469
migration-chance
migration-chance
0
100
0.166
1
1
%
HORIZONTAL

SLIDER
184
288
356
321
migration-chance
migration-chance
0
1
0.166
0.001
1
NIL
HORIZONTAL

SLIDER
192
79
364
112
language-count
language-count
0
10
3.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model starts from an existing model (by Cace & Bryson) showing that altruistic communication is adaptive.  This model looks at the reasons why, if this is so, it adapts so rarely, or in such limited ways.

My hypothesis is that too-rapid communication of behaviour leads to ecologically unstable strategies.  This is a seperate but not exclusive explanation from the Boyd & Richerson claim that the problem is just the rate of change in the environment drives demand for individual vs. cultural learning.  In principle, there is no reason that cultures couldn't adapt *faster* than individuals.

Optimizations

Make fast verison where food always depletes, agents never show knowledge

## SPECIAL NOTE

This has not yet been submitted as a paper.

## HOW IT WORKS

*life and death
Agents are hatched inheriting only their parents breed, talker or silent
When they run out of energy or reach the maximum age, the agents die.

*communication
At every time-step the communicators will pick one thing they know of and communicate this to the turtles around them. As a result the others will be able to eat the food they now learned about.
They also communicate to their offspring. The knowledge-transfer variable determines the probability for every single bit of parental know-how being dispensed to the offspring.

*feeding
When the turtles that know are at a patch with the food they know of, they get more energy.

*patches
The user defines the rate at which food is added to the environment. Every patch has the probability of (replace-rate/1000) of being filled with food.

*the walkabout
The turtles walk around according to levi flight. Foraging animals and foraging optimised agents, regardsless of their implementation (genetic algorithms, NN) do the levi flight.
The probability of a step of lenghth l is P(l):
P(l) = 1/z * 1/l^mu
z is a normalizing constant.
mu is a value between 1 and 3. For this model i have taken 1/mu= 0.3.

The turns are just random.

## HOW TO USE IT

## SETUP_BUTTONS:

+ replace-rate-regular: replace rate of the regular food
+ replace-rate-special: replace rate of the special food
+ no things: the number of types of food: there is always 1 type, the regular.
+ num-turtles: number of turtles in the model. The number of turtles the model will eventually settle down to wil depend on its size and on the amount of food.
+ p-communicators: the initial probability of a turtle being a talker
+ p-knowhow: probability, per bit of knowledge, of a turtle knowing something
+ knowledge-transfer: the probability for every single bit of parental know-how being dispensed to the offspring

## DISPLAY:

+ flip: every time the flip-button is pressed it colours all turtles with a 1 in a different knowledge-slot in a different colour then the turtles that have a 0 in that particular knowledge-slot.
+ colour-off: colours all turtles the same
+ show-values: shows the current values for some interesting properties (like the number of agents knowing about food type x)

## RELATED MODELS

In 2007 JJB branched this model from the archival version of the FreeInfo model that was submitted to Nature in April 2007.  That model was derived from an early version of the model Ivana Cace used for her diploma / MSc dissertation at Utrecht.

## CREDITS AND REFERENCES

Environment:
The algorithm for putting food in the environment is taken from the Rabbits Grass Weeds model.
Copyright 1998 by Uri Wilensky.  All rights reserved.  See
; http://ccl.northwestern.edu/netlogo/models/RabbitsGrassWeeds
; for terms of use.

Levi-flight
see:
Universal Properties of Adaptive Behaviour
Michel van Dartel Eric Postma Jaap van den Herik
IKAT, Universiteit Maastricht, P.O. Box 616 6200 MD Maastricht

But the idea (mine and probably theirs too) comes from a talk at the BNAIS conference in Utrecht some years ago, 2001?
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

loud
false
15
Circle -1 true true 4 9 285
Rectangle -16777216 true false 118 46 179 246
Rectangle -1 true true 105 24 189 51
Rectangle -1 true true 105 31 196 56
Rectangle -1 true true 99 33 189 60
Rectangle -1 true true 108 193 205 205
Rectangle -1 true true 96 193 197 210
Rectangle -1 true true 174 38 201 267
Rectangle -1 true true 109 34 123 258
Rectangle -1 true true 102 26 125 246
Rectangle -1 true true 171 44 191 254
Rectangle -16777216 true false 125 36 170 80
Rectangle -16777216 true false 125 243 170 268
Rectangle -1 true true 104 195 193 218
Rectangle -1 true true 172 15 172 21
Rectangle -1 true true 169 29 192 276
Rectangle -1 true true 90 197 187 223
Rectangle -16777216 true false 125 219 168 229
Rectangle -16777216 true false 157 219 168 232
Rectangle -16777216 true false 158 219 169 241
Rectangle -16777216 true false 124 214 168 224
Rectangle -16777216 true false 160 214 171 215
Rectangle -16777216 true false 158 215 171 224
Rectangle -1 true true 168 195 188 227
Rectangle -16777216 true false 164 214 168 239
Rectangle -16777216 true false 164 216 172 228
Rectangle -16777216 true false 165 209 171 223
Rectangle -1 true true 169 202 185 241
Rectangle -1 true true 149 198 185 213
Rectangle -1 true true 159 203 175 213
Rectangle -1 true true 160 204 175 213
Rectangle -1 true true 159 207 176 214
Rectangle -1 true true 109 205 124 228
Rectangle -1 true true 116 200 124 229
Rectangle -1 true true 111 206 125 230

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

predator
true
0
Polygon -2064490 true false 270 255 225 180 105 180 45 255 135 285 165 285
Polygon -2064490 true false 165 135 165 75 270 60 225 120 165 165 165 135
Polygon -2064490 true false 135 135 135 75 30 60 75 120 135 165 135 135

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

silent
false
15
Polygon -1 true true 69 6 4 64 200 278 275 210
Polygon -1 true true 79 276 17 216 203 7 276 67

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="HBES-selective-pressure" repetitions="32" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="16000"/>
    <metric>count talker</metric>
    <metric>count silent</metric>
    <enumeratedValueSet variable="simulation-runtime">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-depletes?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-proportion-altruists">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lifespan">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="travel-mode">
      <value value="&quot;smooth distribution&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-replacement-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-num-turtles">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freq-of-mutation">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-of-special-foods">
      <value value="-3"/>
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-dist">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="broadcast-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-food-strat">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HBES-indi-nomut" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="14000"/>
    <metric>count talker</metric>
    <metric>count silent</metric>
    <metric>safe-mean [sum knowhow] of talker</metric>
    <metric>safe-standard-deviation [sum knowhow] of talker</metric>
    <metric>safe-mean [sum knowhow] of silent</metric>
    <metric>safe-standard-deviation [sum knowhow] of silent</metric>
    <metric>avg-silent-k 1</metric>
    <metric>sd-silent-k 1</metric>
    <metric>count-silent-k 1</metric>
    <metric>avg-talker-k 1</metric>
    <metric>sd-talker-k 1</metric>
    <metric>count-talker-k 1</metric>
    <metric>avg-silent-k 2</metric>
    <metric>sd-silent-k 2</metric>
    <metric>count-silent-k 2</metric>
    <metric>avg-talker-k 2</metric>
    <metric>sd-talker-k 2</metric>
    <metric>count-talker-k 2</metric>
    <metric>avg-silent-k 3</metric>
    <metric>sd-silent-k 3</metric>
    <metric>count-silent-k 3</metric>
    <metric>avg-talker-k 3</metric>
    <metric>sd-talker-k 3</metric>
    <metric>count-talker-k 3</metric>
    <metric>avg-silent-k 4</metric>
    <metric>sd-silent-k 4</metric>
    <metric>count-silent-k 4</metric>
    <metric>avg-talker-k 4</metric>
    <metric>sd-talker-k 4</metric>
    <metric>count-talker-k 4</metric>
    <metric>avg-silent-k 5</metric>
    <metric>sd-silent-k 5</metric>
    <metric>count-silent-k 5</metric>
    <metric>avg-talker-k 5</metric>
    <metric>sd-talker-k 5</metric>
    <metric>count-talker-k 5</metric>
    <metric>avg-silent-k 6</metric>
    <metric>sd-silent-k 6</metric>
    <metric>count-silent-k 6</metric>
    <metric>avg-talker-k 6</metric>
    <metric>sd-talker-k 6</metric>
    <metric>count-talker-k 6</metric>
    <metric>avg-silent-k 7</metric>
    <metric>sd-silent-k 7</metric>
    <metric>count-silent-k 7</metric>
    <metric>avg-talker-k 7</metric>
    <metric>sd-talker-k 7</metric>
    <metric>count-talker-k 7</metric>
    <metric>avg-silent-k 8</metric>
    <metric>sd-silent-k 8</metric>
    <metric>count-silent-k 8</metric>
    <metric>avg-talker-k 8</metric>
    <metric>sd-talker-k 8</metric>
    <metric>count-talker-k 8</metric>
    <enumeratedValueSet variable="alert-bias">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-runtime">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-depletes?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-proportion-altruists">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lifespan">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="travel-mode">
      <value value="&quot;smooth distribution&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-replacement-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-num-turtles">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freq-of-mutation">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-of-special-foods">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-dist">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="broadcast-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-food-strat">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HBES-indi-mut40" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="14000"/>
    <metric>count talker</metric>
    <metric>count silent</metric>
    <metric>safe-mean [sum knowhow] of talker</metric>
    <metric>safe-standard-deviation [sum knowhow] of talker</metric>
    <metric>safe-mean [sum knowhow] of silent</metric>
    <metric>safe-standard-deviation [sum knowhow] of silent</metric>
    <metric>avg-silent-k 1</metric>
    <metric>sd-silent-k 1</metric>
    <metric>count-silent-k 1</metric>
    <metric>avg-talker-k 1</metric>
    <metric>sd-talker-k 1</metric>
    <metric>count-talker-k 1</metric>
    <metric>avg-silent-k 2</metric>
    <metric>sd-silent-k 2</metric>
    <metric>count-silent-k 2</metric>
    <metric>avg-talker-k 2</metric>
    <metric>sd-talker-k 2</metric>
    <metric>count-talker-k 2</metric>
    <metric>avg-silent-k 3</metric>
    <metric>sd-silent-k 3</metric>
    <metric>count-silent-k 3</metric>
    <metric>avg-talker-k 3</metric>
    <metric>sd-talker-k 3</metric>
    <metric>count-talker-k 3</metric>
    <metric>avg-silent-k 4</metric>
    <metric>sd-silent-k 4</metric>
    <metric>count-silent-k 4</metric>
    <metric>avg-talker-k 4</metric>
    <metric>sd-talker-k 4</metric>
    <metric>count-talker-k 4</metric>
    <metric>avg-silent-k 5</metric>
    <metric>sd-silent-k 5</metric>
    <metric>count-silent-k 5</metric>
    <metric>avg-talker-k 5</metric>
    <metric>sd-talker-k 5</metric>
    <metric>count-talker-k 5</metric>
    <metric>avg-silent-k 6</metric>
    <metric>sd-silent-k 6</metric>
    <metric>count-silent-k 6</metric>
    <metric>avg-talker-k 6</metric>
    <metric>sd-talker-k 6</metric>
    <metric>count-talker-k 6</metric>
    <metric>avg-silent-k 7</metric>
    <metric>sd-silent-k 7</metric>
    <metric>count-silent-k 7</metric>
    <metric>avg-talker-k 7</metric>
    <metric>sd-talker-k 7</metric>
    <metric>count-talker-k 7</metric>
    <metric>avg-silent-k 8</metric>
    <metric>sd-silent-k 8</metric>
    <metric>count-silent-k 8</metric>
    <metric>avg-talker-k 8</metric>
    <metric>sd-talker-k 8</metric>
    <metric>count-talker-k 8</metric>
    <enumeratedValueSet variable="simulation-runtime">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-depletes?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-proportion-altruists">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lifespan">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="travel-mode">
      <value value="&quot;smooth distribution&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-replacement-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-num-turtles">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freq-of-mutation">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-of-special-foods">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-dist">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="broadcast-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-food-strat">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HBES-indi-mut50" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="14000"/>
    <metric>count talker</metric>
    <metric>count silent</metric>
    <metric>safe-mean [sum knowhow] of talker</metric>
    <metric>safe-standard-deviation [sum knowhow] of talker</metric>
    <metric>safe-mean [sum knowhow] of silent</metric>
    <metric>safe-standard-deviation [sum knowhow] of silent</metric>
    <metric>avg-silent-k 1</metric>
    <metric>sd-silent-k 1</metric>
    <metric>count-silent-k 1</metric>
    <metric>avg-talker-k 1</metric>
    <metric>sd-talker-k 1</metric>
    <metric>count-talker-k 1</metric>
    <metric>avg-silent-k 2</metric>
    <metric>sd-silent-k 2</metric>
    <metric>count-silent-k 2</metric>
    <metric>avg-talker-k 2</metric>
    <metric>sd-talker-k 2</metric>
    <metric>count-talker-k 2</metric>
    <metric>avg-silent-k 3</metric>
    <metric>sd-silent-k 3</metric>
    <metric>count-silent-k 3</metric>
    <metric>avg-talker-k 3</metric>
    <metric>sd-talker-k 3</metric>
    <metric>count-talker-k 3</metric>
    <metric>avg-silent-k 4</metric>
    <metric>sd-silent-k 4</metric>
    <metric>count-silent-k 4</metric>
    <metric>avg-talker-k 4</metric>
    <metric>sd-talker-k 4</metric>
    <metric>count-talker-k 4</metric>
    <metric>avg-silent-k 5</metric>
    <metric>sd-silent-k 5</metric>
    <metric>count-silent-k 5</metric>
    <metric>avg-talker-k 5</metric>
    <metric>sd-talker-k 5</metric>
    <metric>count-talker-k 5</metric>
    <metric>avg-silent-k 6</metric>
    <metric>sd-silent-k 6</metric>
    <metric>count-silent-k 6</metric>
    <metric>avg-talker-k 6</metric>
    <metric>sd-talker-k 6</metric>
    <metric>count-talker-k 6</metric>
    <metric>avg-silent-k 7</metric>
    <metric>sd-silent-k 7</metric>
    <metric>count-silent-k 7</metric>
    <metric>avg-talker-k 7</metric>
    <metric>sd-talker-k 7</metric>
    <metric>count-talker-k 7</metric>
    <metric>avg-silent-k 8</metric>
    <metric>sd-silent-k 8</metric>
    <metric>count-silent-k 8</metric>
    <metric>avg-talker-k 8</metric>
    <metric>sd-talker-k 8</metric>
    <metric>count-talker-k 8</metric>
    <enumeratedValueSet variable="simulation-runtime">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-depletes?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-proportion-altruists">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lifespan">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="travel-mode">
      <value value="&quot;smooth distribution&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-replacement-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-num-turtles">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freq-of-mutation">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-of-special-foods">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-dist">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="broadcast-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-food-strat">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ACS-broadcast-vs-run" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="12000"/>
    <metric>count talker</metric>
    <metric>count silent</metric>
    <enumeratedValueSet variable="start-num-turtles">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freq-of-mutation">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-dist">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-of-special-foods">
      <value value="-2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-food-strat">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-depletes?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lifespan">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-replacement-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="travel-mode">
      <value value="&quot;levi flight&quot;"/>
      <value value="&quot;smooth distribution&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-runtime">
      <value value="17000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="broadcast-radius">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-proportion-altruists">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HBES-indi-test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1400"/>
    <metric>count talker</metric>
    <metric>count silent</metric>
    <metric>safe-mean [sum knowhow] of talker</metric>
    <metric>safe-standard-deviation [sum knowhow] of talker</metric>
    <metric>safe-mean [sum knowhow] of silent</metric>
    <metric>safe-standard-deviation [sum knowhow] of silent</metric>
    <metric>avg-silent-k 1</metric>
    <metric>sd-silent-k 1</metric>
    <metric>count-silent-k 1</metric>
    <metric>avg-talker-k 1</metric>
    <metric>sd-talker-k 1</metric>
    <metric>count-talker-k 1</metric>
    <metric>avg-silent-k 2</metric>
    <metric>sd-silent-k 2</metric>
    <metric>count-silent-k 2</metric>
    <metric>avg-talker-k 2</metric>
    <metric>sd-talker-k 2</metric>
    <metric>count-talker-k 2</metric>
    <metric>avg-silent-k 3</metric>
    <metric>sd-silent-k 3</metric>
    <metric>count-silent-k 3</metric>
    <metric>avg-talker-k 3</metric>
    <metric>sd-talker-k 3</metric>
    <metric>count-talker-k 3</metric>
    <metric>avg-silent-k 4</metric>
    <metric>sd-silent-k 4</metric>
    <metric>count-silent-k 4</metric>
    <metric>avg-talker-k 4</metric>
    <metric>sd-talker-k 4</metric>
    <metric>count-talker-k 4</metric>
    <metric>avg-silent-k 5</metric>
    <metric>sd-silent-k 5</metric>
    <metric>count-silent-k 5</metric>
    <metric>avg-talker-k 5</metric>
    <metric>sd-talker-k 5</metric>
    <metric>count-talker-k 5</metric>
    <metric>avg-silent-k 6</metric>
    <metric>sd-silent-k 6</metric>
    <metric>count-silent-k 6</metric>
    <metric>avg-talker-k 6</metric>
    <metric>sd-talker-k 6</metric>
    <metric>count-talker-k 6</metric>
    <metric>avg-silent-k 7</metric>
    <metric>sd-silent-k 7</metric>
    <metric>count-silent-k 7</metric>
    <metric>avg-talker-k 7</metric>
    <metric>sd-talker-k 7</metric>
    <metric>count-talker-k 7</metric>
    <metric>avg-silent-k 8</metric>
    <metric>sd-silent-k 8</metric>
    <metric>count-silent-k 8</metric>
    <metric>avg-talker-k 8</metric>
    <metric>sd-talker-k 8</metric>
    <metric>count-talker-k 8</metric>
    <enumeratedValueSet variable="simulation-runtime">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-depletes?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-proportion-altruists">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lifespan">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="travel-mode">
      <value value="&quot;smooth distribution&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-replacement-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-num-turtles">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freq-of-mutation">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-of-special-foods">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-dist">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="broadcast-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-food-strat">
      <value value="8"/>
    </enumeratedValueSet>
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
0
@#$#@#$#@
