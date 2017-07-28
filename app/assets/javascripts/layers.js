

//function used with osm mapnik tiles
// Note this function is defined twice...
function osm_getTileURL(bounds) {
    var res = this.map.getResolution();
    var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
    var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
    var z = this.map.getZoom();
    var limit = Math.pow(2, z);

    if (y < 0 || y >= limit) {
        return OpenLayers.Util.getImagesLocation() + "404.png";
    } else {
        x = ((x % limit) + limit) % limit;
        return this.url + z + "/" + x + "/" + y + "." + this.type;
    }
}


// This is the default style
var mapnik = new OpenLayers.Layer.OSM("OSM Mapnik", ["http://a.tile.openstreetmap.org/${z}/${x}/${y}.png", 
  "http://b.tile.openstreetmap.org/${z}/${x}/${y}.png", "http://c.tile.openstreetmap.org/${z}/${x}/${y}.png"],{
    displayOutsideMaxExtent: false,
    transitionEffect: 'resize',
    numZoomLevels: 20,
    attribution: '&copy <a href="http://www.openstreetmap.org/">OpenStreetMap</a> contributors'
});
