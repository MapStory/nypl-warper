# API Access

There is an administrative API access to the application. Access is controlled via API keys.

All API methods have full permission to the site, and are intended only for use integrating the
site with MapStory.

The API is version 1, in the future there may be other versions. 

## Methods

### Get list of all maps
json formatted list that returns all maps that have been warped for a given user. 

This should include links to thumbnails, accuracy of warp, times, dates, etc.

Example: 

  GET /api/v1/maps.json



#### Filter by user

You can optionally filter all maps by if the user has added to "my maps". Supply the login
name, which will be the mapstory user id.

Example:
	


## Authentication

All API requests require an API key. This key should be passed
via a request header "X-API-KEY"

Example:

	curl -H "X-API-KEY: 31044b6c69cac20c530059b88e80fa8d" http://localhost:3000/api/v1/maps.json

If no API key, or an invalid API key, is passed in the API will return a 401 Unauthorized 
