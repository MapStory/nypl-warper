json.maps @maps do |map|
	# Basic metadata
	json.id map.id
  json.title map.title
  json.description map.description
  
  # Status, with friendly parsing
  #json.warped map.warped?
  
  # Might want to call bounds here instead - would fall back if un-warped?
  json.bbox map.bbox


  # Number of control points
  json.control_point_count map.gcps.hard.size


  # Thumbnail image
  json.map_thumb thumb_map_url(map.id)


  # Links back
  json.map_page map_url(map.id)
  json.download download_map_url(map.id)
  # Add in direct link to rectify?

  # timestamps
  json.created_at map.created_at
  json.updated_at map.updated_at
  json.rectified_at map.rectified_at
  json.gcp_touched_at map.gcp_touched_at
  json.upload_updated_at map.upload_updated_at

  # Human readable time
  json.last_modified "#{time_ago_in_words(map.updated_at)} ago"

  # List of users that have saved this map?

end