class gelignAIte extends AIController 
{
  // Bus service
  bus_town_id                 = false;
  bus_depot_tile              = false;
  bus_service_built           = false;
  bus_station_downtown        = false;
  bus_station_uptown          = false;
  bus_engine                  = false;
  bus_new_engine_available    = false;

  // Postal service
  postal_town_id              = false;
  postal_depot_tile           = false;
  postal_service_built        = false;
  postal_station_downtown     = false;
  postal_station_uptown       = false;
  postal_engine               = false;
  postal_new_engine_available = false;

  // General
  last_station_update         = 0;
  max_station_update          = false;
  group_id                    = null;                         // Updating engines, etc.
  self                        = AICompany.COMPANY_INVALID;

  constructor()
  {
    this.bus_town_id                 = false;
    this.bus_depot_tile              = false;
    this.bus_service_built           = false;
    this.bus_station_downtown        = false;
    this.bus_station_uptown          = false;
    this.bus_engine                  = false;
    this.bus_new_engine_available    = false;

    this.postal_town_id              = false;
    this.postal_depot_tile           = false;
    this.postal_service_built        = false;
    this.postal_station_downtown     = false;
    this.postal_station_uptown       = false;
    this.postal_engine               = false;
    this.postal_new_engine_available = false;

    this.last_station_update         = AIDate.GetYear( AIDate.GetCurrentDate() );
    this.max_station_update          = false;
    this.group_id                    = null;
    this.self                        = AICompany.COMPANY_SELF;
  } 
}

function gelignAIte::Start()
{
  debug( "gelignAIte started." );
  InitCompany();

  // Set legal road type
  AIRoad.SetCurrentRoadType( AIRoad.ROADTYPE_ROAD );

  // Set the current available engines for bus and postal services.
  // In the following this is done via event-handling.
  ManageEngines( false ); // Do not send vehicles to depot

  // Keep running. If Start() exits, the AI dies.
  while( true )
  {
    // Build up services
    CreateBusService();
    this.Sleep( 10 );
    CreatePostalService();
    this.Sleep( 10 );

    // Move stations outwards in growing towns
    UpdateStations();
    this.Sleep( 10 );

    // Check for interrupts, especially crashed vehicles
    HandleEvents();
    this.Sleep( 10 );

    // Check funds, repay loan where required and possible
    ManageFunds();
    this.Sleep( 10 );

    // Make auto renew vehicles happen or build better vehicles (i.e. newer models)
    ManageVehicles();

    // No haste
    this.Sleep( 450 );
  }
}

function gelignAIte::Stop()
{
//debug("TODO: Implement me (stop function)", "error");
}

function gelignAIte::Save()
{
  local table = {}; 

  table.rawset( "bus_town_id", this.bus_town_id );
  table.rawset( "bus_depot_tile", this.bus_depot_tile );
  table.rawset( "bus_service_built", this.bus_service_built );
  table.rawset( "bus_station_downtown", this.bus_station_downtown );
  table.rawset( "bus_station_uptown", this.bus_station_uptown );
  table.rawset( "bus_engine", this.bus_engine );
  table.rawset( "bus_new_engine_available", this.bus_new_engine_available );
  table.rawset( "postal_town_id", this.postal_town_id );
  table.rawset( "postal_depot_tile", this.postal_depot_tile );
  table.rawset( "postal_service_built", this.postal_service_built );
  table.rawset( "postal_station_downtown", this.postal_station_downtown );
  table.rawset( "postal_station_uptown", this.postal_station_uptown );
  table.rawset( "postal_engine", this.postal_engine );
  table.rawset( "postal_new_engine_available", this.postal_new_engine_available );
  table.rawset( "last_station_update", this.last_station_update );
  table.rawset( "max_station_update", this.max_station_update );
  table.rawset( "group_id", this.group_id );

  return table;
}

function gelignAIte::Load( version, data )
{
  if( data.rawin( "bus_town_id" ))
    this.bus_town_id = data.rawget( "bus_town_id" );

  if( data.rawin( "bus_depot_tile" ))
    this.bus_depot_tile = data.rawget( "bus_depot_tile" );

  if( data.rawin( "bus_service_built" ))
    this.bus_service_built = data.rawget( "bus_service_built" );

  if( data.rawin( "bus_station_downtown" ))
    this.bus_station_downtown = data.rawget( "bus_station_downtown" );

  if( data.rawin( "bus_station_uptown" ))
    this.bus_station_uptown = data.rawget( "bus_station_uptown" );

  if( data.rawin( "bus_engine" ))
    this.bus_engine = data.rawget( "bus_engine" );

  if( data.rawin( "bus_new_engine_available" ))
    this.bus_new_engine_available = data.rawget( "bus_new_engine_available" );

  if( data.rawin( "postal_town_id" ))
    this.postal_town_id = data.rawget( "postal_town_id" );

  if( data.rawin( "postal_depot_tile" ))
    this.postal_depot_tile = data.rawget( "postal_depot_tile" );

  if( data.rawin( "postal_service_built" ))
    this.postal_service_built = data.rawget( "postal_service_built" );

  if( data.rawin( "postal_service_built" ))
    this.postal_station_downtown = data.rawget( "postal_station_downtown" );

  if( data.rawin( "postal_station_uptown" ))
    this.postal_station_uptown = data.rawget( "postal_station_uptown" );

  if( data.rawin( "postal_engine" ))
    this.postal_engine = data.rawget( "postal_engine" );

  if( data.rawin( "postal_new_engine_available" ))
    this.postal_new_engine_available = data.rawget( "postal_new_engine_available" );

  if( data.rawin( "last_station_update" ))
    this.last_station_update = data.rawget( "last_station_update" );

  if( data.rawin( "max_station_update" ))
    this.max_station_update = data.rawget( "max_station_update" );

  if( data.rawin( "group_id" ))
    this.group_id = data.rawget( "group_id" );

  debug( "Loaded." );
}

function gelignAIte::InitCompany()
{
  // Say hi
  debug( "Hi, I'm the gelignAIte AI.");
  debug( "I will create a passenger and a postal service in the biggest town nearby," );
  debug( "buy some vehicles to drive around and then 'fall asleep.'   :-) *ZzzZZzZ*" );

  // Set company name
  local rank = "st";
  local i = 1;
  if( !AICompany.SetName( "gelignAIte" ))
  {
    do
    {
      i++;
      switch( i % 10 )
      {
        case 1:
          rank = "st";
        break;
        case 2:
          rank = "nd";
        break;
        case 3:
          rank = "rd";
        break;
        default:
          rank = "th";
      }
    }
    while( !AICompany.SetName( "gelignAIte #" + i ) && ( i < 255 ));
  }

  // Make our president
  AICompany.SetPresidentGender( AICompany.GENDER_MALE );
  AICompany.SetPresidentName( "gelign!te " + i + rank );

  // Enable automatic renewal of vehicles
  if( AICompany.SetAutoRenewStatus( true ))
  {
    debug( "Set auto renew status to " + AICompany.GetAutoRenewStatus( this.self ));
  }
  if( AICompany.SetAutoRenewMonths( 6 ))
  {
    debug( "Set auto renew months to " + AICompany.GetAutoRenewMonths( this.self ));
  }
  if( AICompany.SetAutoRenewMoney( 50000 ))
  {
    debug( "Set auto renew money to " + AICompany.GetAutoRenewMoney( this.self ));
  }

  // Create group for vehicle servicing (updating engines, a.s.o.)
  if( this.group_id == null )
  {
    this.group_id = AIGroup.CreateGroup( AIVehicle.VT_ROAD );
  }
}

/**Write debug output to the console.
 */
function gelignAIte::debug( str, type = "info" )
{
  local date  = AIDate.GetCurrentDate();
  local year  = AIDate.GetYear( date );
  local month = AIDate.GetMonth( date );
  local day   = AIDate.GetDayOfMonth( date );
  local ts    = year + "-" + month + "-" + day + ": ";

  switch( type )
  {
    case "error":
      AILog.Error( ts + str );
    break;
    case "warning":
      AILog.Warning( ts + str );
    break;
    case "info":  // fall through
    default:
      AILog.Info( ts + str );
  }
}

/**Event handling.
 */
function gelignAIte::HandleEvents()
{
  //if( debug() ) AILog.Info( "Checking events ..." );
  while( AIEventController.IsEventWaiting() )
  {
    local event = AIEventController.GetNextEvent();
    switch( event.GetEventType() )
    {
      // New engine available
      case AIEvent.AI_ET_ENGINE_PREVIEW:   // Fall through
      case AIEvent.AI_ET_ENGINE_AVAILABLE:
        ManageEngines();
        break;

      // Vehicle lost or crashed
      case AIEvent.AI_ET_VEHICLE_LOST:     // Fall through
      case AIEvent.AI_ET_VEHICLE_CRASHED:
        ReplaceCrashedVehicle();
        break;

      // Other events not yet handled
      default:
        // Intentionally ignored.
    }
  }
  //if( debug() ) debug( "... done. [Event handling]" );
}

/**Find cargo type of an engine. Use in a ListValuator.
 */
function gelignAIte::EngineCargoValuator( engine_id, cargo_label )
{
  local cLabel = AICargo.GetCargoLabel( AIEngine.GetCargoType( engine_id ));

  // Engine's cargo label is the desired cargo label
  return cLabel == cargo_label;
}

/**Get cargo label of the given vehicle.
   Provided for convenience and debugging purposes.
*/
function gelignAIte::GetCargoLabel( vehicle_id )
{
  return AICargo.GetCargoLabel( AIEngine.GetCargoType( AIVehicle.GetEngineType( vehicle_id ) ) );
}

/**Find cargo type of a vehicle. Use in a ListValuator.
 */
function gelignAIte::VehicleCargoValuator( vehicle_id, cargo_label )
{
  local engine_id  = AIVehicle.GetEngineType( vehicle_id );
  local cargo_type = AIEngine.GetCargoType( engine_id );
  local cLabel     = AICargo.GetCargoLabel( cargo_type );

  // True if vehicle's cargo label is the desired cargo label
  return cLabel == cargo_label;
}

/**Retrieving vehicles types available.
 */
function gelignAIte::GetEnginesYetAvailable()
{
  local enginesAvailable = AIEngineList( AIVehicle.VT_ROAD );
  // enginesAvailable.AddList( AIEngineList( AIVehicle.VT_RAIL ));
  // enginesAvailable.AddList( AIEngineList( AIVehicle.VT_WATER ));
  // enginesAvailable.AddList( AIEngineList( AIVehicle.VT_AIR ));

  return enginesAvailable;
}

/**Replace a crashed vehicle as long as there are enough funds.
*/
function gelignAIte::ReplaceCrashedVehicle()
{
  local vl = AIVehicleList();
  vl.Valuate( AIVehicle.GetState );
  vl.KeepValue( AIVehicle.VS_CRASHED );

  // Get funds
  AICompany.SetLoanAmount( AICompany.GetMaxLoanAmount() );

  // Clone lost vehicles and start them
  for( local v = vl.Begin(); vl.HasNext(); v = vl.Next(), this.Sleep( 10 ))
  {
    debug( "Vehicle (ID: " + v + ") crashed. Trying to replace it now.", "warning" );

    // Try to stop it to save running costs
    AIVehicle.StartStopVehicle( v );

    // Find corresponding depot
    local depot_tile = GetCargoLabel( v ) == "PASS" ? this.bus_depot_tile : this.postal_depot_tile;
    
    // Clone crashed vehicle including orders
    local cv = AIVehicle.CloneVehicle( depot_tile, v, true );

    // Start vehicle if one could be built
    if( AIVehicle.IsValidVehicle( cv ) )
    {
      AIVehicle.StartStopVehicle( cv );

      // Add to group
      AIGroup.MoveVehicle( this.group_id, cv );
    }
  }

  // Repay loan left
  ManageFunds();
}

/**Build a depot in the given town.
 */
function gelignAIte::BuildDepot( town_id )
{
  debug( "Going to build a depot in " + AITown.GetName( town_id ) + " now ..." );
  local tile_id = false;

  // Make a list of tiles we can build our depot on ...
  local depot_placement_tiles = AITileList();
  local town_loc = AITown.GetLocation( town_id );
  depot_placement_tiles.AddRectangle( town_loc - AIMap.GetTileIndex( 5, 5 ), town_loc + AIMap.GetTileIndex( 5, 5 ));
  //if( debug() )  debug( "Tiles left in " + AITown.GetName( town_id ) + ": " + depot_placement_tiles.Count() );

  // ... but only consider tiles next to roads
  depot_placement_tiles.Valuate( AIRoad.GetNeighbourRoadCount );
  depot_placement_tiles.KeepAboveValue( 0 );
  //if( debug() )  debug( "Road-neighboured tiles left in " + AITown.GetName( town_id ) + ": " + depot_placement_tiles.Count() );

  // ... but not being a road itself
  depot_placement_tiles.Valuate( AIRoad.IsRoadTile );
  depot_placement_tiles.KeepValue( 0 );
  //if( debug() )  debug( "No-road tiles left in " + AITown.GetName( town_id ) + ": " + depot_placement_tiles.Count() );

  // ... and not sloped
  depot_placement_tiles.Valuate( AITile.GetSlope );
  depot_placement_tiles.KeepValue( 0 );
  //if( debug() )  debug( "Not-sloped tiles left in " + AITown.GetName( town_id ) + ": " + depot_placement_tiles.Count() );

  // Finally search from town center and outwards
  depot_placement_tiles.Valuate( AIMap.DistanceManhattan, town_loc );
  depot_placement_tiles.Sort( AIAbstractList.SORT_BY_VALUE, false ); // highest value first == build depot uptown

  //if( debug() )  AILog.Info( "Trying to build depot now on one of the tiles left ..." );
  for( tile_id = depot_placement_tiles.Begin(); depot_placement_tiles.HasNext(); tile_id = depot_placement_tiles.Next() )
  {
    // Orientate depot to neighboured road tile
    local front = GetNeighbourRoadTileWithNoSlopeAndClear( tile_id );

    //if( !AITile.IsBuildable( tile_id ) && !AIRoad.IsRoadTile( tile_id ) && !AICompany.IsMine( AITile.GetOwner( tile_id )))
    if( front && !AITile.IsBuildable( tile_id ) && !AICompany.IsMine( AITile.GetOwner( tile_id )))
    {
      // Clear tile to build depot on
      if( AITile.DemolishTile( tile_id ) )
      {
        //if( debug() )  debug( "Front tile id: " + front );
        //if( debug() )  debug( "Demolishing tile: " + tile_id );

        // Build depot 
        if( !front || !AIRoad.BuildRoadDepot( tile_id, front ))
        {
          //if( debug() )  debug( "... failed building depot ..." );
          //if( debug() )  debug( "... Front: " + front );
          //if( debug() )  debug( "... Error: " + AIError.GetLastErrorString() );
        }
        else
        {
          debug( "... successfully built depot (Tile-ID: " + tile_id + "). Now checking road connection ..." );

          // Connect to road if necessary at all
          if( AIRoad.AreRoadTilesConnected( tile_id, front ))
          {
            debug( "... road tiles already connected. Skipping building road." );
            break; // We are done
          }
          else
          {
            debug( "... road tiles not connected. Connect now ..." );

            // Connect to road and repeat if road was not clear (due to passing vehicles)
            local road_built = false;
            local attempts = 0;
            do
            {
              attempts++;
              if( attempts > 1 )
              {
                debug( attempts + ". attempt to connect depot ... (Failure due to: " + AIError.GetLastErrorString() + ")" );
              }

              this.Sleep( 5 );
              road_built = AIRoad.BuildRoad( tile_id, front );
            } while( AIError.GetLastError() != AIError.ERR_NONE && attempts < 500 );

            // Check whether road building was successful
            if( road_built )
            {
              debug( "... successfully connected depot with road (Tile-ID: " + front + ")." );
              break; // We are done
            }
            else
            {
              debug( "... failed to connect to road after " + attempts + " attempts. Last failure due to: " + AIError.GetLastErrorString() );
              debug( "... removing depot again and trying another location (if available). I'm sorry for demolishing tile " + tile_id + " ..." );
              AITile.DemolishTile( tile_id );
            }
          }
        }
      } // if demolished
    } // if buildable
  } // end for

  return tile_id;
}

/**Build stations in the given town of the given vehicle type at the desired places.
 */
function gelignAIte::BuildStation( town_id, ROADVEHTYPE, downtown )
{
  local tile_id = false;

  // Make a list of tiles we can build our stations on ...
  local station_placement_tiles = AITileList();
  local town_loc = AITown.GetLocation( town_id );

  // Make range dependend from town size. At least 5 tiles plus an additional offset.
  // NOTE: There seems to be a bug with the tile list.
  // We can't increase just the rectangle as then we seem to lose several tiles near the town center.
  // So increase rectangle in dependency of "downtown" parameter.
  local pop = AITown.GetPopulation( town_id );
  local range = 5;
  if( !downtown )
  {
    // Increase range by 1 tile per 3000 inhabitants
    range += pop / 3000;

    // But don't go any further than 16 tiles
    if( range > 16 )
    {
      range = 16;

      // Don't update (move) stations any longer
      this.max_station_update = true;
    }
  }

  // Make rectangle with possible tiles to build stations on
  station_placement_tiles.AddRectangle( town_loc - AIMap.GetTileIndex( range, range ), town_loc + AIMap.GetTileIndex( range, range ));
  // debug( "Tiles left in " + AITown.GetName( town_id ) + ": " + station_placement_tiles.Count() );

  // ... but only consider road tiles
  station_placement_tiles.Valuate( AIRoad.IsRoadTile );
  station_placement_tiles.KeepAboveValue( 0 );
  // debug( "Road tiles left in " + AITown.GetName( town_id ) + ": " + station_placement_tiles.Count() );

  // ... and not sloped
  station_placement_tiles.Valuate( AITile.GetSlope );
  station_placement_tiles.KeepValue( 0 );
  // debug( "Not-sloped tiles left in " + AITown.GetName( town_id ) + ": " + station_placement_tiles.Count() );

  // Don't go over the edges
  station_placement_tiles.Valuate( AIMap.DistanceMax, town_loc );
  station_placement_tiles.KeepBelowValue( range + 1 );

  // Finally search from outside inwards
  station_placement_tiles.Valuate( AIMap.DistanceManhattan, town_loc );
  station_placement_tiles.Sort( AIAbstractList.SORT_BY_VALUE, downtown ); // Place station outwards (outside the town)

  // Find location to place the stations
  for( tile_id = station_placement_tiles.Begin(); station_placement_tiles.HasNext(); tile_id = station_placement_tiles.Next() )
  {
    // Orientate depot to neighboured road tile
    local front = GetNeighbourRoadTile( tile_id );
    if( !front )
    {
      continue; // No neighbour available. Next!
    }

    local station_built = false;
    local attempts      = 0;
    do
    {
      attempts++;
      if( attempts > 1 )
      {
        debug( attempts + ". attempt to built station on tile " + tile_id + " ... (Failure due to: " + AIError.GetLastErrorString() + ")" );
      }

      this.Sleep( 10 );

      // Combine station where possible ...
      station_built = AIRoad.BuildDriveThroughRoadStation( tile_id, front, ROADVEHTYPE, AIStation.STATION_JOIN_ADJACENT );
      // ... or build a new one when combining failed
      if( !station_built && AIError.GetLastErrorString() == "ERR_STATION_TOO_CLOSE_TO_ANOTHER_STATION" )
      {
        station_built = AIRoad.BuildDriveThroughRoadStation( tile_id, front, ROADVEHTYPE, AIStation.STATION_NEW );
      }
    } while( AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY && attempts < 200 );

    if( station_built )
    {
      debug( "Station built successfully (Tile-ID: " + tile_id + "). Distance (max) to town center: " + AIMap.DistanceMax( town_loc, tile_id ));
      break;
    }
    else
    {
      debug( "... failed to build station on tile " + tile_id + " after " + attempts + " attempts. Last failure due to: " + AIError.GetLastErrorString(), "warning" );
    }
  }

  return tile_id;
}

/**Find neighboured road tile. Will be used e.g. to orientate depots.
 */
function gelignAIte::GetNeighbourRoadTile( tile_id )
{
  // Get coordinates of center tile
  local tile_x = AIMap.GetTileX( tile_id );
  local tile_y = AIMap.GetTileY( tile_id );

  // Get 4 neighbours
  local neighbours = AITileList();
  neighbours.AddTile( AIMap.GetTileIndex( tile_x - 1, tile_y ));
  neighbours.AddTile( AIMap.GetTileIndex( tile_x, tile_y - 1 ));
  neighbours.AddTile( AIMap.GetTileIndex( tile_x + 1, tile_y ));
  neighbours.AddTile( AIMap.GetTileIndex( tile_x, tile_y + 1 ));

  // Only neighbours with at least one road tile ...
  neighbours.Valuate( AIRoad.IsRoadTile );
  neighbours.KeepAboveValue( 0 );

  // ... and not being drive through station itself
  neighbours.Valuate( AIRoad.IsRoadStationTile );
  neighbours.KeepValue( 0 );

  // Return first neighboured road tile
  local neighbour = false;
  for( local i = neighbours.Begin(); neighbours.HasNext(); i = neighbours.Next() )
  {
    neighbour = i;
    break;
  }

  return neighbour;
}

/**Check the 4 neighboured tiles for being of type road and not sloped.
 */
function gelignAIte::GetNeighbourRoadTileWithNoSlopeAndClear( center_tile_id )
{
  // Get coordinates of center tile
  local tile_x = AIMap.GetTileX( center_tile_id );
  local tile_y = AIMap.GetTileY( center_tile_id );

  // Get 4 neighbours
  local neighbours = AITileList();
  neighbours.AddTile( AIMap.GetTileIndex( tile_x - 1, tile_y ));
  neighbours.AddTile( AIMap.GetTileIndex( tile_x, tile_y - 1 ));
  neighbours.AddTile( AIMap.GetTileIndex( tile_x + 1, tile_y ));
  neighbours.AddTile( AIMap.GetTileIndex( tile_x, tile_y + 1 ));

  // Only neighbours without slope are from interest ...
  neighbours.Valuate( AITile.GetSlope );
  neighbours.KeepValue( 0 );

  // ... and don't have a drive through station on it
  neighbours.Valuate( AIRoad.IsRoadStationTile );
  neighbours.KeepValue( 0 );

  // Return first neighboured road tile
  local neighbour = false;
  for( local i = neighbours.Begin(); neighbours.HasNext(); i = neighbours.Next() )
  {
    if( AIRoad.IsRoadTile( i ))
    {
      neighbour = i;
      break;
    }
  }

  return neighbour;
}

/**Determine current available engines for MAIL and PASSenger services
   and set the best ones. This function is always called on a new engine
   even if not a MAIL or PASS one. It will force vehicles to be replaced
   next time ManageVehicles() is called (it will send them to depot for
   servicing and AIGroup.SetAutoReplace will do the rest).
*/
function gelignAIte::ManageEngines( ingame = true )
{
  // Check for engines available for passengers
  local ea = GetEnginesYetAvailable();

  // Choose adequate road vehicle for passenger service
  ea.Valuate( EngineCargoValuator, "PASS" );
  ea.KeepValue( 1 );
  ea.Valuate( AIEngine.GetRoadType ); // Exclude trams
  ea.KeepValue( 0 );

  // Set vehicle type to best engine available
  if( ea.Count() > 0 )
	{
		local bus_engine_new = ea.Begin();
		if( this.bus_engine != bus_engine_new )
		{
			// Called on start to set the initial engine to build.
      // Nothing to replace here.
			if( !ingame )
			{
				this.bus_engine = bus_engine_new;
			}
			// Force vehicles to go to depot when this was called by an event
			// but only when we have a service running at all.
			else if( this.bus_service_built )
			{
				this.bus_new_engine_available = true;

				// Update engine
				if( AIGroup.SetAutoReplace( this.group_id, this.bus_engine, bus_engine_new ))
				{
					debug( "New bus engine available. Updating bus service." );
					this.bus_engine = bus_engine_new;
				}
			}
		}
	}

  // Check for engines available for mail
  ea.Clear();
  ea = GetEnginesYetAvailable();

  // Choose adequate road vehicle for postal service
  ea.Valuate( EngineCargoValuator, "MAIL" );
  ea.KeepValue( 1 );

  // Set vehicle type to best engine available
  if( ea.Count() > 0 )
  {
    local postal_engine_new = ea.Begin();
    if( this.postal_engine != postal_engine_new )
		{
			// Called on start to set the initial engine to build. Nothing to replace here.
			if( !ingame )
			{
				this.postal_engine = postal_engine_new;
			}
			// Force vehicles to go to depot when this was called by an event
			// but only when we have a service running at all.
			else if( this.postal_service_built )
			{
				this.postal_new_engine_available = true;

				// Update engine
				if( AIGroup.SetAutoReplace( this.group_id, this.postal_engine, postal_engine_new ))
				{
					debug( "New postal engine available. Updating postal service." );
					this.postal_engine = postal_engine_new;
				}
			}
		}
  }
}

/**Set engines available to be build to always have the newest model running.
   Also renew current vehicles and build new ones when available.
 */
function gelignAIte::ManageVehicles()
{
  // AutoRenew does not handle new engines. Send vehicles to depot for replacement.
  if( this.bus_new_engine_available )
  {
    // Get vehicles belonging to the bus service
    local vl = AIVehicleList();

    vl.Valuate( VehicleCargoValuator, "PASS" ); // True (1) for vehicles of type PASS, false (0) otherwise
    vl.KeepValue( 1 );                          // 1 == true == PASS

    // Send vehicles to depot if not already on their way to depot
    for( local v = vl.Begin(); vl.HasNext() ; v = vl.Next() )
    {
      // Do not send vehicle to depot if already on its way to it
      if( AIOrder.IsGotoDepotOrder( v, AIOrder.ORDER_CURRENT ))
      {
        // debug( "Vehicle (ID: " + v + ", Cargo: " + GetCargoLabel(v)+ ") is already on its way to depot for replacement." );
      }
      else
      {
        if( AIVehicle.SendVehicleToDepotForServicing( v ))
        {
          // debug( "Sending vehicle (ID: " + v + ", Cargo: " + GetCargoLabel(v)+ ") to depot for replacement with a newer model." );
        }
        else
        {
          debug( "Failed to send vehicle (ID: " + v + ", Cargo: " + GetCargoLabel(v)+ ") to depot. Reason: " + AIError.GetLastErrorString(), "error" );
        }
      }
    }

    // Do not send the vehicles twice
    this.bus_new_engine_available = false;
  }

  // Same as above but for vehicles belonging to the postal service
  // The if-else will replace the different types (bus/truck) sequentielly. Might work without the else, too.
  else if( this.postal_new_engine_available )
  {
    local vl = AIVehicleList();
    vl.Valuate( VehicleCargoValuator, "MAIL" ); // True (1) for vehicles of type MAIL, false (0) otherwise
    vl.KeepValue( 1 );                          // 1 == true == MAIL

    // Send vehicles to depot
    for( local v = vl.Begin(); vl.HasNext() ; v = vl.Next() )
    {
      // Do not send vehicle to depot if already on its way to it
      if( AIOrder.IsGotoDepotOrder( v, AIOrder.ORDER_CURRENT ))
      {
        // debug( "Vehicle (ID: " + v + ", Name: "+AIVehicle.GetName(v)+", Cargo: " + GetCargoLabel(v)+ ") is already on its way to depot for replacement." );
      }
      else
      {
        if( AIVehicle.SendVehicleToDepotForServicing( v ))
        {
          // debug( "Sending vehicle (ID: " + v + ", Name: "+AIVehicle.GetName(v)+", Cargo: " + GetCargoLabel(v)+ ") to depot for replacement with a newer model." );
        }
        else
        {
          debug( "Failed to send vehicle (ID: " + v + ", Name: "+AIVehicle.GetName(v)+", Cargo: " + GetCargoLabel(v)+ ") to depot. Reason: " + AIError.GetLastErrorString(), "error" );
        }
      }
    }

    // Do not send the vehicles twice
    this.postal_new_engine_available = false;
  }

  // Find vehicles being too old
  local vl = AIVehicleList();
  vl.Valuate( AIVehicle.GetAgeLeft );
  vl.KeepBelowValue( 1 );

  // Increase loan if we need to renew vehicles and don't have enough funds
  if( vl.Count() && AICompany.GetBankBalance( this.self ) < AICompany.GetAutoRenewMoney( this.self ) * 2 )
  {
    debug( "Raising funds to renew vehicles ..." );

    // Increase to max loan amount to increase the chance to make auto renew vehicles happen
    AICompany.SetLoanAmount( AICompany.GetMaxLoanAmount() );
  }
}

/**Try to always have as much funds as required for survival. Take loan where required, repay where possible.
 */
function gelignAIte::ManageFunds()
{
  local loan;
  local balance    = AICompany.GetBankBalance( this.self );
  local maxLoan    = AICompany.GetMaxLoanAmount();
  local loanAmount = AICompany.GetLoanAmount();
  local interval   = AICompany.GetLoanInterval();

  // Nothing loaned and positive balance => nothing to do
  if( loanAmount == 0 && balance > 0 )
    return;

  // Increase loan on a negative balance
  if( balance < 0 )
  {
    loan = loanAmount + ( -1 * balance / interval + 1 ) * interval;
    debug( "We seem to be low on funds with a current balance of " + balance + ".", "warning" );
    debug( "Raising funds to: " + loan, "warning" );
  }
  // We have some money. Check whether we can repay some.
  else
  {
    // Calculate new loan amount
    loan = loanAmount - balance / interval * interval;
    loan = max( 0, loan );
  }

  // Set loan if different from previous amount
  if( loan != loanAmount )
  {
    if( AICompany.SetLoanAmount( loan ))
    {
      debug( "Reset loan to now: " + loan );
    }
    else
    {
      debug( "Could not set loan to " + loan + ". Reason: " + AIError.GetLastErrorString(), "warning" );
    }
  }
}

/**Determine the biggest town in the map and returns its ID.
 */
function gelignAIte::BiggestTownAround()
{
  // Find biggest town around
  local town_list = AITownList();

  //if( debug() )  debug( "Finding biggest town around to start ..." );
  town_list.Valuate( AITown.GetPopulation );
  local bigtown_ID = town_list.Begin();
  //if( debug() )  debug( "...done. [Searching biggest town]" );
  //if( debug() )  debug( "Biggest town found is '" + AITown.GetName( bigtown_ID ) + "' with a current population of "+ AITown.GetPopulation( bigtown_ID ) + "." );

  return bigtown_ID;
}

/**As the town grows with the time move the uptown stations outwards
 */
function gelignAIte::UpdateStations()
{
  // Don't move stations if they are already at the most outside location.
  // For largest distance to town center see BuildStation()
  if( this.max_station_update )
    return;

  local now = AIDate.GetYear( AIDate.GetCurrentDate() );

  // Do nothing within 5 years
  if( now - this.last_station_update < 5 )
    return;

  // Reset timer
  this.last_station_update = now;
  debug( "Updating stations: Moving uptown stations outwards." );

  // Rebuild stations uptown
  // Rebuild only when we have a station of that type at all
  if( this.bus_station_uptown )
  {
    // Ensure we have money to do so
    AICompany.SetLoanAmount( AICompany.GetMaxLoanAmount() );

    // There might be a vehicle in the way so retry as long as the station could not be removed.
    while( !AIRoad.RemoveRoadStation( this.bus_station_uptown ))
    {
      this.Sleep( 10 );
    }
    this.bus_station_uptown = BuildStation( this.bus_town_id, AIRoad.ROADVEHTYPE_BUS, false );

    this.Sleep( 10 );
    // Redefine orders
    SetOrders( "PASS" );
  }

  // Rebuild only when we have a station of that type at all
  if( this.postal_station_uptown )
  {
    // Ensure we have money to do so
    AICompany.SetLoanAmount( AICompany.GetMaxLoanAmount() );

    // There might be a vehicle in the way so retry as long as the station could not be removed;
    while( !AIRoad.RemoveRoadStation( this.postal_station_uptown ))
    {
      this.Sleep( 10 );
    }
    this.postal_station_uptown = BuildStation( this.postal_town_id, AIRoad.ROADVEHTYPE_TRUCK, false );

    this.Sleep( 10 );
    // Redefine orders
    SetOrders( "MAIL" );
  }
}

/**Set orders
 */
function gelignAIte::SetOrders( cargo_type )
{
  local vl = AIVehicleList();
  vl.Valuate( VehicleCargoValuator, cargo_type );
  vl.KeepValue( 1 ); // 1 == PASS
  local v1 = vl.Begin();

  // Clear old orders (where present)
  while( AIOrder.GetOrderCount( v1 ))
  {
    AIOrder.RemoveOrder( v1, AIOrder.ORDER_CURRENT );
  }

  if( cargo_type == "PASS" )
  {
    AIOrder.AppendOrder( v1, this.bus_station_downtown, AIOrder.AIOF_FULL_LOAD );    // Load full downtown
    AIOrder.AppendOrder( v1, this.bus_station_uptown, AIOrder.AIOF_NONE );           // Do not uptown
  }
  else // MAIL
  {
    AIOrder.AppendOrder( v1, this.postal_station_downtown, AIOrder.AIOF_FULL_LOAD ); // Load full downtown
    AIOrder.AppendOrder( v1, this.postal_station_uptown, AIOrder.AIOF_NONE );        // Do not uptown
  }

  // Copy orders and start vehicles sequentially
  for( local v = vl.Begin(); vl.HasNext(); v = vl.Next() )
  {
    // Share orders
    AIOrder.ShareOrders( v, v1 );

    // Start vehicles (only when stopped in depot)
    if( AIVehicle.IsStoppedInDepot( v ))
    {
      if( !AIVehicle.StartStopVehicle( v ))
      {
        debug( "Failed to start vehicle " + v + ": " + AIError.GetLastErrorString(), "warning" );
      }

      // Spend some time between vehicles start their route
      this.Sleep( 100 );
    }
  }
}

/**Build up a bus service in the biggest town around.
 */
function gelignAIte::CreateBusService()
{
  // Don't call that function twice
  if( this.bus_service_built )
  {
    return;
  }
  this.bus_service_built = true;

  if( !this.bus_engine )
  {
    // No road vehicle for passenger transport available
    this.bus_service_built = false;
  }
  else
  {
    /*
       Build depot and stations. We assume the city is large enough so we don't need
       to build any streets. This may fail of course. :-/
     */

    // Get ID of the biggest town on the map
    this.bus_town_id = BiggestTownAround();

    // Get cash. Will be repayed by repeatedly called ManageFunds()
    AICompany.SetLoanAmount( AICompany.GetMaxLoanAmount() );

    // Build depot
    this.bus_depot_tile = BuildDepot( this.bus_town_id );

    if( this.bus_depot_tile )
    {
      // Build two stations
      this.bus_station_downtown = BuildStation( this.bus_town_id, AIRoad.ROADVEHTYPE_BUS, true );  // Downtown
      this.bus_station_uptown   = BuildStation( this.bus_town_id, AIRoad.ROADVEHTYPE_BUS, false ); // Uptown

			// Build vehicles and add them to vehicles group
      for( local v = 0; v < 2; v++ )
      {
        local veh_id = AIVehicle.BuildVehicle( this.bus_depot_tile, this.bus_engine );
        AIGroup.MoveVehicle( this.group_id, veh_id );
      }

      // Repay loan left
      ManageFunds();

      // Set orders
      SetOrders( "PASS" );
    }
  }
}

/**Build up a postal service in the biggest town around.
 */
function gelignAIte::CreatePostalService()
{
	// Don't call that function twice
	if( this.postal_service_built )
	{
		return;
	}
	this.postal_service_built = true;

	// Do not build the postal service if we don't have the money.
	// Too much loan will kill us (taxes too high). Only gain about 20 %.
	local currLoan = 1.0 * AICompany.GetLoanAmount() / AICompany.GetMaxLoanAmount();
	if( currLoan > 0.2 )
	{
		this.postal_service_built = false;
		return;
	}

	if( !this.postal_engine )
	{
		// No road vehicle for mail transport available
		this.postal_service_built = false;
	}
	else
	{
		/*
			 Build depot and stations. We assume the city is large enough so we don't need
			 to build any streets. This may fail of course. :-/
		 */
		// Get ID of the biggest town on the map
		this.postal_town_id = BiggestTownAround();

		// Check whether there is enough post to transfer at all. Don't start in a town with less than 9k inhabitants
		local inhabitants = AITown.GetPopulation( this.postal_town_id );
		if( inhabitants < 9000 )
		{
			this.postal_service_built = false;
			return;
		}

		// Get cash
		AICompany.SetLoanAmount( AICompany.GetMaxLoanAmount() );

		// Build depot
		this.postal_depot_tile = BuildDepot( this.postal_town_id );

		if( this.postal_depot_tile )
		{
			// Build two stations
			this.postal_station_downtown = BuildStation( this.postal_town_id, AIRoad.ROADVEHTYPE_TRUCK, true );  // Downtown
			this.postal_station_uptown   = BuildStation( this.postal_town_id, AIRoad.ROADVEHTYPE_TRUCK, false ); // Uptown

			// Build vehicles and add them to vehicles group
			for( local v = 0; v < 4; v++ )
			{
				local veh_id = AIVehicle.BuildVehicle( this.postal_depot_tile, this.postal_engine );
				AIGroup.MoveVehicle( this.group_id, veh_id );
			}

			// Repay loan left
			ManageFunds();

			// Set orders
			SetOrders( "MAIL" );
		}
	}
}
