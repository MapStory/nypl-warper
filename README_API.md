# API Access

There is an administrative API access to the application. Access is controlled via API keys.

All API methods have full permission to the site, and are intended only for use integrating the
site with MapStory.

The API is version 1, in the future there may be other versions. 

## Methods

### Get list of all warped maps
json formatted list that returns all maps that have been warped in the system. 

All relevant metadata is returned, including a "download" link to fetch the 
rectified geotiff image.

Example: 

  GET /api/v1/warped.json


#### Filter by user

You can optionally filter all maps by the "My maps" collection. By default
new maps will be added to that user's "my maps" collection.

Supply the login name, which will be the mapstory user id.

Example:
	
	GET /api/v1/warped.json?user=dlee

This will return 404 if the user can't be found

## Future methods

Currently fetching un-warped maps is not implemented. This may be useful if wanting to
direct users to maps that need work.

Fetching data about a specific map is not implemented. All relevant data is returned
with the list.


## Authentication

All API requests require an API key. This key should be passed
via a request header "X-API-KEY"

Example:

	curl -H "X-API-KEY: 31044b6c69cac20c530059b88e80fa8d" http://localhost:3000/api/v1/warped.json

If no API key, or an invalid API key, is passed in the API will return a 401 Unauthorized 
