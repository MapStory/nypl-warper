var warpedmap;
var warped_wmslayer;
var maxOpacity = 1;
var minOpacity = 0.1;

maps['warped'] = {};
maps['warped'].zoomWheel = new OpenLayers.Control.Navigation( { zoomWheelEnabled: false } );
maps['warped'].panZoomBar = new OpenLayers.Control.PanZoomBar();
maps['warped'].keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' });

maps['warped'].newZoom = null;
maps['warped'].oldZoom = null;

maps['warped'].resolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18] // not applied at the moment

maps['warped'].active = false;
maps['warped'].deactivate = function(){
  //console.log('warped deactivate');
  maps['warped'].keyboard.deactivate();
  maps['warped'].active = false;
}
maps['warped'].activate = function(){
  //console.log('warped activate');
  maps['warped'].keyboard.activate();
  maps['warped'].active = true;
  currentMaps = ['warped'];
  warped_updateSize();
}


function warpedinit() {
    OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
    OpenLayers.Util.onImageLoadErrorColor = "transparent";

    var options_warped = {
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326"),
        units: "m",

        maxExtent: new OpenLayers.Bounds(-20037508, -20037508,
            20037508, 20037508.34),
        controls: [
            new OpenLayers.Control.Attribution(),
            new OpenLayers.Control.LayerSwitcher(),
            maps['warped'].zoomWheel,
            maps['warped'].panZoomBar,
            maps['warped'].keyboard
        ]
    };

    warpedmap = new OpenLayers.Map('warpedmap', options_warped);

    maps['warped'].map = warpedmap;

    warpedmap.events.register("zoomend", warpedmap, function(){

      if (warpedmap.zoom < maps['warped'].newZoom){
        maps['warped'].newZoom = warpedmap.zoom + 0.5;
      } else {
        maps['warped'].newZoom = warpedmap.zoom;
      }
    });


    // create OSM layer
    mapnik3 = mapnik.clone();
    warpedmap.addLayer(mapnik3);
    
    //ny_2014_clone = ny_2014.clone();
    //warpedmap.addLayer(ny_2014_clone);
    
    for (var i = 0; i < layers_array.length; i++) {
        warpedmap.addLayer(get_map_layer(layers_array[i]));
    }

    var warped_wms_url = warpedwms_url;

    warped_wmslayer = new OpenLayers.Layer.WMS("warped image",
        warped_wms_url, {
            format: 'image/png',
            status: 'warped'
        }, {
            TRANSPARENT: 'true',
            reproject: 'true',
            transitionEffect: null // Per docs, "Using 'resize' on non-opaque layers can cause undesired visual effects."
        }, {
            gutter: 15,
            buffer: 0
        }, {
            projection: "epsg:4326",
            units: "m"
        }
    );
    var opacity = .7;
    warped_wmslayer.setOpacity(opacity);
    warped_wmslayer.setIsBaseLayer(false);
    warpedmap.addLayer(warped_wmslayer);

    clipmap_bounds_merc = warped_bounds.transform(warpedmap.displayProjection, warpedmap.projection);

    //set up slider
    jQuery("#slider").slider({
        value: 100 * opacity,
        range: "min",
        slide: function(e, ui) {
            warped_wmslayer.setOpacity(ui.value / 100);
            OpenLayers.Util.getElement('opacity').value = ui.value;
        }
    });

    window.addEventListener("resize", warped_updateSize);
    warped_updateSize();

    // after expanding map area zoom in
    warpedmap.zoomToExtent(clipmap_bounds_merc);

}

function get_map_layer(layerid) {
    var newlayer_url = layer_baseurl + "/" + layerid;
    var map_layer = new OpenLayers.Layer.WMS("Layer " + layerid,
        newlayer_url, {
            format: 'image/png'
        }, {
            TRANSPARENT: 'true',
            reproject: 'true'
        }, {
            gutter: 15,
            buffer: 0
        }, {
            projection: "epsg:4326",
            units: "m"
        }
    );
    map_layer.setIsBaseLayer(false);
    map_layer.visibility = false;

    return map_layer;
}

function changeOpacity(byOpacity) {
    var newOpacity = (parseFloat(OpenLayers.Util.getElement('opacity').value) + byOpacity).toFixed(1);
    newOpacity = Math.min(maxOpacity,
        Math.max(minOpacity, newOpacity));
    OpenLayers.Util.getElement('opacity').value = newOpacity;
    wmslayer.setOpacity(newOpacity);
}


function warped_updateSize() {
  //console.log('warped_updateSize')

  var headerSpace = 130

  var minHeight = 500;
  var calculatedHeight = Number(window.innerHeight - headerSpace);
  if (calculatedHeight < minHeight){
    calculatedHeight = minHeight;
  }

  warpedmap.div.style.height = calculatedHeight + "px";
  warpedmap.div.style.width = "100%";
  warpedmap.updateSize();

  // calculate the distance from the top of the browser to the top of the tabs to set the scroll position correctly
  var ele = document.getElementById("wooTabs");
  var offsetFromTop = 0;
  while(ele){
     offsetFromTop += ele.offsetTop;
     ele = ele.offsetParent;
  }

  //window.scrollTo(0, offsetFromTop);

  //animate the scroll position transition
  jQuery('html, body').clearQueue();
  jQuery('html, body').animate({
        scrollTop: offsetFromTop
    }, 500);

  // clear preset height if one was set
  setTimeout( removePlaceholderHeight, 500);

}
