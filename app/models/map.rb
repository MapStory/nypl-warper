require "open3"
require "error_calculator"
require 'rmagick'

include ErrorCalculator
class Map < ActiveRecord::Base
  include Tilestache
    
  has_many :gcps,  :dependent => :destroy
  has_many :layers_maps,  :dependent => :destroy
  has_many :layers, :through => :layers_maps # ,:after_add, :after_remove
  has_many :my_maps, :dependent => :destroy
  has_many :users, :through => :my_maps
  #belongs_to :owner, :class_name => "User"

  # I think parent is only for inset maps, which have been removed.
  belongs_to :parent, :class_name => "Map", :foreign_key => "parent_id"
   
  validates_presence_of :title
  validates_numericality_of :rough_lat, :rough_lon, :rough_zoom, :allow_nil => true

  has_attached_file :upload, :styles => {:thumb => ["256x256>", :png]} ,
    :url => '/:attachment/:id/:style/:hash.:extension',
    :hash_secret => Rails.application.secrets.secret_key_base
    
  validates_attachment_size(:upload, :less_than => MAX_ATTACHMENT_SIZE) if defined?(MAX_ATTACHMENT_SIZE)
  validates_attachment_content_type :upload, content_type: /\Aimage\/.*\z/

  # We don't really use published, or publishing anymore...
  enum status: [:unloaded, :loading, :available, :warping, :warped, :published, :publishing]
  enum mask_status: [:unmasked, :masking, :masked]
  enum rough_state: [:step_1, :step_2, :step_3, :step_4]

  has_paper_trail :ignore => [:bbox, :bbox_geom]
    
  attr_accessor :error

  after_initialize :default_values

  after_destroy :delete_images
  after_destroy :delete_map, :update_counter_cache, :update_layers
  after_save :update_counter_cache
  
  # Really we might want this on only before_create...
  before_save :extract_dimensions

  ##################
  # CALLBACKS
  ###################
  
  def default_values
    self.status  ||= :unloaded  
    self.mask_status  ||= :unmasked  
    self.rough_state ||= :step_1  
  end
  
  
  # paperclip plugin deletes the images when model is destroyed
  # we just need to take care of things paperclip isn't aware of.
  def delete_images
    logger.info "Deleting map images"
    if File.exists?(temp_filename)
      logger.info "deleted temp"
      File.delete(temp_filename)
    end
    if File.exists?(warped_filename)
      logger.info "Deleted Map warped"
      File.delete(warped_filename)
    end
    if File.exists?(warped_png_filename)
      logger.info "deleted warped png"
      File.delete(warped_png_filename)
    end
  end
  
  def delete_map
    #logger.info "Deleting mapfile"
  end
  
  def update_layer
    self.layers.each do |layer|
      layer.update_layer
    end unless self.layers.empty?
  end
  
  def update_layers
    logger.info "updating (visible) layers"
    unless self.layers.visible.empty?
      self.layers.visible.each  do |layer|
        layer.update_layer
      end
    end
  end
  
  def update_counter_cache
    logger.info "update_counter_cache"
    unless self.layers.empty?
      self.layers.each do |layer|
        layer.update_counts
      end
    end
  end
  
  def update_gcp_touched_at
    self.touch(:gcp_touched_at)
  end
  
  #method to publish the map
  #sets status to published
  def publish
    self.paper_trail_event = 'publishing'
    self.status = :publishing
    self.save
    
    Spawnling.new(:nice => 7) do
      begin
        if self.tilestache_seed  #in tilestache concern
          self.paper_trail_event = 'published'
          self.status = :published
          self.save
        else
          self.paper_trail_event = 'fail_publish'
          self.status = :warped
          self.save
        end
      rescue Exception => e
        logger.error e.inspect
        self.paper_trail_event = 'fail_publish'
        self.status = :warped
        self.save
      end
      self.paper_trail_event = nil
      
    end #spawnling fork
    
  end
  
  #unpublishes a map, sets it's status to warped
  def unpublish
    self.paper_trail_event = 'unpublished'
    self.status = :warped
    self.save
    self.paper_trail_event = nil
  end
  
  #############################################
  #CLASS METHODS
  #############################################
  
  def self.max_attachment_size
    max_attachment_size =  defined?(MAX_ATTACHMENT_SIZE)? MAX_ATTACHMENT_SIZE : nil
  end
  
  def self.max_dimension
    max_dimension = defined?(MAX_DIMENSION)? MAX_DIMENSION : nil
  end
  
  #############################################
  #ACCESSOR METHODS
  #############################################

  def maps_dir
    defined?(SRC_MAPS_DIR) ? SRC_MAPS_DIR :  File.join(Rails.root, "/public/mapimages/src/")
  end

  def dest_dir
    defined?(DST_MAPS_DIR) ?  DST_MAPS_DIR : File.join(Rails.root, "/public/mapimages/dst/")
  end


  def warped_dir
    dest_dir
  end

  # Return the path to what was uploaded? (or does this have to be a tif?)
  def unwarped_filename
    self.upload.path
  end

  def warped_filename
    File.join(warped_dir, id.to_s) + ".tif"
  end

  def warped_png_dir
    File.join(dest_dir, "/png/")
  end

  def warped_png
    unless File.exists?(warped_png_filename)
      convert_to_png
    end
    warped_png_filename
  end
  
  def warped_png_filename
    filename = File.join(warped_png_dir, id.to_s) + ".png"
  end

  def warped_png_aux_xml
    warped_png + ".aux.xml"
  end


  def mask_file_format
    "gml"
  end

  def temp_filename
    # self.full_filename  + "_temp"
    File.join(warped_dir, id.to_s) + "_temp"
  end

  def mask_dir
    
  end
  
  def masking_file_gml
    File.join(MASK_DIR,  self.id.to_s) + ".gml"
  end

  #file made when rasterizing
  def masking_file_gfs
    File.join(MASK_DIR,  self.id.to_s) + ".gfs"
  end

  def masked_src_filename
    self.unwarped_filename + "_masked";
  end
    
  #############################################
  #INSTANCE METHODS
  #############################################
    

  def available?
    return [:available,:warping, :warped, :published].include?(status.to_sym)
  end

  # At some point rails switched from strings to symbols.
  # unsure what version, but our current version is old
  # enough to be using strings. Convert to symbol here
  def warped_or_published?
    return [:warped, :published].include?(status.to_sym)
  end
    
  def last_changed
    if self.gcps.size > 0
      self.gcps.last.created_at
    elsif !self.updated_at.nil?
      self.updated_at
    elsif !self.created_at.nil?
      self.created_at
    else
      Time.now
    end
  end
  
  def save_rough_centroid(lon,lat)
    self.rough_centroid =  Point.from_lon_lat(lon,lat)
    self.save
  end
  
  def save_bbox
    stdin, stdout, stderr = Open3::popen3("#{GDAL_PATH}gdalinfo #{warped_filename}")
    unless stderr.readlines.to_s.size > 0
      info = stdout.readlines.to_s
      string,west,south = info.match(/Lower Left\s+\(\s*([-.\d]+),\s+([-.\d]+)/).to_a
      string,east,north = info.match(/Upper Right\s+\(\s*([-.\d]+),\s+([-.\d]+)/).to_a
      self.bbox = [west,south,east,north].join(",")
    else
      logger.debug "Save bbox error "+ stderr.readlines.to_s
    end
  end
  
  def bounds
    if bbox.nil?
      x_array = []
      y_array = []
      self.gcps.hard.each do |gcp|
        #logger.info "GCP lat #{gcp[:lat]} , lon #{gcp[:lon]} "
        x_array << gcp[:lat]
        y_array << gcp[:lon]
      end
      #south, west, north, east
      our_bounds = [y_array.min ,x_array.min ,y_array.max, x_array.max].join ','
    else
      bbox
    end
  end
  
  
  #returns a GeoRuby polygon object representing the bounds
  def bounds_polygon
    bounds_float  = bounds.split(',').collect {|i| i.to_f}
    Polygon.from_coordinates([ [bounds_float[0..1]] , [bounds_float[2..3]] ], -1)
  end
  
  def converted_bbox
    bnds = self.bounds.split(",")
    cbounds = []
    c_in, c_out, c_err =
      Open3::popen3("echo #{bnds[0]} #{bnds[1]} | cs2cs +proj=latlong +datum=WGS84 +to +proj=merc +ellps=sphere +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0")
    info = c_out.readlines.to_s
    string,cbounds[0], cbounds[1] = info.match(/([-.\d]+)\s*([-.\d]+).*/).to_a
    c_in, c_out, c_err =
      Open3::popen3("echo #{bnds[2]} #{bnds[3]} | cs2cs +proj=latlong +datum=WGS84 +to +proj=merc +ellps=sphere +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0")
    info = c_out.readlines.to_s
    string,cbounds[2], cbounds[3] = info.match(/([-.\d]+)\s*([-.\d]+).*/).to_a
    cbounds.join(",")
  end
  
  #attempts to align based on the extent and offset of the
  #reference map's warped image
  #results it nicer gcps to edit with later
  def align_with_warped(srcmap, align = nil, append = false)
    srcmap = Map.find(srcmap)
    origgcps = srcmap.gcps.hard

    #clear out original gcps, unless we want to append the copied gcps to the existing ones
    self.gcps.hard.destroy_all unless append == true

    #extent of source from gdalinfo
    stdin, stdout, sterr = Open3::popen3("#{GDAL_PATH}gdalinfo #{srcmap.warped_filename}")
    info = stdout.readlines.to_s
    stringLW,west,south = info.match(/Lower Left\s+\(\s*([-.\d]+), \s+([-.\d]+)/).to_a
    stringUR,east,north = info.match(/Upper Right\s+\(\s*([-.\d]+), \s+([-.\d]+)/).to_a

    lon_shift = west.to_f - east.to_f
    lat_shift = south.to_f - north.to_f

    origgcps.each do |gcp|
      a =  Gcp.new(gcp.attributes.except("id"))
      if align == "east"
        a.lon -= lon_shift
      elsif align == "west"
        a.lon += lon_shift
      elsif align == "north"
        a.lat -= lat_shift
      elsif align == "south"
        a.lat += lat_shift
      else
        #if no align, then dont change the gcps
      end
      a.map = self
      a.save
    end

    newgcps = self.gcps.hard
  end

  #attempts to align based on the width and height of
  #reference map's un warped image
  #results it potential better fit than align_with_warped
  #but with less accessible gpcs to edit
  def align_with_original(srcmap, align = nil, append = false)
    srcmap = Map.find(srcmap)
    origgcps = srcmap.gcps

    #clear out original gcps, unless we want to append the copied gcps to the existing ones
    self.gcps.hard.destroy_all unless append == true

    origgcps.each do |gcp|
      new_gcp = Gcp.new(gcp.attributes.except("id"))
      if align == "east"
        new_gcp.x -= srcmap.width

      elsif align == "west"
        new_gcp.x += srcmap.width
      elsif align == "north"
        new_gcp.y += srcmap.height
      elsif align == "south"
        new_gcp.y -= srcmap.height
      else
        #if no align, then dont change the gcps
      end
      logger.debug new_gcp.inspect
      new_gcp.map = self
      logger.debug new_gcp.inspect
      new_gcp.save
    end

    newgcps = self.gcps.hard
  end
  
  # map gets error attibute set and gcps get error attribute set
  def gcps_with_error(soft=nil)
    unless soft == 'true'
      gcps = Gcp.hard.where(["map_id = ?", self.id]).order(:created_at)
    else
      gcps = Gcp.soft.where(["map_id = ?", self.id]).order(:created_at)
    end
    gcps, map_error = ErrorCalculator::calc_error(gcps)
    @error = map_error
    #send back the gpcs with error calculation
    gcps
  end

  def mask!
    require 'fileutils'
    self.paper_trail_event = 'masking'
    self.mask_status = :masking
    save!
    format = self.mask_file_format
    
    if format == "gml"
      return "no masking file found, have you created a clipping mask and saved it?"  if !File.exists?(masking_file_gml)
      masking_file = self.masking_file_gml
      layer = "features"
    else
      return "no masking file matching specified format found."
    end
    
    masked_src_filename = self.masked_src_filename
    if File.exists?(masked_src_filename)
      #deleting old masked image
      File.delete(masked_src_filename)
    end
    #copy over orig to a new unmasked file
    FileUtils.copy(unwarped_filename, masked_src_filename)
    
    
    command = "#{GDAL_PATH}gdal_rasterize -i  -burn 17 -b 1 -b 2 -b 3 #{masking_file} -l #{layer} #{masked_src_filename}"
    r_stdout, r_stderr = Open3.capture3( command )
    logger.info command
    
    r_out  = r_stdout
    r_err = r_stderr
    
    #if there is an error, and it's not a warning about SRS
    if !r_err.blank? #&& r_err.split[0] != "Warning"
      #error, need to fail nicely
      logger.error "ERROR gdal rasterize script: "+ r_err
      logger.error "Output = " +r_out
      r_out = "ERROR with gdal rasterise script: " + r_err + "<br /> You may want to try it again? <br />" + r_out
    else
      r_out = "Success! Map was cropped!"
    end
    
    self.paper_trail_event = 'masked'
    self.mask_status = :masked
    save!
    self.paper_trail_event = nil
    
    r_out
  end
  
  
  
  # FIXME -clear up this method - don't return the text, just raise execption if necessary
  #
  # gdal_rasterize -i -burn 17 -b 1 -b 2 -b 3 SSS.json -l OGRGeoJson orig.tif
  # gdal_rasterize -burn 17 -b 1 -b 2 -b 3 SSS.gml -l features orig.tif

  #Main warp method
  def warp!(resample_option, transform_option, use_mask="false")
    prior_status = self.status
    self.status = :warping
    self.paper_trail_event = 'warping'
    save!
    self.paper_trail_event = nil
    
    gcp_array = self.gcps.hard
    
    gcp_string = ""
    
    gcp_array.each do |gcp|
      gcp_string = gcp_string + gcp.gdal_string
    end
    
    mask_options = ""
    if use_mask == "true" && self.mask_status == :masked
      src_filename = self.masked_src_filename
      mask_options = " -srcnodata '17 17 17' "
    else
      src_filename = self.unwarped_filename
    end
    
    dest_filename = self.warped_filename
    temp_filename = self.temp_filename
    
    #delete existing temp images @map.delete_images
    if File.exists?(dest_filename)
      #logger.info "deleted warped file ahead of making new one"
      File.delete(dest_filename)
    end
    
    logger.info "gdal translate"
  
    command = "#{GDAL_PATH}gdal_translate -a_srs '+init=epsg:4326' -of VRT #{src_filename} #{temp_filename}.vrt #{gcp_string}"
    t_stdout, t_stderr = Open3.capture3( command )
    
    logger.info command
    
    t_out  = t_stdout
    t_err = t_stderr
    
    if !t_err.blank?
      logger.error "ERROR gdal translate script: "+ t_err
      logger.error "Output = " +t_out
      t_out = "ERROR with gdal translate script: " + t_err + "<br /> You may want to try it again? <br />" + t_out
    else
      t_out = "Okay, translate command ran fine! <div id = 'scriptout'>" + t_out + "</div>"
    end
    trans_output = t_out
    
    memory_limit =  (defined?(GDAL_MEMORY_LIMIT)) ? "-wm "+GDAL_MEMORY_LIMIT.to_s :  ""
    
    #check for colorinterop=pal ? -disnodata 255 or -dstalpha
    command = "#{GDAL_PATH}gdalwarp #{memory_limit}  #{transform_option}  #{resample_option} -dstalpha #{mask_options} -s_srs 'EPSG:4326' #{temp_filename}.vrt #{dest_filename} -co TILED=YES -co COMPRESS=LZW"
    w_stdout, w_stderr = Open3.capture3( command )
    logger.info command
    
    w_out = w_stdout
    w_err = w_stderr
    if !w_err.blank?
      logger.error "Error gdal warp script" + w_err
      logger.error "output = "+w_out
      w_out = "error with gdal warp: "+ w_err +"<br /> try it again?<br />"+ w_out
    else
      w_out = "Okay, warp command ran fine! <div id='scriptout'>" + w_out +"</div>"
    end
    warp_output = w_out
    
    # gdaladdo
    command = "#{GDAL_PATH}gdaladdo -r average #{dest_filename} 2 4 8 16 32 64"
    o_stdout, o_stderr = Open3.capture3( command )
    logger.info command
    
    o_out = o_stdout
    o_err = o_stderr
    if !o_err.blank? 
      logger.error "Error gdal overview script" + o_err
      logger.error "output = "+o_out
      o_out = "error with gdal overview: "+ o_err +"<br /> try it again?<br />"+ o_out
    else
      o_out = "Okay, overview command ran fine! <div id='scriptout'>" + o_out +"</div>"
    end
    overview_output = o_out
    
    if File.exists?(temp_filename + '.vrt')
      logger.info "deleted temp vrt file"
      File.delete(temp_filename + '.vrt')
    end
    
    # don't care too much if overviews threw a random warning
    if w_err.size <= 0 and t_err.size <= 0
      if prior_status == :published
        self.status = :published
      else
        self.status = :warped
      end
      Spawnling.new do
        convert_to_png
      end
      self.touch(:rectified_at)
    else
      self.status = :available
    end
    self.paper_trail_event = 'warped'
    save!
    self.paper_trail_event = nil
    
    update_layers
    update_bbox
    output = "Step 1: Translate: "+ trans_output + "<br />Step 2: Warp: " + warp_output + \
      "Step 3: Add overviews:" + overview_output
  end
  
  def update_bbox
    
    if File.exists? self.warped_filename
      logger.info "updating bbox..."
      begin
        extents = get_raster_extents self.warped_filename
        self.bbox = extents.join ","
        logger.debug "SAVING BBOX GEOM"
        poly_array = [
          [ extents[0], extents[1] ],
          [ extents[2], extents[1] ],
          [ extents[2], extents[3] ],
          [ extents[0], extents[3] ],
          [ extents[0], extents[1] ]
        ]

        self.bbox_geom = GeoRuby::SimpleFeatures::Polygon.from_coordinates([poly_array]).as_wkt

        save
      rescue Exception => e
        logger.debug e.inspect
      end
    end
  end
  
  def delete_mask
    logger.info "delete mask"
    if File.exists?(self.masking_file_gml)
      File.delete(self.masking_file_gml)
    end
    if File.exists?(self.masking_file_gml+".ol")
      File.delete(self.masking_file_gml+".ol")
    end
    if File.exists?(self.masking_file_gfs)
      File.delete(self.masking_file_gfs)
    end
    
    self.mask_status = :unmasked
    self.paper_trail_event = 'mask_deleted'
    save!
    self.paper_trail_event = nil
    
    "mask deleted"
  end
  
  
  def save_mask(vector_features)
    if self.mask_file_format == "gml"
      msg = save_mask_gml(vector_features)
    else
      msg = "Mask format unknown"
    end
    msg
  end
  
  
  #parses geometry from openlayers, and saves it to file.
  #GML format
  def save_mask_gml(features)
    require 'rexml/document'
    if File.exists?(self.masking_file_gml)
      File.delete(self.masking_file_gml)
    end
    if File.exists?(self.masking_file_gml+".ol")
      File.delete(self.masking_file_gml+".ol")
    end
    if File.exists?(self.masking_file_gfs)
      File.delete(self.masking_file_gfs)
    end
    origfile = File.new(self.masking_file_gml+".ol", "w+")
    origfile.puts(features)
    origfile.close
    
    doc = REXML::Document.new features
    REXML::XPath.each( doc, "//gml:coordinates") { | element|
      # blimey element.text.split(' ').map {|i| i.split(',')}.map{ |i| i[0] => i[1]}.inject({}){|i,j| i.merge(j)}
      coords_array = element.text.split(' ')
      new_coords_array = Array.new
      coords_array.each do |coordpair|
        coord = coordpair.split(',')
        coord[1] = self.height - coord[1].to_f
        newcoord = coord.join(',')
        new_coords_array << newcoord
      end
      element.text = new_coords_array.join(' ')
      
    } #element
    gmlfile = File.new(self.masking_file_gml, "w+")
    doc.write(gmlfile)
    gmlfile.close
    message = "Map clipping mask saved (gml)"
  end
   
  ############
  #PRIVATE
  ############
  
  # Grabs uploaded file dimensions.
  # call with before_save
  def extract_dimensions
    tempfile = upload.queued_for_write[:original]
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(tempfile)
      self.height = geometry.height.to_i
      self.width = geometry.width.to_i
    end
    #img = Magick::Image.ping(filename)
    #self.height       = img[0].rows
    #self.width        = img[0].columns
  end


  def convert_to_png
    logger.info "start convert to png ->  #{warped_png_filename}"
    ext_command = "#{GDAL_PATH}gdal_translate -of png #{warped_filename} #{warped_png_filename}"
    stdout, stderr = Open3.capture3( ext_command )
    logger.debug ext_command
    if !stderr.blank?
      logger.error "ERROR convert png #{warped_filename} -> #{warped_png_filename}"
      logger.error stderr
      logger.error stdout
    else
      logger.info "end, converted to png -> #{warped_png_filename}"
    end
  end


  def find_bestguess_places
    yql = Yql::Client.new
    query = Yql::QueryBuilder.new 'geo.placemaker'

    query.conditions = {:documentContent => ERB::Util.h(self.title.to_s) + " "+ ERB::Util.h(self.description.to_s), :documentType => "text/plain", :appid => APP_CONFIG['yahoo_app_id'] }
    yql.query = query
    yql.format = "json"
    begin
      resp = yql.get
      data = resp.show.to_s

      results = JSON.parse(data)

      places = Array.new
      if results["query"]["results"]["matches"]
        found_places = results["query"]["results"]["matches"]["match"]
        max_lat, max_lon, min_lat, min_lon = -90.0, -180.0, -90.0, 180.0
        found_places = [found_places] if found_places.is_a?(Hash)
        found_places.each do | found_place |
          place = found_place["place"]
          place_hash = Hash.new
          place_hash[:name] = place['name']
          lon =  place['centroid']['longitude']
          lat =  place['centroid']['latitude']
          place_hash[:lon] = lon
          place_hash[:lat] = lat
          places << place_hash

          max_lat = lat.to_f if lat.to_f > max_lat
          min_lat = lat.to_f if lat.to_f < min_lat
          max_lon = lon.to_f if lon.to_f > max_lon
          min_lon = lon.to_f if lon.to_f < min_lon
        end

        extents =  [min_lon, min_lat, max_lon, max_lat].join(',')

        if !self.layers.visible.empty? && !self.layers.visible.first.maps.warped.empty?
          sibling_extent = self.layers.visible.first.maps.warped.last.bbox
        else
          sibling_extent = nil
        end

        placemaker_result = {:status => "ok", :map_id => self.id, :extents => extents, :count => places.size, :places => places, :sibling_extent=> sibling_extent}

      else
        placemaker_result = {:status => "fail", :code => "no results"}
      end

    rescue SocketError => e
      logger.error "Socket error in find bestguess places" + e.to_s
      placemaker_result = {:status => "fail", :code => "socketError"}
    rescue Exception =>e
      logger.error "Exception in find bestguess places" + e.to_s
      placemaker_result = {:status => "fail", :code => "socketError"}
    end
    
    placemaker_result
  end

  
  
end
