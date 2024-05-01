import controlP5.*;

// Initialization parameters
int maxCells = 250000;
int cellAmount = 5000;  // affects frame rate
String restartCellAmount = String.valueOf(cellAmount);  // is string bc user enters the desired amount via text input

static int WIDTH = 750;
static int HEIGHT = 750;
int[] mainColor = {204, 255, 102};
int[][] pheromoneGrid = new int[WIDTH][HEIGHT];
PVector[] cellPositions = new PVector[maxCells];
PVector[] cellDirections = new PVector[maxCells];
String visualizationMode = "both";  // trail | cell | both , affects frame rate
int mouseRadius = 75;

// Parameters for single cell behavior
boolean spawnInCircle = false;  // full | circle
String initialDirection = "center";  // random | center | out
int spawnRadius = 200;
int spawnInnerRadius = 50;
float size = 1;
float speed = 1;
float pheromoneDecay = 0.95;  // 0.925 - 0.99 , affects frame rate
float sensorAngle = 90;
float moveAngle = 45;
int sensorRadius = 9;  // affects frame rate
int sensorLength = 13;
boolean randomSteer = false;
int randomSteerAngle = 0;
boolean restart = false;

// GUI variables
ControlP5 cp5;
ColorWheel cp;
int c;
String exportPath = ".";

void initializeCells() {
  /*
    Initializes cells by spawning them in the specified form and with a given direction
  */
  
  for (int i=0; i<cellAmount; i++) {
    // Spawn cells in circle form around the center if wanted
    if (spawnInCircle) {
      float angle = random(TWO_PI);
      float radius = random(spawnInnerRadius, spawnRadius);
      float x = WIDTH / 2.0 + radius * cos(angle);
      float y = HEIGHT / 2.0 + radius * sin(angle);
      PVector position = new PVector(x, y);
      cellPositions[i] = position;
    }
    // Spawn distributed in the entire canvas
    else {
      cellPositions[i] = new PVector(random(0, WIDTH - 1), random(0, HEIGHT - 1));
    }
    
    PVector initialDirectionVector = new PVector((int) WIDTH / 2, (int) HEIGHT / 2);
    // Give cells an initial direction to the center if wanred
    if (initialDirection.equals("center")) {
      initialDirectionVector = PVector.sub(initialDirectionVector, cellPositions[i]);
    }
    // Give cells an initial direction away from the center if wanred
    else if (initialDirection.equals("out")) {
      initialDirectionVector = PVector.sub(cellPositions[i], initialDirectionVector);  
    }
    // Give cells a random initial direction
    else {
      initialDirectionVector = new PVector(random(0, WIDTH), random(0, HEIGHT));
    }
   
    initialDirectionVector.normalize();
    cellDirections[i] = initialDirectionVector;
  }
}



PVector turnVector(PVector vec, float angle) {
  /*
    Turns a vector by a specified angle
  */
  
  float angleRadians = radians(angle);
  float rotX = vec.x * cos(angleRadians) - vec.y * sin(angleRadians);
  float rotY = vec.x * sin(angleRadians) + vec.y * cos(angleRadians);
  return new PVector(rotX, rotY);
}

void boundChecker(PVector vec) {
  /*
    Checks for and handles a vector that is out-of-bounds 
  */
  if (vec.x < 0) { vec.x = 0; }
  if (vec.x >= WIDTH) { vec.x = WIDTH - 1; }
  if (vec.y < 0) { vec.y = 0; }
  if (vec.y >= HEIGHT) { vec.y = HEIGHT - 1; }
}


int sensePheromones(PVector cellPosition, PVector cellDirection) {
  /* 
    Sense pheromones using three sensors and decide in which direction to turn
    based on where the highest concentration is.
  */
  
  // Calculate the positions of the three sensors
  PVector ext0 = cellDirection.copy();
  ext0.normalize();  
  PVector smellVector0 = PVector.add(cellPosition, PVector.mult(ext0, sensorLength));
  
  PVector ext1 = turnVector(new PVector(cellDirection.x, cellDirection.y), sensorAngle);
  ext1.normalize();
  PVector smellVector1 = PVector.add(cellPosition, PVector.mult(ext1, sensorLength));
  
  PVector ext2 = turnVector(new PVector(cellDirection.x, cellDirection.y), -sensorAngle);
  ext2.normalize();
  PVector smellVector2 = PVector.add(cellPosition, PVector.mult(ext2, sensorLength));
  
  boundChecker(smellVector0);
  boundChecker(smellVector1);
  boundChecker(smellVector2);

  int intensitySensor0 = 0;
  int intensitySensor1 = 0;
  int intensitySensor2 = 0;
  
  // Count the pheromone concetration around all three sesnsors
  for (int xOffset = -sensorRadius; xOffset <= sensorRadius; xOffset++) {
    for (int yOffset = -sensorRadius; yOffset <= sensorRadius; yOffset++) {
      int i = (int) (cellPosition.x + xOffset);
      int j = (int) (cellPosition.y + yOffset);

      if (i >= 0 && i < WIDTH && j >= 0 && j < HEIGHT) {
        PVector currentPheromone = new PVector(i, j);

        float dist0 = PVector.dist(currentPheromone, smellVector0);
        if (dist0 <= sensorRadius) {
          intensitySensor0 += pheromoneGrid[i][j] * (1 - dist0 / sensorRadius);
        }

        float dist1 = PVector.dist(currentPheromone, smellVector1);
        if (dist1 <= sensorRadius) {
          intensitySensor1 += pheromoneGrid[i][j] * (1 - dist1 / sensorRadius);
        }

        float dist2 = PVector.dist(currentPheromone, smellVector2);
        if (dist2 <= sensorRadius) {
          intensitySensor2 += pheromoneGrid[i][j] * (1 - dist2 / sensorRadius);
        }
      }
    }
  }

  // Choose direction based on which sensor sensed the highest pheromone concentration
  // 0 = stright, 1 = right, -1 = left
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
  else if (randomSteer && intensitySensor1 == intensitySensor2 && intensitySensor1 > intensitySensor0) {
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
  /*
    Moves the cell with the given index in the direction which the sensors dictate
  */
  
  PVector cellPosition = cellPositions[cellIdx];
  PVector cellDirection = cellDirections[cellIdx];
  
  // Check for and handle boundary collision
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
  
  // Catch our-of-bounds coodinates
  boundChecker(newPosition);
  
  cellPositions[cellIdx] = newPosition;
  cellDirections[cellIdx] = newDirection;
}


boolean cellInMouseRadius(int cellIdx) {
  /*
    Checks if cell with given index is inside the clicked mouse position
  */
  
  PVector cellPosition = cellPositions[cellIdx];
  float dist = PVector.dist(cellPosition, new PVector(mouseX, mouseY));
  return dist <= mouseRadius;
}

void fleeFromMouse(int cellIdx) {
  /*
    Move cell away from mouse postion if user clicks and holds  
  */

  PVector cellPosition = cellPositions[cellIdx];
  PVector mousePosition = new PVector(mouseX, mouseY);
     
  // Calculate new cell position
  PVector newDirection = PVector.sub(cellPosition, mousePosition);
  newDirection.normalize();
  PVector newPosition = new PVector(
    cellPosition.x + 4 * newDirection.x,
    cellPosition.y + 4 * newDirection.y
  );
  boundChecker(newPosition);
  
  cellPositions[cellIdx] = newPosition;
  cellDirections[cellIdx] = newDirection;    
}



void setup() {
  size(750, 750);
  background(0);
    
  // Create GUI elements
  cp5 = new ControlP5(this);
  
  // Parameter control
  cp5.addSlider("speed")
    .setLabel("speed")
    .setPosition(10, 30)
    .setSize(100, 20)
    .setRange(1, 10)
    .setValue(1)
    .moveTo("parameters");
  cp5.addSlider("sensorAngle")
    .setLabel("sensor angle")
    .setPosition(10, 60)
    .setSize(100, 20)
    .setRange(10, 120)
    .setValue(90)
    .moveTo("parameters");
  cp5.addSlider("moveAngle")
    .setLabel("move angle")
    .setPosition(10, 90)
    .setSize(100, 20)
    .setRange(10, 120)
    .setValue(45)
    .moveTo("parameters");
  cp5.addSlider("sensorRadius")
    .setLabel("sensor reach")
    .setPosition(10, 120)
    .setSize(100, 20)
    .setRange(1, 15)
    .setValue(9)
    .moveTo("parameters");
  cp5.addSlider("sensorSize")
    .setLabel("sensor length")
    .setPosition(10, 150)
    .setSize(100, 20)
    .setRange(1, 25)
    .setValue(13)
    .moveTo("parameters");
  cp5.addSlider("pheromoneDecay")
    .setLabel("pheromone decay")
    .setPosition(10, 180)
    .setSize(100, 20)
    .setRange(0.9, 0.999)
    .setValue(0.95)
    .moveTo("parameters");
  cp5.addSlider("mouseRadius")
    .setLabel("mouseRadius")
    .setPosition(10, 210)
    .setSize(100, 20)
    .setRange(25, 100)
    .setValue(50)
    .moveTo("parameters");
  
  // Color control
  cp = cp5.addColorWheel("c")
    .setPosition(10, 30)
    .setRGB(color(mainColor[0], mainColor[1], mainColor[2]))
    .moveTo("color");
  
  // Image snapchot control
  cp5.addButton("export")
    .setBroadcast(false)
    .setValue(0)
    .setSize(100, 40)
    .setPosition(10, 30)
    .moveTo("export")
    .setBroadcast(true);
  cp5.addButton("openFileExplorer")
    .setBroadcast(false)
    .setLabel("select folder")
    .setValue(0)
    .setSize(100, 30)
    .setPosition(10, 80)
    .moveTo("export")
    .setBroadcast(true);
  
  // Restart control
  cp5.addToggle("spawnInCircle")
     .setLabel("spawn in circle?")
     .setPosition(10, 30)
     .setSize(20, 20)
     .moveTo("restart");
  cp5.addSlider("spawnRadius")
    .setLabel("spawn radius")
    .setPosition(20, 70)
    .setSize(100, 20)
    .setRange(0, (int) WIDTH / 2)
    .setValue(200)
    .moveTo("restart");
  cp5.addSlider("spawnInnerRadius")
    .setLabel("spawn inner radius")
    .setPosition(20, 100)
    .setSize(100, 20)
    .setRange(0, (int) WIDTH / 2)
    .setValue(0)
    .moveTo("restart");
  cp5.addTextfield("initialDirection")
    .setLabel("init. direction ('random', 'center', 'out')")
    .setPosition(10, 130)
    .setSize(100, 20)
    .moveTo("restart");
  cp5.addTextfield("restartCellAmount")
    .setLabel("cell amount (max. 250k)")
    .setPosition(10, 170)
    .setSize(100, 20)
    .moveTo("restart");
  cp5.addButton("restart")
    .setBroadcast(false)
    .setValue(0)
    .setSize(100, 40)
    .setPosition(10, 210)
    .moveTo("restart")
    .setBroadcast(true);
  
  // Spawn cells
  initializeCells();  
}


void restart() {
  /*
    Restart button handler
  */
  restart = true;
  
  try{
    cellAmount = Integer.parseInt(restartCellAmount);
    if (cellAmount > maxCells) {
      cellAmount = maxCells;
    }
  }
  catch (NumberFormatException e) {
    ;
  }
}


void openFileExplorer() {
  /* 
    Handler for opening the file explorer to select an export path
  */
  selectFolder("Select a folder store images:", "folderSelection");
}


void folderSelection(File selection) {
  /*
    Callback for updating the export path
  */
  if (selection == null) {
    ;
  } 
  else {
    println(selection, selection.getAbsolutePath());
    exportPath = selection.getAbsolutePath();
  }
}

void export() {
  /*
    Export button handler
  */
  PImage capturedImage;
  cp5.hide();
  capturedImage = get();
  cp5.show();
  capturedImage.save(exportPath + "/export-" + System.currentTimeMillis() / 1000 + ".png");
}


public void controlEvent(ControlEvent c) {
  /*
    Handler for control p5 changes events
  */
  // Detect color pick
  if(c.isFrom(cp)) {
    mainColor[0] = cp5.get(ColorWheel.class, "c").r();
    mainColor[1] = cp5.get(ColorWheel.class, "c").g();
    mainColor[2] = cp5.get(ColorWheel.class, "c").b();
  }
}


void draw() {
  background(0);
  
  if (restart) {
    // Remove all previous pheromones
    for(int i=0; i<WIDTH; i++) {
      for(int j=0; j<HEIGHT; j++) {
        pheromoneGrid[i][j] = 0;
      }
    }
    initializeCells();
    restart = false;
  }
  
  for (int i=0; i<cellAmount; i++) {
    // Move cell away from mouse cursor if user clicks and holds
    if (mousePressed && cellInMouseRadius(i)){
      fleeFromMouse(i);
    }
    
    // Move cell by smelling pheromones around it and choosing a direction
    else {
      moveCell(i);
    }
    
    // Draw cell on canvas
    if (visualizationMode == "cell" || visualizationMode == "both") {
      noStroke();
      fill(mainColor[0], mainColor[1], mainColor[2]);
      circle(cellPositions[i].x, cellPositions[i].y, 1);
    }
    
    // Create new pheromone at the current cell position
    pheromoneGrid[(int) cellPositions[i].x][(int) cellPositions[i].y] = 255;
  }
  
  for(int i=0; i<WIDTH; i++) {
    for(int j=0; j<HEIGHT; j++) {
      
      // Slightly evaporate current pheromone particle
      pheromoneGrid[i][j] *= pheromoneDecay;
      
      // Remove pheromoe if almost completely evaporated
      if (pheromoneGrid[i][j] < 0.001) {
        pheromoneGrid[i][j] = 0;
      }
      else {
        // Draw pheromone on canvas (increase opacity with time)
        if (visualizationMode == "trail" || visualizationMode == "both") {
          noStroke();
          fill(mainColor[0], mainColor[1], mainColor[2], pheromoneGrid[i][j]);
          circle(i, j, size);
        }
      }
    }
  }
}
