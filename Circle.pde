//A circle class for drawing and keeping track of specific circles
class Circle
{
  //coordinates
  int x;
  int y;
  //velocity
  int velX;
  int velY;
  int diam;

  Circle(int startX, int startY, int xVel, int yVel, int d)
  {
    x = startX;
    y = startY;
    velX = xVel;
    velY = yVel;
    diam = d;
    fill(16, 92, 1);
  }

  void update()
  {
    //test for wall to bounce off of
    if(x + (diam / 2) >= width || x - (diam / 2) <= 0)
    {
      velX *= -1;
    }
    if(y + (diam / 2) >= height || y - (diam / 2) <= 0)
    {
      velY *= -1;
    }

    x += velX;
    y += velY;
  } 

  void drawCircle()
  {
    ellipse(x, y, diam, diam);
  }
}


