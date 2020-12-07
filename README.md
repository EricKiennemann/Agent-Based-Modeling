# CAR FLOW SIMULATION

The web logo version of this project is here : https://storage.googleapis.com/netlogo/car_flow_simulation.html

![Car flow simulation](/images/flow_car_simulation.gif)

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
