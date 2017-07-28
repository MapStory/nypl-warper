# Used for fetching wms data
class Wms

	# Pass in
	# ows - preference settings object
	# status - "unwarped" or something else
	# map - needed for id and filenames
	def self.dispatch(ows, status, map)

		# Define here so we can return outside of instrumentation block
		result_data = nil
		content_type = nil

		ActiveSupport::Notifications.instrument("wms.dispatch", map_id: map.id, status: status) do
			mapsv = Mapscript::MapObj.new(File.join(Rails.root, '/lib/mapserver/wms.map'))
			projfile = File.join(Rails.root, '/lib/proj')
			mapsv.setConfigOption("PROJ_LIB", projfile)
			#map.setProjection("init=epsg:900913")
			mapsv.applyConfigOptions
			mapsv.setMetaData("wms_onlineresource", "#{Rails.configuration.wms_base}#{map.id}")
			
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
		end

		return [result_data, content_type]
	end


end