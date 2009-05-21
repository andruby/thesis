/*********************************************
 * OPL 5.0 Model
 * Author: Andrew Fecheyr Lippens
 * Creation Date: 9/05/2009 at 23:49
 *********************************************/

// Setup
int      horizon = 60*24*21-1;    // Number of minutes in a week
int      blocktime = 5;

// Inladen van parameter.dat
int   rotation_time_bru = ...;
int   spill_short = ...;
int   spill_medium = ...;
int   fixed_cost_100 = ...;
int   var_cost_100 = ...;
int   swap_cost_family = ...;
int   swap_cost_nonfamily = ...;
int   rotation_time_external = ...;

// Opbouwen van alle tijdspunten in het netwerk
int check_count = ftoi((horizon+1) / blocktime);
{int} timepoints = {i*blocktime | i in 0..check_count};

// Data van elke vloot
tuple FleetType 
{
  string   ba_code;     // Id vloot
  int      aircrafts;  // Aantal vliegtuigen
  string   haul;       // medium-short haul
  int      seats;      // Aantal zetels
  int      fixed_cost_percent; // Vaste kosten per vlucht
  int      var_cost_percent;   // Variabele kosten per minuut in de lucht
  int      family;      // family van t vliegtuig. 1 = AR1,AR8,146 en 2 = 733,734
}

// Invullen van vloot info uit data file
{FleetType} fleets = ...; 

// Vlucht datastructuur
tuple FlightStruct 
{
  int       id;         // flight id
  string    original_ba_code;    // ba_code van de originele assignment
  int       original_family;     // family of the original aircraft
  int       depT;       // departure time 
  int       arrT;       // arrival time 
  int       flightT; // Totale tijd in de lucht
  string    haul;       // medium-short haul
  int       pax_1;        // Passagiersvraag voor 1e leg
  int       pax_2;      // Passagiersvraag voor 2e leg
}

{FlightStruct} flights = ...; 

// Controleer of de tijden kloppen
assert forall(l in flights)  0 <= l.depT;
assert forall(l in flights)  0 <= l.arrT;
assert forall(l in flights)  horizon >= l.depT;
assert forall(l in flights)  horizon >= l.arrT;
assert forall(l in flights)  l.depT < l.arrT;

// De operationele kostprijs
// Voor elk koppel (fleet,flight) definieren we Cost = spill_cost + fixed_cost + var_cost*flightT
float Cost[fleets][flights];

// Cost Initialization
execute COST_INIT {
   for(var l in flights) {
      for(var f in fleets) {
         var spill_cost = 0;
         // bereken de totale spill
         var spill = 0;
         if(f.seats < l.pax_1) { spill = spill + l.pax_1 - f.seats }
         if(f.seats < l.pax_2) { spill = spill + l.pax_2 - f.seats }
         if(0 < spill) {
            var spill_price = (l.haul == "Medium" ? spill_medium : spill_short );
            spill_cost = spill * spill_price;
         } 
         // bereken de swap_penalty
         var swap_penalty = 0;
         if (l.original_ba_code != f.ba_code) {
            // er is geswapped
            if (l.original_family == f.family) {
               swap_penalty = swap_cost_family;
            }
            else
            {
               swap_penalty = swap_cost_nonfamily;
            }
         }
         Cost[f][l] = spill_cost + 2*(f.fixed_cost_percent/100)*fixed_cost_100 + (f.var_cost_percent/100)*(l.flightT/60)*var_cost_100 + swap_penalty;
      }
   }
}

// Maak arrays van vluchten voor elk tijdspunt
{FlightStruct} time_flights_array[t in timepoints] = {l | l in flights : l.depT <= t && t < (l.arrT + rotation_time_bru)}; 

/*  ----------------------------------------------------
 *   Variabelen:
 *   assignment -- assignment[l][f] betekend dat flights[l] gevlogen 
 *         wordt door een vliegtuig in fleets[f].
 *   --------------------------------------------------- */
dvar boolean assignment[fleets][flights];

minimize
   sum(l in flights, f in fleets)
      Cost[f][l] * assignment[f][l];
      
subject to {
   forall(l in flights)
      ctCover:
         sum(f in fleets)
            assignment[f][l] == 1;
            
   forall(t in timepoints,f in fleets)
      ctAvailability:
         sum(l in time_flights_array[t])
            assignment[f][l] <= f.aircrafts;
            
   forall(l in flights: l.haul == "Medium")
      ctHaul:
         sum(f in fleets: f.haul == "Short")
            assignment[f][l] == 0;
}

/*
* OUTPUT 
* schrijf de assignments naar een textfile dat makkelijk 
* ingelezen kan worden door cplex_to_ruby.rb 
* dit is nodig om de visualisatie software te gebruiken
*/

execute DISPLAY {
   var ofile = new IloOplOutputFile("Z:\\unief\\thesis - fleet assignment\\ILOG\\shared_data\\assignments\\assignments.txt");
   for(var l in flights) {
      for(var f in fleets) {
         if(assignment[f][l] == 1) {
            ofile.writeln(l.id, ": ", f.ba_code);
            writeln(l.id, ": ", f.ba_code);
         }
      }
   }
   ofile.close();
}