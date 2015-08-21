function fixImageSmoothing(canvasId) {
  var canvasElement = document.getElementById(canvasId);
  
  if(canvasElement != null) {
    var ctx = canvasElement.getContext("2d");

    ctx.mozImageSmoothingEnabled = false;
    ctx.webkitImageSmoothingEnabled = false;
    ctx.msImageSmoothingEnabled = false;
    ctx.imageSmoothingEnabled = false;
  } else {
	console.log("Could not find canvas with id: " + canvasId);
  }
}
