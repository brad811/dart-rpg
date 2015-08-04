function fixImageSmoothing() {
  console.log("Fixing image smoothing...");
  var canvasElements = document.getElementsByTagName("canvas");
  for(var i=0; i<canvasElements.length; i++) {
    var ctx = canvasElements[i].getContext("2d");

    ctx.mozImageSmoothingEnabled = false;
    ctx.webkitImageSmoothingEnabled = false;
    ctx.msImageSmoothingEnabled = false;
    ctx.imageSmoothingEnabled = false;
  }
}

window.onload = function() {
  fixImageSmoothing();
}
