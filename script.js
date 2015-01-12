var c = $("canvas")[0];
var ctx = c.getContext("2d");
ctx.imageSmoothingEnabled = false;

var canvasWidth = 640,
	canvasHeight = 512;

var spritesImage = new Image();
spritesImage.src = "sprite_sheet.png";

ctx.fillStyle = "#333333";
ctx.fillRect(0, 0, canvasWidth, canvasHeight);

var Tiles = {
	GROUND: 67,
	WALL: 68,
	PLAYER: 129
};

function Sprite() {
}

Sprite.pixelsPerSprite = 16;
Sprite.spriteSheetSize = 32;
Sprite.spriteScale = 2;

Sprite.render = function(id, sizeX, sizeY, posX, posY) {
	sizeX *= Sprite.pixelsPerSprite;
	sizeY *= Sprite.pixelsPerSprite;

	spriteX = Sprite.pixelsPerSprite * (id%Sprite.spriteSheetSize - 1);
	spriteY = Sprite.pixelsPerSprite * Math.floor(id/Sprite.spriteSheetSize);

	ctx.drawImage(
		spritesImage,
		spriteX, spriteY, // sx, sy
		sizeX, sizeY, // swidth, sheight
		posX*Sprite.pixelsPerSprite*Sprite.spriteScale, posY*Sprite.pixelsPerSprite*Sprite.spriteScale, // x, y
		sizeX*Sprite.spriteScale, sizeY*Sprite.spriteScale // width, height
	);
}

function Player() {
	var x = 8, y = 5;

	this.render = function() {
		Sprite.render(Tiles.PLAYER, 1, 2, x, y-1);
	}
};

function World() {
	var map = [];
	map[0] = [];
	for(var i=0; i<20; i++) {
		map[0].push(Tiles.WALL);
	}

	for(var i=1; i<15; i++) {
		map[i] = [];
		map[i].push(Tiles.WALL);
		for(var j=0; j<18; j++) {
			map[i].push(Tiles.GROUND);
		}
		map[i].push(Tiles.WALL);
	}

	map[15] = [];
	for(var i=0; i<20; i++) {
		map[15].push(Tiles.WALL);
	}

	this.render = function() {
		for(y in map) {
			for(x in map[y]) {
				Sprite.render(map[y][x], 1, 1, x, y);
			}
		}
	}
}

var world = new World();
var player = new Player();

spritesImage.onload = function() {
	world.render();
	player.render();
};
