
int WIDTH = 750;
int HEIGHT = 750;
float size = 1;
float speed = 1;
int cellAmount = 5000;

float sensorAngle = 90;
float moveAngle = 22;
int sensorReach = 30;
int sensorLength = 30;

int[][] pheromoneGrid = new int[WIDTH][HEIGHT];
PVector[] cellPositions = new PVector[cellAmount];
PVector[] cellDirections = new PVector[cellAmount];

boolean initializeCircle = false;
boolean initializeToCenter = true;
int spawnRadius = 500;


void initializeCells() {
  for (int i=0; i<cellAmount; i++) {
    if (initializeCircle) {
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
    if (initializeToCenter) {
      initialDirectionVector = new PVector((int) WIDTH / 2, (int) HEIGHT / 2);
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
  
  PVector ext1 = turnVector(new PVector(cellDirection.x, cellDirection.y), random(0, 1) * sensorAngle).normalize();
  PVector smellVector1 = PVector.add(cellPosition, PVector.mult(ext1, sensorLength));
  
  PVector ext2 = turnVector(new PVector(cellDirection.x, cellDirection.y), random(0, 1) * -sensorAngle).normalize();
  PVector smellVector2 = PVector.add(cellPosition, PVector.mult(ext2, sensorLength));
  
  boundChecker(smellVector0);
  boundChecker(smellVector1);
  boundChecker(smellVector2);
  
  /*fill(255, 0, 0);
  circle(smellVector0.x, smellVector0.y, 5);
  circle(smellVector1.x, smellVector1.y, 5);
  circle(smellVector2.x, smellVector2.y, 5);*/

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
    turnChoice = (int) random(1, 3);
    if (turnChoice == 1) { turnChoice = 1; }
    else { turnChoice = -1; }
  }
  else {
    turnChoice = (int) random(1, 3);
    if (turnChoice == 0) { turnChoice = 0; }
    else if (turnChoice == 1){ turnChoice = 1; }
    else if (turnChoice == 2){ turnChoice = -1; }
  }

  return turnChoice;
}
  

void moveCell(int cellIdx) {
  PVector cellPosition = cellPositions[cellIdx];
  PVector cellDirection = cellDirections[cellIdx];

  if (cellPosition.x >= WIDTH-1 || cellPosition.x <= 1) {
    cellDirection.x *= -1;
  }
  if (cellPosition.y >= HEIGHT-1 || cellPosition.y <= 1) {
    cellDirection.y *= -1;
  }
  
  int turnDirection = sensePheromones(cellPosition, cellDirection);

  PVector newDirection = turnVector(cellDirection, turnDirection * moveAngle);
  PVector newPosition = new PVector(
    cellPosition.x + speed * newDirection.x,
    cellPosition.y + speed * newDirection.y
  );
  
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
    
    noStroke();
    fill(204, 255, 102);
    circle(cellPositions[i].x, cellPositions[i].y, 1);
    
    pheromoneGrid[(int) cellPositions[i].x][(int) cellPositions[i].y] = 255;
  }

  for(int i=0; i<WIDTH; i++) {
    for(int j=0; j<HEIGHT; j++) {
      pheromoneGrid[i][j] -= 2;
      if (pheromoneGrid[i][j] < 0) {
        pheromoneGrid[i][j] = 0;
      }
      else {
        noStroke();
        fill(204, 255, 102, pheromoneGrid[i][j]);
        circle(i, j, size);
      }
    }
  }
}
