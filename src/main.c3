import std::io;
import std::math;
import raylib5::rl;


const int HEIGHT = 600;
const int WIDTH = 800;
const int MAX_CIRCLES = 2;
const int[] DIRECTION = {-1, 1};

struct Ball
{
	float radius;
	bool isActive;
	Vector2 position;
}

enum GameState
{
	START,
	CLICKING,
	TRACKING
}

fn void main()
{
	// Main element
	Ball ball           = {};
	float spawnInterval = 2.0f;
	float timeToDespawn = 1.2f;
	float ballTimer     = 0.0f;
	float gameTimer     = 0.0f;

	// movement 
	float speed       = 100f;
	Vector2 direction = {};
	bool goingLeft    = false;
	bool goingRight   = false;

	// UI elements
	int ballCount = 0;
	int score     = 0;
	int lives     = 3;
	bool isPaused = false;
	bool isDead   = false;

	// Mouse val
	Vector2 mousePos   = {};
	Vector2 mouseDelta = {(float)rl::getScreenWidth() / 2, (float)rl::getScreenHeight() / 2};
	float sens         = 0.9f;

	// Blink vars
	int elapsedTime = 0;
	bool show       = false;

	rl::initWindow(HEIGHT, WIDTH, "pew");
	defer rl::closeWindow();

	rl::initAudioDevice();
	defer rl::closeAudioDevice();

	rl::disableCursor();

	Sound hit =  rl::loadSound("assets/hit.wav");
	defer rl::unloadSound(hit);

	Sound miss = rl::loadSound("assets/miss.wav");
	defer rl::unloadSound(miss);


	GameState state = GameState.START;
	while(!rl::windowShouldClose())
	{
		float rightBound = (float)(rl::getScreenWidth() / 4) * 3;
		float leftBound  = (float)(rl::getScreenWidth() / 3);

		switch (state)
		{
			case GameState.START:
				elapsedTime = (int)rl::getTime();
				if (rl::isKeyDown(rl::KEY_ENTER)) { state = GameState.CLICKING; }
				if (rl::isKeyDown(rl::KEY_SPACE)) { state = GameState.TRACKING; }
				// direction = {DIRECTION[rand_in_range(0, DIRECTION.len - 1)], 0};
				goingRight = true;

				show = (elapsedTime % 2) == 0;
				break;
			case GameState.TRACKING:
				gameTimer += rl::getFrameTime();
				set_ball_spawn(&ball, (Vector2){(float)rl::getScreenWidth() / 2, (float)rl::getScreenHeight()  / 2}, 20f);

				direction.x = (float)goingRight - (float)goingLeft;
				ball.position.x += direction.x * speed * gameTimer;

				if (ball.position.x + ball.radius >= rightBound) { goingLeft = true; goingRight = false; }
				// if (ball.position.x - ball.radius <= leftBound)  { goingLeft = false; goingRight = true; }
				break;
			case GameState.CLICKING:
				// mousePos = rl::getMousePosition();
				gameTimer += rl::getFrameTime();
				ballTimer += rl::getFrameTime(); 
				mouseDelta = rl::getMouseDelta();
				if (rl::isKeyPressed(rl::KEY_P)) { isPaused = !isPaused; }

				if (rl::isKeyPressed(rl::KEY_R) && isDead)
				{
					ball.isActive = false;
					ballCount = 0;
					score = 0;
					lives = 3;
					isDead = false;
					isPaused = false; 
					ballTimer = 0.0f;
				}
		
				if (!isPaused && !isDead)
				{
					if (ballTimer >= spawnInterval && ballCount <= MAX_CIRCLES)
					{
						set_ball_spawn(&ball, (Vector2){rand_in_range(200, rl::getScreenWidth() - 100), rand_in_range(200,rl::getScreenHeight() - 100)}, rand_in_range(10,25));
						ballCount++;
				
						ballTimer = 0.0f;
					}
			
					if (ballTimer >= timeToDespawn && ballCount > 0)
					{
						rl::playSound(miss);
						ball.isActive = false;
						ballCount--;
						lives--;
					}
			
					if (rl::isMouseButtonPressed(MouseButton.LEFT))
					{
						if (rl::checkCollisionPointCircle(mousePos, ball.position, ball.radius))
						{
							rl::playSound(hit);
							score += (int)(10 + ((timeToDespawn - ballTimer) * 10)); 
							ball.isActive = false; 
							ballCount--;
						} else {
							rl::playSound(miss);
							lives--;
							ballCount--;
							ball.isActive = false; 
						}	
					}
			
					if (lives <= 0)
					{
						if (ball.isActive) { ball.isActive = false; }

						isDead = true;
						lives = 0;
					}
				}	

				if (gameTimer < 1) {
					mousePos = {(float)rl::getScreenWidth() / 2, (float)rl::getScreenHeight() / 2};
				} else {
					mousePos.x += mouseDelta.x * sens;
					mousePos.y += mouseDelta.y * sens;
				}

				if (mousePos.x < 0) mousePos.x = 0;
				if (mousePos.x > rl::getScreenWidth()) mousePos.x = rl::getScreenWidth();
				if (mousePos.y < 0) mousePos.y = 0;
				if (mousePos.y > rl::getScreenHeight()) mousePos.y = rl::getScreenHeight();
				break;
		}

		rl::beginDrawing();
		rl::clearBackground(rl::RAYWHITE);

		switch(state)
		{
			case GameState.START:
				rl::clearBackground(rl::RAYWHITE);
				if (show) { rl::drawText("Press ENTER to start the game", (rl::getScreenWidth() / 2) - 350, rl::getScreenHeight() / 2, 50, rl::BLACK); }

				break;
			case GameState.TRACKING:
				rl::drawCircleV(ball.position, ball.radius, rl::RED);

				break;
			case GameState.CLICKING:
				if (ball.isActive)
				{
					rl::drawCircleV(ball.position, ball.radius, rl::RED);
				}

				rl::drawCircleV(mousePos, 3, rl::BLACK);
		
				if (isPaused) { show_pause_menu(); }
				if (isDead)   { show_death_menu(); }
	
				rl::drawText(rl::textFormat("Score: %d", score), 10, 15, 30, rl::BLACK);
				rl::drawText(rl::textFormat("Lives: %d", lives), 10, 50, 30, rl::BLACK);
				break;
		}

		rl::endDrawing();
	}
}

fn void set_ball_spawn(Ball* ball, Vector2 pos, float radius)
{
	ball.radius = radius;
	ball.position = pos;
	ball.isActive = true;
}

fn void show_pause_menu()
{
	rl::drawRectangleV({0, (float)rl::getScreenHeight() / 2 - 50}, {(float)rl::getScreenWidth(), 150}, rl::RED);
	rl::drawText("PAUSED", rl::getScreenWidth() / 2 - 100, rl::getScreenHeight() / 2, 50, rl::BLACK);
}

fn void show_death_menu()
{
	rl::drawRectangleV({0, (float)rl::getScreenHeight() / 2 - 50}, {(float)rl::getScreenWidth(), 150}, rl::RED);
	rl::drawText("DEAD", rl::getScreenWidth() / 2, rl::getScreenHeight() / 2 - 20, 40, rl::BLACK);
	rl::drawText("Press [R] to restart || [Esc] to quit", rl::getScreenWidth() / 2 - 300, rl::getScreenHeight() / 2 + 50, 32, rl::BLACK);
}
