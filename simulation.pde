
// Initialization parameters
static int WIDTH = 750;
static int HEIGHT = 750;
int cellAmount = 10000;  // affects frame rate
String initializationMode = "full";  // full | circle
String initialDirection = "center";  // random | center | out
int spawnRadius = 200;
int[] mainColor = {204, 255, 102};
int[][] pheromoneGrid = new int[WIDTH][HEIGHT];
PVector[] cellPositions = new PVector[cellAmount];
PVector[] cellDirections = new PVector[cellAmount];
String visualizationMode = "both";  // trail | cell | both , affects frame rate

// Parameters for single cell behavior
float size = 1;
float speed = 1;
float pheromoneDecay = 0.95;  // 0.925 - 0.99 , affects frame rate
float sensorAngle = 90;
float moveAngle = 30;
int sensorReach = 8;  // affects frame rate
int sensorLength = 14;
boolean randomSteer = true;
int randomSteerAngle = 20;



void initializeCells() {
  for (int i=0; i<cellAmount; i++) {
    if (initializationMode == "circle") {
      float angle = random(TWO_PI);
      float radius = random(0, spawnRadius);
      float x = WIDTH / 2.0 + radius * cos(angle);
      float y = HEIGHT / 2.0 + radius * sin(angle);
      PVector position = new PVector(x, y);
      cellPositions[i] = position;
    }
    else {
      cellPositions[i] = new PVector(random(0, WIDTH - 1), random(0, HEIGHT - 1));
    }
    
    PVector initialDirectionVector;
    if (initialDirection == "center") {
      initialDirectionVector = new PVector((int) WIDTH / 2, (int) HEIGHT / 2);
    }
    else if (initialDirection == "out") {
      float angle = random(TWO_PI);
      float x = width/2 + spawnRadius * cos(angle);
      float y = height/2 + spawnRadius * sin(angle);
      initialDirectionVector = new PVector(x - width/2, y - height/2);
    }
    else {
      initialDirectionVector = new PVector(random(0, WIDTH), random(0, HEIGHT));
    }
    PVector initialDirection = PVector.sub(initialDirectionVector, cellPositions[i]);

    initialDirection.normalize();
    cellDirections[i] = initialDirection;
  }
}



PVector turnVector(PVector vec, float angle) {
  float angleRadians = radians(angle);
  float rotX = vec.x * cos(angleRadians) - vec.y * sin(angleRadians);
  float rotY = vec.x * sin(angleRadians) + vec.y * cos(angleRadians);
  return new PVector(rotX, rotY);
}

void boundChecker(PVector vec) {
  if (vec.x < 0) { vec.x = 0; }
  if (vec.x >= WIDTH) { vec.x = WIDTH - 1; }
  if (vec.y < 0) { vec.y = 0; }
  if (vec.y >= HEIGHT) { vec.y = HEIGHT - 1; }
}


int sensePheromones(PVector cellPosition, PVector cellDirection) {
  PVector ext0 = cellDirection.copy().normalize();  
  PVector smellVector0 = PVector.add(cellPosition, PVector.mult(ext0, sensorLength));
  
  PVector ext1 = turnVector(new PVector(cellDirection.x, cellDirection.y), sensorAngle).normalize();
  PVector smellVector1 = PVector.add(cellPosition, PVector.mult(ext1, sensorLength));
  
  PVector ext2 = turnVector(new PVector(cellDirection.x, cellDirection.y), -sensorAngle).normalize();
  PVector smellVector2 = PVector.add(cellPosition, PVector.mult(ext2, sensorLength));
  
  boundChecker(smellVector0);
  boundChecker(smellVector1);
  boundChecker(smellVector2);

  int intensitySensor0 = 0;
  int intensitySensor1 = 0;
  int intensitySensor2 = 0;
  
  for (int xOffset = -sensorReach; xOffset <= sensorReach; xOffset++) {
    for (int yOffset = -sensorReach; yOffset <= sensorReach; yOffset++) {
      int i = (int) (cellPosition.x + xOffset);
      int j = (int) (cellPosition.y + yOffset);

      if (i >= 0 && i < WIDTH && j >= 0 && j < HEIGHT) {
        PVector currentPheromone = new PVector(i, j);

        float dist0 = PVector.dist(currentPheromone, smellVector0);
        if (dist0 <= sensorReach) {
          intensitySensor0 += pheromoneGrid[i][j];// * (1 - dist0 / sensorReach);
        }

        float dist1 = PVector.dist(currentPheromone, smellVector1);
        if (dist1 <= sensorReach) {
          intensitySensor1 += pheromoneGrid[i][j];// * (1 - dist1 / sensorReach);
        }

        float dist2 = PVector.dist(currentPheromone, smellVector2);
        if (dist2 <= sensorReach) {
          intensitySensor2 += pheromoneGrid[i][j];// * (1 - dist2 / sensorReach);
        }
      }
    }
  }

    
  int turnChoice = 0;
  if (intensitySensor0 > intensitySensor1 && intensitySensor0 > intensitySensor2) {
    turnChoice = 0;
  }
  else if (intensitySensor1 > intensitySensor0 && intensitySensor1 > intensitySensor2) {
    turnChoice = 1;
  }
  else if (intensitySensor2 > intensitySensor1 && intensitySensor2 > intensitySensor0) {
    turnChoice = -1;
  }
  else if (intensitySensor1 == intensitySensor2 && intensitySensor1 > intensitySensor0) {
    // If no pheromone differences are detected turn randomly if wantd
    turnChoice = (int) random(1, 3);
    if (turnChoice == 1) { turnChoice = 1; }
    else { turnChoice = -1; }
  }
  else if (randomSteer) {
    // If no pheromone differences are detected turn randomly if wantd
    turnChoice = (int) random(0, 3);
    if (turnChoice == 0) { turnChoice = 0; }
    else if (turnChoice == 1){ turnChoice = 1; }
    else if (turnChoice == 2){ turnChoice = -1; }
  }

  return turnChoice;
}
  

void moveCell(int cellIdx) {
  PVector cellPosition = cellPositions[cellIdx];
  PVector cellDirection = cellDirections[cellIdx];
  
  // Check for boundary collision
  if (cellPosition.x >= WIDTH-1 || cellPosition.x <= 1) {
    cellDirection.x *= -1;
  }
  if (cellPosition.y >= HEIGHT-1 || cellPosition.y <= 1) {
    cellDirection.y *= -1;
  }
  
  // Sense pheromones and choose direction to move
  int turnDirection = sensePheromones(cellPosition, cellDirection);
  
  // Randomly change movement angle by a little bit if wanted
  float randomSteerStrength = random(-1, 1) * randomSteerAngle;
  
  // Calculate new cell position
  PVector newDirection = turnVector(cellDirection, turnDirection * (moveAngle - randomSteerStrength));
  PVector newPosition = new PVector(
    cellPosition.x + speed * newDirection.x,
    cellPosition.y + speed * newDirection.y
  );
  
  // TODO I'm sure I don't need it...
  boundChecker(newPosition);
  
  cellPositions[cellIdx] = newPosition;
  cellDirections[cellIdx] = newDirection;
}


void setup() {
  size(750, 750);
  background(0);
  
  initializeCells();
}



void draw() {
  background(0);

  for (int i=0; i<cellAmount; i++) {
    moveCell(i);
    
    if (visualizationMode == "cell" || visualizationMode == "both") {
      noStroke();
      fill(mainColor[0], mainColor[1], mainColor[2]);
      circle(cellPositions[i].x, cellPositions[i].y, 1);
    }
    
    pheromoneGrid[(int) cellPositions[i].x][(int) cellPositions[i].y] = 255;
  }

  for(int i=0; i<WIDTH; i++) {
    for(int j=0; j<HEIGHT; j++) {
      pheromoneGrid[i][j] *= pheromoneDecay;
      if (pheromoneGrid[i][j] < 0.001) {
        pheromoneGrid[i][j] = 0;
      }
      else {
        if (visualizationMode == "trail" || visualizationMode == "both") {
          noStroke();
          fill(mainColor[0], mainColor[1], mainColor[2], pheromoneGrid[i][j]);
          circle(i, j, size);
        }
      }
    }
  }
}
