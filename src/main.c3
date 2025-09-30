import std::io;
import std::math;
import raylib5::rl;


const int HEIGHT = 600;
const int WIDTH = 800;
const int MAX_CIRCLES = 3;
const int[] DIRECTION = {-1, 1};

struct Ball
{
	float radius;
	bool isActive;
	Vector2 position;
}


struct Button
{
	float width;
	float height;
	Vector2 position;
	String name;
}

enum GameState
{
	START,
	TAPPING,
	TRACKING
}

fn void main()
{
	// Main element
	Ball[] balls       = mem::new_array(Ball, 3);
	defer mem::free(balls);

	Ball ball           = {};
	float spawnInterval = 1.0f;
	float timeToDespawn = 0.5f;
	float ballTimer     = 0.0f;
	float gameTimer     = 0.0f;

	// movement 
	Vector2 direction = {};
	float speed       = 150f;
	bool goingLeft    = false;
	bool goingRight   = false;

	// UI elements
	int ballCount = 0;
	int score     = 0;
	int lives     = 3;
	bool isPaused = false;
	bool isDead   = false;
	Button[5] buttons;

	// Mouse val
	Vector2 mousePos   = {};
	Vector2 mouseDelta = {};
	float sens         = 0.9f;

	// Blink vars
	int elapsedTime = 0;
	bool show       = false;

	rl::initWindow(HEIGHT, WIDTH, "tsub");
	defer rl::closeWindow();

	rl::initAudioDevice();
	defer rl::closeAudioDevice();

	rl::disableCursor();

	Sound hit =  rl::loadSound("assets/hit.wav");
	defer rl::unloadSound(hit);

	Sound miss = rl::loadSound("assets/miss.wav");
	defer rl::unloadSound(miss);

	for(int i = 0; i < 5; i++) { buttons[i] = create_button(i); }

	GameState state = GameState.START;
	while(!rl::windowShouldClose())
	{
		float rightBound = (float)rl::getScreenWidth() * 0.8f;
		float leftBound  = (float)rl::getScreenWidth() * 0.2f;

		switch (state)
		{
			case GameState.START:
				elapsedTime = (int)rl::getTime();
				// if (rl::isKeyDown(rl::KEY_ENTER)) { state = GameState.TAPPING; }
				// if (rl::isKeyDown(rl::KEY_SPACE)) { state = GameState.TRACKING; }

				mouseDelta = rl::getMouseDelta();
				mousePos.x += mouseDelta.x * sens;
				mousePos.y += mouseDelta.y * sens;

				if (mousePos.x < 0) mousePos.x = 0;
				if (mousePos.x > rl::getScreenWidth()) mousePos.x = rl::getScreenWidth();
				if (mousePos.y < 0) mousePos.y = 0;
				if (mousePos.y > rl::getScreenHeight()) mousePos.y = rl::getScreenHeight();

				// TODO:: Move creating buttons into a new function, maybe.
				Rectangle tap = {
					.x      = buttons[0].position.x,
					.y      = buttons[0].position.y,
					.width  = buttons[0].width,
					.height = buttons[0].height
				};

				Rectangle track = {
					.x      = buttons[1].position.x,
					.y      = buttons[1].position.y,
					.width  = buttons[1].width,
					.height = buttons[1].height
				};


				// TODO:: Move handling of button events into a new function.
				if (rl::isMouseButtonPressed(MouseButton.LEFT))
				{
					if(rl::checkCollisionPointRec(mousePos, tap))   { state = GameState.TAPPING; }
					if(rl::checkCollisionPointRec(mousePos, track))	{ state = GameState.TRACKING; }
				}

				goingRight = true;
				show = (elapsedTime % 2) == 0;
				break;
			case GameState.TRACKING:
				gameTimer += rl::getFrameTime();
				float dt = rl::getFrameTime();
				mouseDelta = rl::getMouseDelta();

				// direction = {DIRECTION[rand_in_range(0, DIRECTION.len - 1)], 0};

				if (gameTimer < 1)
				{
					set_ball_spawn(&ball, (Vector2){(float)rl::getScreenWidth() / 2, (float)rl::getScreenHeight()  / 2}, 20f);	
					mousePos = {(float)rl::getScreenWidth() / 2, (float)rl::getScreenHeight() / 2};
				}
				else
				{
					direction.x = (float)goingRight - (float)goingLeft;
					ball.position.x += direction.x * speed * dt;

					if (rl::checkCollisionPointCircle(mousePos, ball.position, ball.radius)) { score += 10; } 

					mousePos.x += mouseDelta.x * sens;
					mousePos.y += mouseDelta.y * sens;

					if (mousePos.x < 0) mousePos.x = 0;
					if (mousePos.x > rl::getScreenWidth()) mousePos.x = rl::getScreenWidth();
					if (mousePos.y < 0) mousePos.y = 0;
					if (mousePos.y > rl::getScreenHeight()) mousePos.y = rl::getScreenHeight();

					if (ball.position.x + ball.radius >= rightBound) { goingLeft = true; goingRight = false; }
					if (ball.position.x - ball.radius <= leftBound)  { goingLeft = false; goingRight = true; }
				}

				break;
			case GameState.TAPPING:
				gameTimer += rl::getFrameTime();
				ballTimer += rl::getFrameTime(); 
				mouseDelta = rl::getMouseDelta();

				// TODO:: Change handling when ballCount reaches < 0
				if(ballCount < 0) ballCount = 0;

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
					if (ballTimer >= spawnInterval && ballCount < MAX_CIRCLES)
					{
						set_ball_spawn(&balls[ballCount], (Vector2){rand_in_range(200, rl::getScreenWidth() - 100), rand_in_range(200,rl::getScreenHeight() - 100)}, rand_in_range(10,25));

						ballCount++;
						ballTimer = 0.0f;
					}
			
					if (ballTimer >= timeToDespawn && ballCount > 0)
					{
						io::printn(ballTimer);
						rl::playSound(miss);
						foreach(&b:balls) (*b).isActive = false;
						ballCount--;
						lives--;
					}
			
					if (rl::isMouseButtonPressed(MouseButton.LEFT))
					{
						foreach(&b:balls)
						{
							if (rl::checkCollisionPointCircle(mousePos, (*b).position, (*b).radius))
							{
								rl::playSound(hit);
								score += (int)(10 + ((timeToDespawn - ballTimer) * 10)); 
								(*b).isActive = false;
								ballCount--;
							}

							// TODO:: add handling when tap misses the target
							// else
							// {
							// 	rl::playSound(miss);
							// 	lives--;
							// 	// foreach(&b:balls) b.isActive = false;
							// 	b.isActive = false; 
							// 	ballCount--;
							// }	
						}
					}
			
					if (lives <= 0)
					{
						foreach(&b:balls) {	(*b).isActive = (*b).isActive ? false : true; }
						isDead = true;
						lives = 0;
					}
				}	

				if (gameTimer < 1)
				{
					mousePos = {(float)rl::getScreenWidth() / 2, (float)rl::getScreenHeight() / 2};
				}
				else
				{
					mousePos.x += mouseDelta.x * sens;
					mousePos.y += mouseDelta.y * sens;
				}

				if (mousePos.x < 0) { mousePos.x = 0; }
				if (mousePos.y < 0) { mousePos.y = 0; }
				if (mousePos.x > rl::getScreenWidth()) { mousePos.x = rl::getScreenWidth(); }
				if (mousePos.y > rl::getScreenHeight()) { mousePos.y = rl::getScreenHeight(); }
				break;
		}

		rl::beginDrawing();
		rl::clearBackground(rl::RAYWHITE);

		switch(state)
		{
			case GameState.START:
				rl::clearBackground(rl::RAYWHITE);

				rl::drawRectangleV(buttons[0].position, (Vector2){buttons[0].width, buttons[0].height}, rl::BLACK);
				rl::drawRectangleV(buttons[1].position, (Vector2){buttons[1].width, buttons[1].height}, rl::RED);
			
				rl::drawCircleV(mousePos, 3, rl::BLACK);
				if (show) { rl::drawText("tsub", (rl::getScreenWidth() / 2), rl::getScreenHeight() / 2, 50, rl::BLACK); }

				break;
			case GameState.TRACKING:
				rl::drawCircleV(ball.position, ball.radius, rl::RED);
				rl::drawCircleV(mousePos, 3, rl::BLACK);
				rl::drawText(rl::textFormat("Score: %d", score), 10, 15, 30, rl::BLACK);
				rl::drawText(rl::textFormat("Time: %d", (int)gameTimer), 10, 50, 30, rl::BLACK);

				break;
			case GameState.TAPPING:
				foreach(&b:balls) if ((*b).isActive) { rl::drawCircleV((*b).position, (*b).radius, rl::RED); }

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

fn Button create_button(int index)
{
	static int spacing = 100;
	String[5] buttons = {"trackingButton","tappingButton","quitButton","menuButton","restartButton"};

	Button b       = {};
	b.name         = buttons[index];
	b.width        = 75;
	b.height       = 50;
	b.position.x   = (float)(rl::getScreenWidth() / 2) + b.width + spacing;
	b.position.y   = (float)(rl::getScreenHeight() / 2);
	spacing += 100;
	return b;
}
