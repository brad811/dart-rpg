var c = $("canvas")[0];
var ctx = c.getContext("2d");
ctx.imageSmoothingEnabled = false;

var canvasWidth = 800,
	canvasHeight = 720;

var spriteSize = 16,
	spriteSheetSize = 32,
	spriteScale = 5;

var spritesImage = new Image();
spritesImage.src = "sprite_sheet.png";

ctx.fillStyle = "#333333";
ctx.fillRect(0, 0, canvasWidth, canvasHeight);

spritesImage.onload = function() {
	for(var i=0; i<canvasWidth/(spriteSize*spriteScale); i++) {
		drawSprite(i+1, 16*spriteScale*i, 0);
	}

	for(var i=1; i<canvasHeight/(spriteSize*spriteScale); i++) {
		drawSprite(i+1, 0, 16*spriteScale*i);
	}
};

function drawSprite(id, x, y) {
	var sx = spriteSize * (id%spriteSheetSize - 1),
		sy = spriteSize * Math.floor(id/spriteSheetSize);

	ctx.drawImage(
		spritesImage,
		sx, sy, // sx, sy
		spriteSize, spriteSize, // swidth, sheight
		x, y, // x, y
		spriteSize * spriteScale, spriteSize * spriteScale // width, height
	);
}
