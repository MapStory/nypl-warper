# Used for fetching wms data
class Wms

	def self.dispatch(ows, status, request, map)

    mapsv = Mapscript::MapObj.new(File.join(Rails.root, '/lib/mapserver/wms.map'))
    projfile = File.join(Rails.root, '/lib/proj')
    mapsv.setConfigOption("PROJ_LIB", projfile)
    #map.setProjection("init=epsg:900913")
    mapsv.applyConfigOptions
    rel_url_root =  (ActionController::Base.relative_url_root.blank?)? '' : ActionController::Base.relative_url_root
    
    mapsv.setMetaData("wms_onlineresource",
      "http://" + request.host_with_port + rel_url_root + "/maps/wms/#{map.id}")
    
    raster = Mapscript::LayerObj.new(mapsv)
    raster.name = "image"
    raster.type = Mapscript::MS_LAYER_RASTER
    raster.addProcessing("RESAMPLE=BILINEAR")

    if status == "unwarped"
      raster.data = map.unwarped_filename  
    else #show the warped map
      raster.data = map.warped_filename
    end
    
    raster.status = Mapscript::MS_ON
    raster.dump = Mapscript::MS_TRUE
    raster.metadata.set('wcs_formats', 'GEOTIFF')
    raster.metadata.set('wms_title', map.title)
    raster.metadata.set('wms_srs', 'EPSG:4326 EPSG:3857 EPSG:4269 EPSG:900913')
    #raster.debug = Mapscript::MS_TRUE
    raster.setProcessingKey("CLOSE_CONNECTION", "ALWAYS")
    
    Mapscript::msIO_installStdoutToBuffer
    mapsv.OWSDispatch(ows)
    content_type = Mapscript::msIO_stripStdoutBufferContentType || "text/plain"
    result_data = Mapscript::msIO_getStdoutBufferBytes
    Mapscript::msIO_resetHandlers

    return [result_data, content_type]
	end


end