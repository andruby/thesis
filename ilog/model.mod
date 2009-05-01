/*  ----------------------------------------------------
 *   OPL Model for Fleet Assignment Example
 *   (c) 2001 ILOG, Inc.
 *   All Rights Reserved
 *
 *
 *   This model is called by the fleet.prj OPL Studio
 *   project.
 *
 *   The fleet assignment problem assigns aircrafts (fleets) 
 *   to flights in order to maximize net profit.
 * 
 *   The data include:   
 *      1) a list of airports,
 *      2) a list of flights among those airports,
 *      3) a list of fleets.
 *
 *   Time is in minutes of the week.
 * 
 *   The constraints include:
 *      1) there must be a plane at the airport for the
 *         flight.
 *      2) one-stop flights must have both legs assigned to the 
 *         same fleet.
 *      3) Each airport must begin and end the week with the same 
 *         distribution of planes.
 *
 *   "Source" and "sink" cities are added so that we can 
 *   build the third type of constraint.
 *   ---------------------------------------------------
 */

int      Horizon = 10400;    // Number of minutes in a week (tot 6:20 smorgens de zondag)
int      maxRefuel = 40;         
{string} Airports = ...;
{string} Fleets = ...;
{string} Distance = ...;
float    MaxSpill = ...;

//Characteristics of each fleet
tuple FleetType 
{
  int      aircrafts;  //number of aircrafts for each fleet
  string   dist;       //long-medium-short distance flight
  int      seats;      //number of seats
  int      refuelT;    //Time on ground between flights
  int      a;          //fixed cost
  int      b;          //variable cost : total cost = a + BH * b * seats where BH is the flight time
}
FleetType fleetInfo[Fleets] = ...; 
assert forall(pl in Fleets) fleetInfo[pl].refuelT <= maxRefuel;

//Flight legs
tuple FlightLeg 
{
  int       id;    //flight id
  string    depA;  //departure airport
  int       depT;  //departure time 
  string    arrA;  //arrival airport
  int       arrT;  //arrival time 
  string    dist;  //long-medium-short distance flight
  int       pax;   //passenger demand
  int       price; //ticket price
}
{FlightLeg} flightLegs = ...; 
assert forall(fl in flightLegs)  0 <= fl.depT;// <= Horizon;
assert forall(fl in flightLegs)  0 <= fl.arrT;// <= Horizon;
assert forall(fl in flightLegs)  Horizon >= fl.depT;
assert forall(fl in flightLegs)  Horizon >= fl.arrT;
assert forall(fl in flightLegs)  fl.depT < fl.arrT;

//Flow model
{FlightLeg} source = {<999,"Source", f.depT-maxRefuel,f.depA, f.depT-maxRefuel,f.dist,0,0> | f in flightLegs};
{FlightLeg} sink = {<999,f.arrA, Horizon+maxRefuel, "Sink", Horizon+maxRefuel,f.dist,0,0> | f in flightLegs};
{FlightLeg} flights = flightLegs union source union sink;

//One-stop flights
//These are flights which are broken into 2 sub-flights, and are flown by the
//same aircraft.
tuple OneStop
{
  int firstId;
  int secondId;
}
{OneStop} oneStopFlights = ...;

//Cash Direct Operating Costs
//for every couple (fleet,flight) we define  cdoc = a + b*(demand-spill)*(arrTime-depTime)
int Cost[flights][Fleets];

//Profit
//for every couple (fleet,flight) we define  profit = (demand-spill)*ticket_price
int Profit[flights][Fleets];

//Cost & Profit Initialization
execute INITIALIZE {
   for(fl in flights) {
      for(pl in Fleets) {
         if(fl.depA != "Source" && fl.arrA != "Sink") {  
            //Cost vector
            if(fl.pax > fleetInfo[pl].seats) {
               Cost[fl][pl] = fleetInfo[pl].a + fleetInfo[pl].b*fleetInfo[pl].seats*(fl.arrT-fl.depT);
            } else {
               Cost[fl][pl] = fleetInfo[pl].a + fleetInfo[pl].b*fl.pax*(fl.arrT-fl.depT);
            }

            //Profit vector
            if(fl.pax > fleetInfo[pl].seats) {
               Profit[fl][pl] = fleetInfo[pl].seats*fl.price;
            } else {
               Profit[fl][pl] = fl.pax*fl.price;
            }
         } else {
            Cost[fl][pl] = 0;
            Profit[fl][pl] = 0;
         }
      }
   }
}


/*  ----------------------------------------------------
 *   Variables:
 *   assignment -- assignment[fl][pl] means flights[fl] is 
 *         covered by a plane in fleet[pl].
 *   --------------------------------------------------- */
dvar boolean assignment[flights][Fleets];

constraint cstSource;
constraint cstSink;
constraint cstSpill;

minimize 
   sum(fl in flights, pl in Fleets)
      (-Profit[fl][pl] + Cost[fl][pl]) * assignment[fl][pl];
subject to {
   // Every plane of each fleet must come from the source only once.
   cstSource =
   forall(pl in Fleets)
      sum(fl in flights: fl.depA == "Source") assignment[fl][pl] <= fleetInfo[pl].aircrafts;

   // Every plane of each fleet must go to the sink only once.
   cstSink =
   forall(pl in Fleets)
      sum(fl in flights: fl.arrA == "Sink") assignment[fl][pl] <= fleetInfo[pl].aircrafts;

   forall(fl in flights: fl.depA != "Source" && fl.arrA != "Sink") 
      // Every "real" flight must have a plane assigned to it
      sum(pl in Fleets) assignment[fl][pl] == 1;

   forall(pl in Fleets, fl in flights: fl.depA != "Source" && fl.arrA != "Sink") 
      // The plane must be at the airport in order to use it!
      sum(prevf in flights: prevf.arrA == fl.depA && prevf.arrT + fleetInfo[pl].refuelT <= fl.depT) 
         assignment[prevf][pl] -
      sum(prevf in flights: prevf != fl && prevf.depA == fl.depA && prevf.depT <= fl.depT) 
         assignment[prevf][pl]
      >= assignment[fl][pl];
      
   forall(pl in Fleets, fl in flights: fl.arrA == "Sink")
      // The plane must be at the airport in order to use it!
      sum(prevf in flights: prevf.arrA == fl.depA && prevf.arrT + fleetInfo[pl].refuelT <= fl.depT) 
         assignment[prevf][pl] -
      sum(prevf in flights: prevf != fl && prevf.depA == fl.depA && prevf.depT <= fl.depT) 
         assignment[prevf][pl]
      >= assignment[fl][pl];
     
   //Type-compatibility check between fleets and flights (long/medium/short distance)
   //Long-haul aircrafts can fly long, medium and short flights, medium-haul aircrafts
   //can only fly medium and short flights, and so on..
   forall(fl in flights: fl.depA != "Source" && fl.arrA != "Sink")
      forall(pl in Fleets: fleetInfo[pl].dist == "Short" && (fl.dist == "Medium" || fl.dist == "Long"))
         assignment[fl][pl] == 0;
   forall(fl in flights: fl.depA != "Source" && fl.arrA != "Sink")
      forall(pl in Fleets: fleetInfo[pl].dist == "Medium" && fl.dist == "Long")
         assignment[fl][pl] == 0;

   cstSpill =
   forall(fl in flights: fl.depA != "Source" && fl.arrA != "Sink")
      //MaxSpill constraint
      //if MaxSpill=.1 and the demand for the flight f is 100, then the maximum no of passengers 
      //that can be spilled is 10 (i.e. you must use an aircraft which has seat capacity >= 90 )
      sum(pl in Fleets) assignment[fl][pl]*fleetInfo[pl].seats >= fl.pax*(1-MaxSpill);

   forall(pl in Fleets) {
   // Planes must end the day where they started the day
      forall(ap in Airports)
         sum(fl in flights: fl.depA == "Source" && fl.arrA == ap) assignment[fl][pl] ==
         sum(fl in flights: fl.depA == ap && fl.arrA == "Sink") assignment[fl][pl];

      //One-Stop services
      //force each ordered pair of forced turn flights to use the same equipment type
      forall(pair in oneStopFlights)
         sum(f1 in flights: f1.id == pair.firstId) assignment[f1][pl] ==
         sum(f2 in flights: f2.id == pair.secondId) assignment[f2][pl];
   }
}


execute DISPLAY {
   for(fl in flights)
      for(pl in Fleets)
         if(assignment[fl][pl] == 1) 
            writeln("assignment[", fl, "][", pl, "] = ", assignment[fl][pl]);
}