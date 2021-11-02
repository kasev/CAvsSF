
globals [population-size memory-size social-memory-capacity num-sites site-capacity percentage-of-headless-inovators percentage-of-traditionalists fresher-reminiscence-matters-more balance-traditionalists? debug-output ritual-sites home-site max-pop-per-site state-of-world after-headless-state-of-world after-traditionalists-state-of-world redones yellowones r-head r-tradi y-head y-tradi redonestotal yellowonestotal prosocialeffectusage nonsocialeffectusage show-network-of-individual _recording-save-file-name]

;; coded in netologo v5.3.1.
;; v0.4a (from 0.3.2.)
;;        - major reimplementation of the model
;;        - end of subpopulations, end of types of agents
;;        - agents have strategies of behavior, can think, i.e. try to optimize their behavior (followers) and act
;;             - three reactions on experience (none-superchaotic, none-superstable, optmizing)
;;        - there is constant ratio of strategies [parameter] in population, but agents get a random strategy each tick
;;        - strategy is a strategy for "happinness", answer on a question how to be act to be happy
;;        - QUIRK :  the satisfaction is population based and is constant in the ratio of unhappy (changers - innovators), happy (non-changers - traditionalist) and context-based happy (follow)

;;???     - follower strategy is evaluated "at once", not follower after follower : will it significantly change the dynamics of the model?
;;        minor tweaks
;;          - deleted button and functionality "balance traditionalists"
;;
;; v0.3.2 - better visualisation of the selection dynamics
;;      - explorative visualisation of (part of) ego-network of one random agent (chosenOne)


;; general description
;; - distribution of agents to sites due to their strategies
;;   - headless-goers randomly, traditionalist go to last place, rest follow  by deciding algorithm
;; - there is fixed ratio (50% to 50%) of different ritual sites


turtles-own [ ;; as people
  visiting-site ;; site I am in (redundant, same as patch-at)
  strategy;; strategy to be satisfied I use  "","h","t","f"  "no strategy", "headless", "traditional", "follow"
  site-evaluation ;; social evaluation, list of marks
  wish-to-visit;;

  ;; EM = encounter memory
  EM-people-met  ;;  list of agentsets - agents from last encounter on ritual site, on 0 is list with last encounter
  EM-place-visited;;  list of agentsets - visited patches, on 0 is the last visited patch
  EM-used-strategies;; list of used strategies
  EM-used-site-evaluation;; list of used social evaluations of sites (marking of ritual site at tick before decision was made; relevant for follow strategy)

  my-last-place ;; last place agent visited
  my-last-encountered-quality;; last quality agent has encountered
  my-last-strategy;; my last used way of behavior

  chosenOne;;  special variable
  last-caffinity; ;;debug variable
]


links-own [
  EM-met ;; list of 0s and 1s; 1 = we have met in the tick, 0 = we have NOT met in the tick
]

patches-own [ ;; as ritual sites
  site-quality ;; "SF" or "CA"
  site-mark ;; evaluation of ritual site by agent, used in deciding algoritm (rewritten by each agent deciding process)
]




to globals-init

  set population-size 200
  set num-sites 10
  set memory-size 5 ;; how much encounters agent remembers
  set social-memory-capacity 150 ;; bottom-up constraint effecting also the "max members of one group", which makes the site-capacity not needed
                                 ;; it is NOT number of agents (aka dunbar number), see part 2 of ritual-activity procedure


  set site-capacity 100 ;;; top-down constraint for visitorss of one ritual site

  set percentage-of-headless-inovators 10
  set percentage-of-traditionalists 50

  set fresher-reminiscence-matters-more False   ;; different strenght of time-ordered memories on marking
  set balance-traditionalists? False

  set debug-output False

  set show-network-of-individual false

end




to setup
  clear-all
  globals-init

  ;;reporting variables initialisation
  set max-pop-per-site 0 ;; maximal population in one site, which the model produced
  set state-of-world n-values num-sites [0] ;; initialisation of list of participant-counts from ritual-sites

  ask patches [
   set site-quality ""
  ]
  set ritual-sites patches with [ritual-site?] ;; create n ritual sites from num-sites patches / code originally from "Party model" of Wilensky, U. (1997).
  set-default-shape turtles "person"
  set home-site patch 0 5 ;; define a home-site patch; place where agents are, when they are not in one of ritual-sites


  ;;distributing site-quality, half first quality, other half second quality
  let sorted-ritual-sites sort-on [pxcor] ritual-sites
  let counter 0
  let half floor(num-sites / 2)
  foreach sorted-ritual-sites [ ?1 ->
    set counter (counter + 1)
    ifelse (half >= counter)[
       ask ?1 [
       set site-quality "SF"
       set plabel-color yellow]
      ][
      ask ?1 [
      set site-quality "CA"
      set plabel-color red]
    ]

  ]

  ;; creating population of agents
  create-turtles population-size / 2 [
    set size 3
    set color white
    set visiting-site one-of ritual-sites with [site-quality = "SF"] ;; randomly visit on of the ritual places with prosocial quality
    move-to visiting-site
    ;;initiatlize turtle variables
    set strategy ""
    set site-evaluation []
    set EM-people-met []
    set EM-place-visited []
    set EM-used-strategies []
    set EM-used-site-evaluation []
    ;;set hidden? true
  ]
  create-turtles population-size / 2 [
    set size 3
    set color white
    set visiting-site one-of ritual-sites with [site-quality = "CA"];; randomly visit on of the ritual places with cognitive quality
    move-to visiting-site
    ;;initiatlize turtle variables
    set strategy ""
    set site-evaluation []
    set EM-people-met []
    set EM-place-visited []
    set EM-used-strategies []
    set EM-used-site-evaluation []
    ;;set hidden? true
  ]



  update-memory ;; creates an initial memory
  ;;debug-move-to-random-patch
  update-labels-setup ;; updates labels of ritual sites
  ;;return-to-home

  visualize-participants

  ;; optional : study network of individual agents
  ;;if show-network-of-individual [
    ;; choose chosenOne
  ;;  ask one-of turtles [ set chosenOne True set shape "star" set color red set size 6]
  ;;]


  reset-ticks

  ;;FOR EXPORT to VIDEO
  ;;export-interface (word "vexport/4/frame" but-first (word (100000 + ticks)) ".png")
  ;;export-world (word "wexport/1/tick" but-first (word (100000 + ticks)) ".dat")
end

;;*********************************
to go
  return-to-home

  ritual-activity
  update-memory
  update-labels-go

  visualize-participants
  update-links

  ;;FOR EXPORT to VIDEO
  ;;export-interface (word "vexport/4/frame" but-first (word (100000 + ticks)) ".png")
  ;;export-world (word "wexport/1/tick" but-first (word (100000 + ticks)) ".dat")

  tick

end



;;****************************************************************************************
;;****************************************************************************************
;; main procedure for distribution of agents to sites in each tick
;; has three parts:
;;   1) distribute strategies according to global parameter [there is constant distribution of satisfaction in population]
;;   2) evaluate and act the simple strategies (headless, traditional)
;;   3) evaluate complex strategies (follow)
;;   4) act the complex strategy (follow)
to ritual-activity

  ;; reporting variables
  set prosocialEffectUsage 0
  set nonsocialEffectUsage 0

  ;;***************************************  1 *******************************************
  distribute-strategies


  ;;***************************************  2 *******************************************
  ask turtles with [strategy = "h"] [
    ;;think-headless self
    act-headless self
  ]
  ;;reporting variables
  set r-head ca-site-visitors-count?
  set y-head sf-site-visitors-count?

  ask turtles with [strategy = "t"] [
    ;;think-traditional self
    act-traditional self
  ]
  ;;reporting variables
  set r-tradi ca-site-visitors-count? - r-head
  set y-tradi sf-site-visitors-count? - y-head

  ;;***************************************  3 *******************************************
  ;; creates evaluation of sites for decision making
  ask turtles with [strategy = "f"] [
    think-follow self
    ;;act-follow self
  ]

  ;;***************************************  4 *******************************************
  ;; acts upon evalutation
  ask turtles with [strategy = "f"] [
    act-follow self
  ]

end

;;************************************
to distribute-strategies
  let headless n-of floor((percentage-of-headless-inovators / 100) * population-size) turtles
  let traditional n-of floor((percentage-of-traditionalists / 100) * population-size) turtles with [not member? self headless]

  ask headless [
    set strategy "h"
    set color orange
  ]
  ask traditional [
    set strategy "t"
    set color blue
  ]

  ;;for rest of agents set strategy to complex strategy "follow"
  ask turtles with [strategy = ""] [
    set strategy "f"
    set color white
  ]
end

;;************************************
;; THINKING STRATEGIES
;;************************************
;;functions for strategies
to think-headless [agent]
  ask agent [
    ;;nothing
    set site-evaluation 0
  ]
end

to think-traditional [agent]
  ask agent [
    ;;nothing
    set site-evaluation 0
  ]
end


to think-follow [agent]

  ;; evaluate present moment vs past (which site offers the best experience according to memory)
  ask agent [
     let deciding-agent self
     let da-EM-people-met EM-people-met         ;; go to your memory of others
     let da-EM-place-visited EM-place-visited   ;; go to your memory of sites
     let da-se site-evaluation

     ;; constraining social memory to a limit defined by global variable - social-memory-capacity
     ;; takes into account the strenght of memory due its time distance from present
     let xposition 0 ;; encounter position in memory / list
     let social-sum 0
     let da-EM-people-met-constrained []


     ;;constraining has 2 dimensions governed by 2 parameters [memory-size],[social-memory-capacity]
     ;; 1) there is limit of depth of memory blocks (tick - encounter):  i.e. 5 [memory size] "RECENT X ticks is relevant"
         ;; realized in update-memory procedure
     ;; 2) there is limit of memory content, i.e.aka Dunbar limit [social memory capacity], "capacity of ego network"
     ;;   3) more recent memories are stronger > we distribute ego capacity to blocks of memory

     foreach da-EM-people-met [ ?1 -> ;; for each encounter(agentset of people agent has met) of full memory
       let agentset ?1
       let acount count agentset
       let coefficient 0
       if (xposition = 0) [set coefficient 3]  ;; last memory has the greatest strength, i.e. people from last encounter take more capacity of memory
       if (xposition = 1) [set coefficient 2]
       if (xposition >= 2) [set coefficient 1]
       set social-sum  social-sum + (acount * coefficient)
       if (social-sum < social-memory-capacity) [
         set da-EM-people-met-constrained lput agentset da-EM-people-met-constrained
       ]
       set xposition xposition + 1
     ]
     ;; simplifing could go around
     ;; 1. not use social memory capacity, just memory size
     ;; or 2.  use SMC and MS, but not ranking according to the position of memory block (ie. recent memories are stronger)


     ;;marking ritual sites due to placed headless and traditionalists, which deciding agent remembers
     ask ritual-sites[
       let site-coefficient 0
       let visiting-people other turtles-here
       let mark 0

       foreach da-EM-people-met-constrained [ ?1 -> ;; memories of deciding agent,
         let encounter ?1 ;; agentset from memory
         let mposition position encounter da-EM-people-met-constrained ;; position of agentset from memory

         let encounter-site item mposition da-EM-place-visited
         ask encounter-site [
           let encounter-site-quality site-quality
           if (encounter-site-quality = "SF")[
             set site-coefficient (1 + social-function-coeficient )
             set prosocialEffectUsage prosocialEffectUsage + 1
             ;;print (word "encounter memory coefficient change SF" ":" site-coefficient)
             ]
           if (encounter-site-quality = "CA")[
             set site-coefficient 1
             set nonsocialEffectUsage nonsocialEffectUsage + 1
             ;;print (word "encounter memory coefficient change CA" ":" site-coefficient)
             ]
         ]

         ask encounter [ ;; ask each agent in memorized encounter
           if (member? self visiting-people)[
             ifelse (fresher-reminiscence-matters-more) [set mark (mark + ((memory-size - mposition) * site-coefficient))]
             [ set mark (mark + (1 * site-coefficient)) ]
                        ]
         ]
       ]
       set site-mark mark
     ]

     ;;modify the existing marks (and their order) due to cognitive attraction coeficient strenght and agents cognitive affinity, which is total CA site experience in his memory
     ;;counting deciding agent's affinity to CA quality
     let caffinity 1
     foreach da-EM-place-visited [ ?1 ->
       let encounter ?1 ;; agentset from memory
       let encounter-quality ""
       ask ?1 [
         set encounter-quality site-quality
         ]
       let mposition position encounter da-EM-place-visited ;;
       if (encounter-quality = "CA") [
         set caffinity caffinity + (cognitive-attraction-coeficient * (memory-size - mposition))    ;; e.g.. 1 + 0.1 * 5
       ]
     ]
     ;;if (caffinity > 1) [print (word "caffinity" caffinity)]

     ;;cognitive attraction influence = affinity to attractive site
     ask ritual-sites [
       if (site-quality = "CA") [
         set site-mark site-mark * caffinity
       ]
     ]


     ;;creates an schema of evalution
     foreach sort-on [pxcor] ritual-sites [
       set da-se fput site-mark da-se
     ]

     ;;decide where to go
     ;;let choices sort-on [site-mark] ritual-sites with [count turtles-here < site-capacity] - USING SITE CAPACITY = OBSOLETE?
     let choices sort-on [site-mark] ritual-sites
     set wish-to-visit last choices

  ]
end

;;************************************
;; ACTING STRATEGIES
;;************************************

to act-headless [agent]
  ask agent [
    move-to one-of ritual-sites
  ]
end

to act-traditional [agent]
  ask agent [
    move-to my-last-place
  ]
end

to act-follow [agent]
  ask agent [
    move-to wish-to-visit
  ]
end



;;*********************************
to visualize-participants  ;; move agents so they are visible in columns over the ritual-site patches
  ;; spread vertically

  ask turtles with [my-last-strategy = "f"] [
    set heading   0
    fd 4                   ;; leave a gap
  while [any? other turtles-here] [
    if-else can-move? 2 [
      fd 1
    ]
    [ ;; else, if we reached the edge of the screen
      set xcor xcor - 1  ;; take a step to the left
      set ycor 0         ;; and move to the base a new stack
      fd 4
    ]
  ]
  ]

  ask turtles with [my-last-strategy = "t"] [
    set heading   0
    fd 4                   ;; leave a gap
  while [any? other turtles-here] [
    if-else can-move? 2 [
      fd 1
    ]
    [ ;; else, if we reached the edge of the screen
      set xcor xcor - 1  ;; take a step to the left
      set ycor 0         ;; and move to the base a new stack
      fd 4
    ]
  ]
  ]

  ask turtles with [my-last-strategy = "h"] [
    set heading   0
    fd 4                   ;; leave a gap
  while [any? other turtles-here] [
    if-else can-move? 2 [
      fd 1
    ]
    [ ;; else, if we reached the edge of the screen
      set xcor xcor - 1  ;; take a step to the left
      set ycor 0         ;; and move to the base a new stack
      fd 4
    ]
  ]
  ]

  ask turtles with [my-last-strategy != "t" and my-last-strategy != "h" and my-last-strategy != "f" ] [
    set heading   0
    fd 4                   ;; leave a gap
  while [any? other turtles-here] [
    if-else can-move? 2 [
      fd 1
    ]
    [ ;; else, if we reached the edge of the screen
      set xcor xcor - 1  ;; take a step to the left
      set ycor 0         ;; and move to the base a new stack
      fd 4
    ]
  ]
  ]

end


;;*********************************
to update-memory ;; update memory of each agents according to people and place in encounter

  ask ritual-sites [
    let place self
    ask turtles-here [

      let other-people other turtles-here
      set EM-people-met fput other-people EM-people-met
      set EM-place-visited fput place EM-place-visited
      set EM-used-strategies fput strategy EM-used-strategies
      set EM-used-site-evaluation fput site-evaluation EM-used-site-evaluation

      set my-last-place place
      set my-last-encountered-quality [site-quality] of place
      set my-last-strategy strategy

      ;;chosenOne code
      if (chosenOne = True) [
                 update-agent-network self
      ]

      ;;forgetting
      if (length EM-people-met > memory-size) [ set EM-people-met but-last EM-people-met]
      if (length EM-place-visited > memory-size) [ set EM-place-visited but-last EM-place-visited]

    ]

    ;;reporting
    let pcount count turtles-here
    if (pcount > max-pop-per-site)[ set max-pop-per-site pcount]

  ]

end


;;*********************************
to update-agent-network [hero]

  foreach EM-people-met [ ?1 ->
   let round-people ?1

   ask round-people [
     create-link-with hero [
       set EM-met []
       set color green
     ]

     ;;adding meeting
     ask my-links [
       ;;set color green
       set EM-met fput ticks EM-met
     ]

   ]

  ]

  ;;adding non-meetings
  ask links [
    let last-memory first EM-met
    if (last-memory != ticks) [
      set EM-met fput 0 EM-met
    ]
  ]

end


to-report take [n xs]
  report sublist xs 0 min list n (length xs)
end


to update-links

  ask links [
     let active-memory take memory-size EM-met
     let summ 0

     foreach active-memory [ ?1 ->
       set summ summ + ?1

     ]

     if (summ = 0)[
       set color black
     ]

     ;; 11, 10, 9, 8, 7 :  /     45/5 = 9 >  delitelne peti tak je to full
     ;;55, 54, 53, 52, 51, 50 / 265/5=53
     ;; if x4 - x5 = 1
     ;;    x3 - x4 = 1
     ;;    x2 - x3 = 1
     ;;    x1 - x2 = 1
     ;;

     if (summ > 0)[
       set color green
     ]
     if ((summ > 0) and (summ mod memory-size = 0))[
       set color red
     ]

  ]

end




;;*********************************
to return-to-home
  ask turtles [
    move-to home-site
    set visiting-site home-site
    set strategy ""
  ]
end


;;*********************************
to update-labels-setup
  let debug []
  ask ritual-sites [
    set plabel count turtles-here
  ]
  let rr sort-on [pxcor] ritual-sites
  foreach rr [ ?1 ->
    let rsite ?1
    ask rsite [
      if (debug-output) [print (word pxcor ":" pycor)]
      ]
    set debug lput (count turtles-on rsite) debug
  ]
  if (debug-output) [ print (word "setup" ":" debug)]
end

to update-labels-go
  let debug []
  set redones 0
  set yellowones 0

  ask ritual-sites [
    set plabel count turtles-here

    if (site-quality = "SF") [
      set yellowones yellowones + count turtles-here
      set yellowonesTotal yellowonesTotal + count turtles-here
      ]
    if (site-quality = "CA") [
      set redones redones + count turtles-here
      set redonesTotal redonesTotal + count turtles-here
      ]

  ]
  let rr sort-on [pxcor] ritual-sites
  foreach rr [ ?1 ->
    let rsite ?1
    set debug lput (count turtles-on rsite) debug
  ]
  if (debug-output) [print (word ticks ":" debug " after head:" after-headless-state-of-world " after trad:" after-traditionalists-state-of-world)]
  set state-of-world debug
end




;;**************************************** REPORT PROCEDURES ***********************************************

to-report report-network-to-csv [memory-depth]

  ask turtles [

  ]

end




to-report distribution-list?
  let dlist []
  let rr sort-on [pxcor] ritual-sites
  foreach rr [ ?1 ->
    let rsite ?1
    set dlist lput (count turtles-on rsite) dlist
  ]
  report dlist
end


to-report sf-site-visitors-count?
 let a 0
 ask ritual-sites with [site-quality = "SF"][
   set a a + (count turtles-here)
   ;;print a
   ;;print "AAA"
   ;;print count turtles-here
   ]
 report a
end

to-report ca-site-visitors-count?
 let a 0
 ask ritual-sites with [site-quality = "CA"][
   set a a + (count turtles-here)
   ]
 report a
end



;;*********************************
to-report ritual-site?  ;; patch procedure
  ;; if your pycor is 0 and your pxcor is where a group should be located,
  ;; then you're a group site.
  ;; In this model (0,0) is near the right edge, so pxcor is usually
  ;; negative.
  ;; first figure out how many patches apart the groups will be
  let site-interval floor (world-width / num-sites)

  report
    ;; all group sites are in the middle row
    (pycor = 0) and
    ;; leave a right margin of one patch, for legibility
    (pxcor <= 0) and
    ;; the distance between groups must divide evenly into
    ;; our pxcor
    (pxcor mod site-interval = 0) and
    ;; finally, make sure we don't wind up with too many groups
    (floor ((- pxcor) / site-interval) < num-sites)
end


to-report max-pop-per-site?
  report max-pop-per-site
end

;;*********************************
;;*********************************

to debug-move-to-random-patch
  ask turtles [
    move-to one-of patches
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
15
132
361
474
-1
-1
4.122
1
15
1
1
1
0
1
0
1
-80
1
-10
70
1
1
1
weeks
30.0

BUTTON
15
10
78
43
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
85
10
148
43
NIL
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

MONITOR
217
505
363
550
CAg (total sum of visits)
redonesTotal
17
1
11

MONITOR
16
505
159
550
SFg (total sum of visits)
yellowonesTotal
17
1
11

SLIDER
15
88
216
121
cognitive-attraction-coeficient
cognitive-attraction-coeficient
0
0.5
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
14
50
216
83
social-function-coeficient
social-function-coeficient
0
1
0.5
0.01
1
NIL
HORIZONTAL

PLOT
370
135
745
371
Sum of SFg vs CAg visits
Time in ticks
Total of participants
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot redonesTotal"
"pen-1" 1.0 0 -7171555 true "" "plot yellowonesTotal"

BUTTON
152
10
215
43
go
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

PLOT
371
374
745
494
 SFg vs CAg summed visits difference during one tick
Time
Sum of visitors in during one event
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -4079321 true "" "plot yellowones"
"pen-1" 1.0 0 -2674135 true "" "plot redones"

PLOT
368
10
745
130
Total difference between sum of visits (SFg minus CAg)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (yellowonesTotal - redonesTotal)"

TEXTBOX
238
32
388
107
Strategies\n\norange - RANDOM\nblue - CONSERVATIVE\nwhite - ADAPTIVE
12
0.0
1

@#$#@#$#@
[excerpt from "Modeling Cultural Transmission of Rituals in Silico: The advantages and pitfalls of agent-based vs. system dynamics models" paper, under review in Journal of Cognition and Culture]


# Overview
## Purpose

The model serves as a  theory-building conceptualization of the transmission dynamics of collective rituals inside a population of interacting individuals as driven by two non-deliberative decision-making factors – cognitive attraction and social function. It creates an idealized environment for a bottom-up cultural selection of two ritual forms reflecting the two factors. The model aims to show specific dynamics associated with the two factors, revealing ratcheting effect towards the ritual form characterized by cognitive attraction.

## Entities, State Variables, and Scales

The model consists of an environment of discrete ritual places divided into two even groups (“SFg, “CAg”). In these places a population of human agents  holds gatherings - encounters each turn. Each agent has constrained memory for ritual experiences gained from such encounters.  Each group of ritual places affects the experience differently.  The agent is bound to use one from three ritual experience seeking strategies (random, conservative and adaptive). The usage ratio of strategies is fixed in the population (10% random, 50% conservative, 40% adaptive) and for individual agents changes each turn randomly. 

There are two main exogenous drivers: social-function-coefficient or SFc (value 0 - 1) and cognitive-attraction-coefficient or CAc (value 0 - 0.1). They represent simple abstractions of targeted factors used to compute the outcome of the adaptive strategy while shifting the tendency to gather to at a ritual place from the respective group. Time moves in discrete ticks. At each tick a ritual encounter is held in one of the ritual places. In the model, each tick represents a time unit of a week. The model does not end up with any equilibrium state, due to the hardwired variation resulting from the constant presence of random experience seeking strategy. However, the configuration of the coefficient associated with the two factors can create a significant preference for one or other ritual form over time.

## Process Overview and Scheduling

Time is modelled in discrete steps – “ticks” – and the same process repeats each tick. At the beginning of each tick, each agent adopts one experience seeking strategy, by which acts. This strategy is randomly allocated along a fixed distribution (10% random, 50% conservative, 40% adaptive). The behavior driven by the adopted strategy results in choosing one ritual place and moving there. For the agent, this place becomes his ritual encounter place for that time step. The process of agent allocation differs according to the experience seeking strategy. Randomly acting agents choose a random place from all possible places. Conservatively acting agent chooses the same place as his last encounter place.  Agent with “adaptive” strategy computes his choice on the basis of his encounter memory and actual situation in ritual places – he tries to optimize his choice with an aim to maximize his ritual experience, i.e. to meet his “best” acquaintances, where best is the most known from previous encounters.  In this computation the two main driving factors come into play and influence decision making. At the end of the turn, every agent adds his actual encounter to his memory, where a number of previous encounters is already stored. 

The process of agent allocation differs according to the experience seeking strategy. Randomly acting agents choose a random place from all possible places. Conservatively acting agent chooses the same place as his last encounter place.  Agent with “adaptive” strategy computes his choice on the basis of his encounter memory and actual situation in ritual places – he tries to optimize his choice with an aim to maximize his ritual experience, i.e. to meet his “best” acquaintances, where best is the most known from previous encounters.  In this computation the two main driving factors come into play and influence decision making.

## Design Concepts

**Individual Decision Making** - Each agent does one decision in each tick, i.e. decides which from the all ritual places he wants to visit. For this he uses one of the experience seeking strategies (random, conservative, adaptive) (see below sections on “Agent memory” and “Experience seeking strategies computation”).
Learning - The agents form social relationships based on the ritual experience. This experience further influences the decision making during the experience seeking strategy with adaptive computation.

**Sensing** -  While located in a place during the ritual encounter, the agents sense and remember the present agents and the type of the respective ritual place. Further, when deciding according to the adaptive experience seeking strategy, the agents have an unrestricted view of the world in the sense that they have full access to the information about allocations of the already located agents (those who behave according to the random and conservative strategy during the given tick). 

**Interaction** - The interaction of agents is limited to sensing each other during the ritual encounter. In that sensing, the most basic social relationship (familiarity) is established and held in individual memory.

**Stochasticity** - The stochastic sources of the simulation variation are the 1) initialization, where agents get their first experience and 2) the random experience seeking strategy, which is followed by 10% agents each tick.

**Collective** - During the simulation, the agent becomes part of emergent collectives (networks of interconnected agents) based on his encounter experiences (memory). The analysis of these collectives is not part of this article.

**Heterogeneity** - The agents have the same probabilities to use one of the three strategies. But what differs is their ritual experience changing from tick to tick.
Observation - The measured output of the simulation is the total difference of visits between the two ritual group places. The outcome can have three different states: (1) The random variation beats the underlying forces of ritual activity and none of the group of ritual places representing the two ritual forms becomes significantly preferred, i.e. none of the group has more visits than the other; (2) the ritual places with SF quality have more visits; (3) the ritual places with CA quality have more visits. 

## Details
### Initialization

At the beginning, a population of 200 agents is randomly and evenly distributed over 10 ritual places and each agent forms his first encounter memory with the other agents at their ritual place. 

### Ritual activity
At each tick each agent choses a place of his ritual encounter using their experience seeking strategy, which is randomly distributed among the agents at the beginning of each tick. The assigned experience seeking strategy leads the agent to find an appropriate ritual place and to move there. The agents assigned with random and conservative strategies proceed first, the agents with adaptive strategy follow. The agents behaving according to the adaptive strategy base their decision upon their access to information about locations of the previously located agents behaving according to the random and conservative strategies. At the end of the tick the memory of agents is updated by the type of the ritual place and those encountered there.

### Agent memory
The agent memory is a fixed 5-positional stack filled with information about his past encounters, where the freshest memory is at the top of the stack and where each position represents one of the past ticks. When the stack exceeds 5, the most time distant memory is deleted. 

The memory consists of two parts, the ritual quality memory and social encounter memory. The first is responsible for remembering the ritual quality of the visited place, that is to which group of places the place belongs. The second is responsible for memorizing all individual agents which were present in the place during the encounter. Both parts are crucial for computing the values on which is based the adaptive experience seeking strategy.

The social encounter memory is constrained to limited capacity of 150 slots for memory of encounter with individual agents. More recent encounter memories hold more space in this memory than older onward. Formally represented, the count of agents from the most recent encounter is multiplied by 3; in the case of the second most recent encounter, the count of agents is multiplied by 2. In the case of older encounters, the count is represented in the memory as one by one.  As a result of this, the agents met over older encounters are pushed out of the memory as the memory capacity is depleted by those met more recently.  


### Experience seeking strategies computation

**Random** and **conservative** strategies follow simple heuristics. When adopting the random strategy, the agent chooses randomly from all possible places. In a conservative strategy, the agents move to the same ritual place that they occupied in the previous tick.

In the **adaptive** strategy, the agents decide by considering each ritual place in terms of its prospective encounter value, which consists of a combination of the social value (familiarity with agents located in the ritual places based on past encounters) and affinity for cognitive attraction value (see further). All ritual places are marked with the prospective ritual encounter value and the place with the highest mark is chosen and the agent moves there.

The marks of the ritual places are computed by measuring a fit between the content of agent’s memory (i.e. visited places and encountered agents over the last 5 ticks) and places visited by a proportion of agents using random or conservative strategies. Here the main two drivers (SFc and CAc) influence the computation in a different way.

The score of a ritual place is ascribed in several steps. First, the agent examines all ritual places and checks their visitors while comparing them with those which he holds in memory from previous encounters. Whenever he recognizes an agent on the examined ritual place as someone in in his memory, he increases the score of the ritual place by one. In a null model (i.e. when the effect of SFc and CAc are set up to zero) he goes into a place scoring highest in that respect. When the SFc is higher than zero, the agent takes into consideration previous encounters with other agents at the ritual space. For each agent that was previously encountered on SF place, the score is increased by 1 and multiplied by (1 + SFc value). Thus, the agent pays higher attention to encounters formed on the SF places than to encounters formed on the CA places.

Second, when the CAc parameter is higher than zero, the agent modifies the marks of all ritual places on the basis of what type of places he visited over the past 5 ticks. The most recent memory has the strongest impact again. Thus, if the agent visited a CA place one week back, he multiplies the overall mark of all current CA places by (1 + [CAc value * 5]), where 5 reflects the fact that it is the most recent memory from the 5 slots.  Further, if he visited a CA place two weeks back as well, he multiplies the overall mark of all current CA places again, now by (1 + [CAc value * 4]) etc. Thus, in agreement with the theoretical framework, past visits of CA places make the agent cumulatively more motivated to visit this type of places again and again over time, regardless with whom he can meet there.



## Authors
Vojtěch Kaše, Tomáš Hampejs, & Zdeněk Pospíšil 
Corresp. address: vojtech.kase@gmail.com

Relased as part of KUZ 2018 workshop, https://www.phil.muni.cz/kuz2018 .
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>yellowones</metric>
    <metric>redones</metric>
    <metric>yellowonesTotal</metric>
    <metric>redonesTotal</metric>
    <enumeratedValueSet variable="place-affinity-coeficient">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prosociality-influence-coeficient">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.5"/>
      <value value="0.5"/>
      <value value="0.7"/>
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="testing-null-model" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>yellowones</metric>
    <metric>redones</metric>
    <metric>yellowonesTotal</metric>
    <metric>redonesTotal</metric>
    <enumeratedValueSet variable="prosociality-influence-coeficient">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="place-affinity-coeficient">
      <value value="0"/>
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
