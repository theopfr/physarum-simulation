
// Initialization parameters
static int WIDTH = 750;
static int HEIGHT = 750;
int cellAmount = 25000;  // affects frame rate
boolean initializeCircle = true;
boolean initializeToCenter = false;
int spawnRadius = 200;
int[] mainColor = {204, 255, 102};
int[][] pheromoneGrid = new int[WIDTH][HEIGHT];
PVector[] cellPositions = new PVector[cellAmount];
PVector[] cellDirections = new PVector[cellAmount];
String visualizationMode = "cell";  // trail | cell | both , affects frame rate

// Parameters for single cell behavior
float size = 1;
float speed = 1;
float pheromoneDecay = 0.95;  // 0.925 - 0.99 affects frame rate
float sensorAngle = 45;
float moveAngle = 45;
int sensorReach = 15;  // affects frame rate
int sensorLength = 15;
boolean randomSteer = true;
int randomSteerAngle = 20;


Cell[] cells = new Cell[cellAmount];


class Cell {
  PVector position;
  PVector direction;
  int turnChoice = 0;
  
  Cell(PVector initialPosition, PVector initialDirection) {
    this.position = initialPosition;
    this.direction = initialDirection;
  }
  
  void sense() {
    PVector ext0 = this.direction.copy().normalize();
    PVector smellVector0 = PVector.add(this.position, PVector.mult(ext0, sensorLength));
    
    PVector ext1 = turnVector(new PVector(this.direction.x, this.direction.y), sensorAngle).normalize();
    PVector smellVector1 = PVector.add(this.position, PVector.mult(ext1, sensorLength));
    
    PVector ext2 = turnVector(new PVector(this.direction.x, this.direction.y), -sensorAngle).normalize();
    PVector smellVector2 = PVector.add(this.position, PVector.mult(ext2, sensorLength));
    
    boundChecker(smellVector0);
    boundChecker(smellVector1);
    boundChecker(smellVector2);
  
    int intensitySensor0 = 0;
    int intensitySensor1 = 0;
    int intensitySensor2 = 0;
    
    for (int xOffset = -sensorReach; xOffset <= sensorReach; xOffset++) {
      for (int yOffset = -sensorReach; yOffset <= sensorReach; yOffset++) {
        int i = (int) (this.position.x + xOffset);
        int j = (int) (this.position.y + yOffset);
  
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
        
    if (intensitySensor0 > intensitySensor1 && intensitySensor0 > intensitySensor2) {
      this.turnChoice = 0;
    }
    else if (intensitySensor1 > intensitySensor0 && intensitySensor1 > intensitySensor2) {
      this.turnChoice = 1;
    }
    else if (intensitySensor2 > intensitySensor1 && intensitySensor2 > intensitySensor0) {
      this.turnChoice = -1;
    }
    else if (intensitySensor1 == intensitySensor2 && intensitySensor1 > intensitySensor0) {
      // If no pheromone differences are detected turn randomly if wantd
      turnChoice = (int) random(1, 3);
      if (turnChoice == 1) { this.turnChoice = 1; }
      else { this.turnChoice = -1; }
    }
    else if (randomSteer) {
      // If no pheromone differences are detected turn randomly if wantd
      turnChoice = (int) random(0, 3);
      if (turnChoice == 0) { turnChoice = 0; }
      else if (turnChoice == 1){ this.turnChoice = 1; }
      else if (turnChoice == 2){ this.turnChoice = -1; }
    }
  }
  
  void move() {    
    // Check for boundary collision
    if (this.position.x >= WIDTH-1 || this.position.x <= 1) {
      this.position.x *= -1;
    }
    if (this.position.y >= HEIGHT-1 || this.position.y <= 1) {
      this.position.y *= -1;
    }
    
    // Sense pheromones and choose direction to turn
    this.sense();
    
    // Randomly change movement angle by a little bit if wanted
    float randomSteerStrength = 0;
    if (randomSteer) {
      randomSteerStrength = random(-1, 1) * randomSteerAngle;
    }
    
    // Calculate new cell position
    PVector newDirection = turnVector(this.direction, this.turnChoice * (moveAngle - randomSteerStrength));
    PVector newPosition = new PVector(
      this.position.x + speed * newDirection.x,
      this.position.y + speed * newDirection.y
    );
    
    // TODO I'm sure I don't need it...
    boundChecker(newPosition);
    
    this.position.x = newPosition.x;
    this.position.y = newPosition.y;
  }
  
  void display() {
    noStroke();
    fill(mainColor[0], mainColor[1], mainColor[2]);
    circle(this.position.x, this.position.y, size);
  }

}



void init() {
  for (int i=0; i<cellAmount; i++) {
    
     PVector cellPosition;
     PVector cellDirection;
    
    if (initializeCircle) {
      float angle = random(TWO_PI);
      float radius = random(0, spawnRadius);
      float x = WIDTH / 2.0 + radius * cos(angle);
      float y = HEIGHT / 2.0 + radius * sin(angle);
      cellPosition = new PVector(x, y);
    }
    else {
      cellPosition = new PVector(random(0, WIDTH - 1), random(0, HEIGHT - 1));
    }
    
    PVector initialDirectionVector;
    if (initializeToCenter) {
      initialDirectionVector = new PVector((int) WIDTH / 2, (int) HEIGHT / 2);
    }
    else {
      initialDirectionVector = new PVector(random(0, WIDTH), random(0, HEIGHT));
    }
    PVector initialDirection = PVector.sub(initialDirectionVector, cellPosition);

    initialDirection.normalize();
    cellDirection = initialDirection;
    
    cells[i] = new Cell(cellPosition, cellDirection);
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


void setup() {
  size(750, 750);
  background(0);
  
  init();
}

void draw() {
  background(0);

  for (int i=0; i<cellAmount; i++) {
    
    Cell currentCell = cells[i];
        
    currentCell.sense();
    currentCell.move();

    if (visualizationMode == "cell" || visualizationMode == "both") {
      currentCell.display();
    }
    
    pheromoneGrid[(int) currentCell.position.x][(int) currentCell.position.y] = 255;
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


