# TripLogger

Use Core Location and Core Data frameworks; <br />

Core Data framework: <br /> 
1. Use it to save the trip information in the SQLite database in the device <br />
2. Use NSFetchedResultsController + UITableView to load/add/delete trip information item <br />

Core Location framework: <br />
1. When update location, check the location.speed, if it is greater than 10 mph, start recording (just remember the start point) <br />
2. When update location, if start point is recorded and the distance between current one and the one remembered one minute ealier is less than 20 meters, consider device is still <br />
3. Use start point from 1 and end point from 2 to add a record to data base (use CLGeocoder to get the address number and street name) <br />
4. In background mode, I use two timers to reduce the frequency calling -didUpdateLocations (I tried -allowDeferredLocationUpdatesUntilTraveled:timeout:, but it seems doesn't work on simulator) <br />
5. In order to enable the background location update, I update the project settings: Capabilities-Background Modes-Location udpates, and call -allowsBackgroundLocationUpdates <br />
6. In background mode, I use -beginBackgroundTaskWithExpirationHandler: if needed (What I actually read is that if I do 5, I don't need this step) <br />
