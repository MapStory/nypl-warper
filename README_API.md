# API Access

There is an administrative API access to the application. Access is controlled via API keys.

All API methods have full permission to the site, and are intended only for use integrating the
site with MapStory.

The API is version 1, in the future there may be other versions. 

## Methods

### Get list of warped maps for user
json formatted list that returns all maps that have been warped for a given user. 

This should include links to thumbnails, accuracy of warp, times, dates, etc.


### Get warped map by map id
json formatted metadata about the map (thumbs, accuracy, dates, etc) including a link
to the geotif file for download.


## Authentication

All API requests require an API key. This key should be passed
via a request header "X-API-KEY"

	curl -H "X-API-KEY: 31044b6c69cac20c530059b88e80fa8d" http://localhost:3000/api/v1/maps