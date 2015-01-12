import 'dart:html';

var canvasWidth = 640,
	canvasHeight = 512;

ImageElement spritesImage = new ImageElement();
var ctx;

void main() {
	CanvasElement c = querySelector('canvas');
	ctx = c.getContext("2d");
	ctx.imageSmoothingEnabled = false;
	
	spritesImage.src = "sprite_sheet.png";
	spritesImage.onLoad.listen((Event e){ 
		world.render();
		player.render();
	});
	
	ctx.fillStyle = "#333333";
	ctx.fillRect(0, 0, canvasWidth, canvasHeight);
}

class Tiles {
	static final GROUND = 67,
	WALL = 68,
	PLAYER = 129;
}

class Sprite {
	static final pixelsPerSprite = 16;
	static final spriteSheetSize = 32;
	static final spriteScale = 2;
	
	static void render(id, sizeX, sizeY, posX, posY) {
		sizeX *= Sprite.pixelsPerSprite;
		sizeY *= Sprite.pixelsPerSprite;
	
		var spriteX = Sprite.pixelsPerSprite * (id%Sprite.spriteSheetSize - 1);
		var spriteY = Sprite.pixelsPerSprite * (id/Sprite.spriteSheetSize).floor();
	
		ctx.drawImage(
			spritesImage,
			spriteX, spriteY, // sx, sy
			sizeX, sizeY, // swidth, sheight
			posX*Sprite.pixelsPerSprite*Sprite.spriteScale, posY*Sprite.pixelsPerSprite*Sprite.spriteScale, // x, y
			sizeX*Sprite.spriteScale, sizeY*Sprite.spriteScale // width, height
		);
	}
}

class Player {
	var x = 8, y = 5;

	void render() {
		Sprite.render(Tiles.PLAYER, 1, 2, x, y-1);
	}
}

class World {
	var map = [];
	
	World() {
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
	}

	void render() {
		for(var y in map) {
			for(var x in map[y]) {
				Sprite.render(map[y][x], 1, 1, x, y);
			}
		}
	}
}

World world = new World();
Player player = new Player();

