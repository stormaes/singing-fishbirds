/*The boid class. watch out this ones a banger!*/

class Boid {
  PVector location;
  PVector velocity;
  PVector acceleration;
  float colour;
  float diameter;
  float maxforce; //maximum steering force
  float maxspeed; //max speed
  float localseparationdistance = 25.0;

  Boid(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = new PVector(random(-1, 1), random(-1, 1));
    location = new PVector(x, y);
    maxspeed = localmaxspeed;
    maxforce = 0.03;
  }

  //run the system
  void run(ArrayList<Boid> boids) {
    flock(boids);
    update();
    borders();
    render();
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  //we accumulate a new acceleration each time base on 3 rules

  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids); //separation
    PVector ali = align(boids); //alignment
    PVector coh = cohesion(boids); //cohesion
    //arbitrarily weight these forces
    sep.mult(localseparationforce);
    ali.mult(localalignmentforce);
    coh.mult(localcohesionforce);
    //add the force vectors to accel
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }
  void update() {
    //update velocity
    velocity.add(acceleration);
    //limit speed
    velocity.limit(maxspeed);
    location.add(velocity);
    //reset acceleration to 0 each cycle45
    acceleration.mult(0);
  }

  //a method that calculates and applies a steering force towards a target
  // steer = desired minus velocity
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, location); //a vector pointing from the location to the target
    //normalie desired and scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);
    //steering = desired minus velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce); //limit to the maximum steering force
    return steer;
  }

void render() {
  /*soundmodes */
  //soundmode that uses y location for boid frequency and x location for panning.
    if (localsoundmodevar==0.0){
      for (int i=0; i<number; i++) {
       flock.synths.get(i).set("freq", (height-flock.boids.get(i).location.y)+localfreqModulation);
        flock.synths.get(i).set("pan",  (flock.boids.get(i).location.x-width)/(width*2)*localpanmod);
      }
    }
  //soundmode that uses y location for frequency and reverse diameter for amplitude (the larger the group the louder they are)
    else if (localsoundmodevar==1.0) {
      for (int i=0; i<number; i++) {
      flock.synths.get(i).set("freq", (height-flock.boids.get(i).location.y)+localfreqModulation);
       flock.synths.get(i).set("amp",  1-flock.boids.get(i).diameter/100);
      }
    }
  //soundmode that uses x location for panning, and size for frequency.
    else if (localsoundmodevar==2.0) {
      for (int i=0; i<number; i++) {
        flock.synths.get(i).set("pan",  (flock.boids.get(i).location.x-width)/(width*2)*localpanmod);
        flock.synths.get(i).set("freq", (flock.boids.get(i).diameter)*localfreqModulation);
      }
    }
    else {
      for (int i=0; i<number; i++) {
        flock.synths.get(i).set("pan",  (flock.boids.get(i).location.x-width)/(width*2)*localpanmod);
        flock.synths.get(i).set("freq", 440-(flock.boids.get(i).diameter)*localfreqModulation);
      }
    }
    smooth();
    noFill();
    pushMatrix();
    translate(location.x, location.y);

    /*RENDERMODE! */

    if(localmode == 0.0)
    {
        for (int i = 0; i<numberOfPoints; i++){
        numbers[i]=random(2,diameter+localvisualsize);
        }
        stroke(255);
        strokeWeight(localsweight);
        
        beginShape();
        for (int i=0; i<numberOfPoints; i++)
        {
          if(i<numberOfPoints-1)
          {
            vertex(numbers[i], numbers[i+1]);
          }
          else
          {vertex(numbers[numberOfPoints-1],numbers[0]);}
        }
        endShape();
     }
    else if(localmode ==1.0)
    {
      float theta = velocity.heading2D() + radians(120);
      stroke(255);
      strokeWeight(localsweight);
      rotate(theta);
      bezier(0, 0, random(0,localvisualsize), random(0,-localvisualsize), random(0,-localvisualsize), random(0,localvisualsize), 0, 0);
    }
    else if(localmode == 2.0)
    {
      noStroke();
      fill(localhue, localsaturation,localbrightness, localalpha);
      ellipse(0, 0, diameter+localvisualsize, diameter+localvisualsize);
    }
    else if(localmode == 3.0)
    {
      noStroke();
      fill(diameter*10, localsaturation,localbrightness, localalpha);
      ellipse(0, 0, diameter+localvisualsize, diameter+localvisualsize);
    }
  popMatrix();
  noStroke();
}

  //wraparound 
void borders() {
   
   
   if (location.x > width) {
      velocity.x = -velocity.x;
    } 
    else if (location.x < 0) {
      velocity.x = -velocity.x;
    } // X
    
    if (location.y > height) {
      velocity.y = -velocity.y;
    } else if (location.y < 0) {
      velocity.y = -velocity.y;
    }// Y
 }
  //Separation
  //method checks for nearby boids and steers away
  PVector separate(ArrayList<Boid> boids) {
    float desiredseparation = localseparationdistance;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    //for every boid in the system chech if its too close
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      //if the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      diameter = d/localsizemod;
      if ((d > 0) && (d < desiredseparation)) {
        //calculate vector pointing away from neighbor

        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d); //weight by distance.
        steer.add(diff);
        count++; //keep track of how many times separation occurs
      }
    }
    //Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    //as long as the vector is greater than 0
    if (steer.mag() > 0) {
      // Implement reynolds: steering = Desired - velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  //Alignment
  //For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = 30+localneighbordist;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d>0) && (d < neighbordist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  //cohesion
  // for the average location (ie center) of all nearby boids, calculate steering vetor towards that location
  PVector cohesion (ArrayList<Boid> boids) {
    float neighbordist = 70+localneighbordist;
    PVector sum = new PVector(0, 0); //start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : boids) {
      float d= PVector.dist(location, other.location);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.location); //add location
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum); //steer towards the location
    } 
    else {
      return new PVector(0, 0);
    }
  }
}
