#include <SDL2/SDL.h>

struct speler { float x; float y; float vx; float vy; int op:1; int links:1; int rechts:1; };

int sw = 1280;
int sh = 720;

/*
local config = {
	horizMoveSpeed = 6;
	jumpSpeed = 15;
	gravity = 20;
	playerRadius = 1.2; -- 1.3
	ballRadius = 0.8; -- 0.9
	netWidth = 0.3;
	netHeight = 2;
	fieldWidth = 20;
	freq = 50;
	physicsSteps = 10;
	maxScore = 25;
	randomBounce = 0.5;
	seed = os.time();

	-- bonus
	bonusRadius = 0.4;
	bonusColor = {255,255,255};
}
*/

// speler
// r = 1.2
// pr = 1280/20 * 1.2 = 77
// br = 1280/20 * 0.8 = 51
// pd = 144
const int spelerRadius = 72;
const int w = spelerRadius * 2;
const int balRadius = 51;
uint32_t linkerpixels[144 * 144];
uint32_t rechterpixels[144 * 144];
uint32_t balpixels[144 * 144];
const float horizMoveSpeed = 6.4; //6 / 20 * sw / 60;
const float jumpSpeed = 16;
const float gravity = 0.3333 * (6.0f/5.0f);

void werkSpelerBij(struct speler* speler) {
	// update
	if (speler->y != 720) speler->vy += gravity;
	speler->x += speler->vx;
	speler->y += speler->vy;
	if (speler->y > 720) {
		speler->y = 720; speler->vy = 0;
		if (speler->op) {
			speler->vy = -jumpSpeed;
		}
	}
}

void balVsSpeler(struct speler* speler) {

}

int main() {
	SDL_Init(SDL_INIT_VIDEO);//|SDL_INIT_AUDIO);

	SDL_Window* win = SDL_CreateWindow("Salvobal", 100, 100, 1280, 720, SDL_WINDOW_SHOWN);
	SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

	for (int x = 0; x < w; x++) {
		for (int y = 0; y < w; y++) {

			if ((x-72)*(x-72) + (y-72)*(y-72) < balRadius*balRadius)
				balpixels[y * w + x] = 0xFFFFFFFF;
			else
				balpixels[y * w + x] = 0;

			if ((x-72)*(x-72) + (y-72)*(y-72) < 72*72 && y <= w/2) {
				linkerpixels[y * w + x] = 0xFFFF00FF;
				rechterpixels[y * w + x] = 0x0000FFFF;
			}
			else {
				linkerpixels[y * w + x] = 0;
				rechterpixels[y * w + x] = 0;
			}
		}
	}

	SDL_Surface* linkerspeler = SDL_CreateRGBSurfaceFrom(linkerpixels, w, w, 32, w * sizeof(uint32_t), 0xFF000000, 0xFF0000, 0xFF00, 0xFF);
	SDL_Surface* rechterspeler = SDL_CreateRGBSurfaceFrom(rechterpixels, w, w, 32, w * sizeof(uint32_t), 0xFF000000, 0xFF0000, 0xFF00, 0xFF);
	SDL_Surface* bal = SDL_CreateRGBSurfaceFrom(balpixels, w, w, 32, w * sizeof(uint32_t), 0xFF000000, 0xFF0000, 0xFF00, 0xFF);

	SDL_Texture* linkertex = SDL_CreateTextureFromSurface(ren, linkerspeler);
	SDL_Texture* rechtertex = SDL_CreateTextureFromSurface(ren, rechterspeler);
	SDL_Texture* baltex = SDL_CreateTextureFromSurface(ren, bal);

	SDL_Event e = {};

	struct speler links = {sw/4, sw/2, 0, 0};
	struct speler rechts = {sw*3/4, sw/2, 0, 0};

	while (1) {
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT || e.type == SDL_WINDOWEVENT_CLOSE)
				goto stop;
			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_LEFT) {
					rechts.links = 1;
					rechts.vx = -horizMoveSpeed;
				}
				else if (e.key.keysym.sym == SDLK_RIGHT) {
					rechts.rechts = 1;
					rechts.vx = +horizMoveSpeed;
				}

				if (e.key.keysym.sym == SDLK_a) {
					links.vx = -horizMoveSpeed;
					links.links = 1;
				}
				else if (e.key.keysym.sym == SDLK_d) {
					links.vx = +horizMoveSpeed;
					links.rechts = 1;
				}

				if (e.key.keysym.sym == SDLK_UP) {
					if (rechts.y == 720) {
						rechts.vy = -jumpSpeed;
					}
					rechts.op = 1;
				}
				if (e.key.keysym.sym == SDLK_w) {
					if (links.y == 720) {
						links.vy = -jumpSpeed;
					}
					links.op = 1;
				}
			}

			// toets losgelaten
			if (e.type == SDL_KEYUP) {
					// links
				if (e.key.keysym.sym == SDLK_LEFT) {
					rechts.links = 0;
					if (rechts.rechts)
						rechts.vx = horizMoveSpeed;
					else
						rechts.vx = 0;
				}
				// rechts
				else if (e.key.keysym.sym == SDLK_RIGHT) {
					rechts.rechts = 0;
					if (rechts.links)
						rechts.vx = -horizMoveSpeed;
					else
						rechts.vx = 0;
				}

				// links
				else if (e.key.keysym.sym == SDLK_a) {
					links.links = 0;
					if (links.rechts)
						links.vx = horizMoveSpeed;
					else
						links.vx = 0;
				}

				// rechts
				else if (e.key.keysym.sym == SDLK_d) {
					links.rechts = 0;
					if (links.links)
						links.vx = -horizMoveSpeed;
					else
						links.vx = 0;
				}

				// op
				if (e.key.keysym.sym == SDLK_UP) {
					rechts.op = 0;
				}
				// op
				if (e.key.keysym.sym == SDLK_w) {
					links.op = 0;
				}
			}
		}

		werkSpelerBij(&links);
		werkSpelerBij(&rechts);

		if (links.x < 0) links.x = 0;
		if (links.x > 640) links.x = 640;

		if (rechts.x < 640) rechts.x = 640;
		if (rechts.x > 1280) rechts.x = 1280;

		SDL_RenderClear(ren);

		SDL_Rect dstrect;
		dstrect.x = (int) links.x - w/2;
		dstrect.y = (int) links.y - w/2;
		dstrect.w = w;
		dstrect.h = w;
		SDL_RenderCopy(ren, linkertex, NULL, &dstrect);

		//SDL_Rect dstrect;
		dstrect.x = (int) rechts.x - w/2;
		dstrect.y = (int) rechts.y - w/2;
		dstrect.w = w;
		dstrect.h = w;
		SDL_RenderCopy(ren, rechtertex, NULL, &dstrect);

		SDL_RenderPresent(ren);
	}

stop:

	SDL_Quit();
	return 0;
}
