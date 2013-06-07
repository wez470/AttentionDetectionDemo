//A circle class for drawing and keeping track of specific circles
class Circle
{
  //coordinates
  protected int x;
  protected int y;
  //velocity
  protected int velX;
  protected int velY;
  protected int diam;
  protected int opacity;

  public Circle(int startX, int startY, int xVel, int yVel, int d)
  {
    x = startX;
    y = startY;
    velX = xVel;
    velY = yVel;
    diam = d;
    opacity = 255;
  }

  public Circle(int startX, int startY, int xVel, int yVel, int d, int opac)
  {
    x = startX;
    y = startY;
    velX = xVel;
    velY = yVel;
    diam = d;
    opacity = opac;
  }  

  public void update()
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

  public void drawCircle()
  {
    stroke(0, 0, 0, opacity);
    fill(16, 92, 1, opacity);
    ellipse(x, y, diam, diam);
  }
}


