import SimpleOpenNI.*; //for kinect openni libraries
import monclubelec.javacvPro.*; //for opencv libraries
import java.awt.*; //for rectange
import com.sun.jna.platform.win32.*; //for win32 libraries
import com.sun.jna.*; //for JNA libraries
import com.sun.jna.platform.win32.WinDef.*; //for win32 definitions
import java.util.ArrayList;

SimpleOpenNI cam;
OpenCV opencv; 
Rectangle[] faceRect;
Rectangle[] eyeRect;
int strBuffSize = 512;
char[] windowText = new char[strBuffSize];
String windowTitle = "AttentionDetectionDemo";
ArrayList<RECT> aboveWindows = new ArrayList<RECT>();
ArrayList<RECT> overlappingRects = new ArrayList<RECT>();
RECT rectOfInterest = new RECT();
HWND windowOfInterest;
Circle circle;
ArrayList<Circle> trail = new ArrayList<Circle>();
ImageProcessingThread imgProcThread;

void setup()
{  
  //frameRate(75);
  cam = new SimpleOpenNI(this); //initialize kinect camera
  cam.setMirror(true);
  cam.enableRGB();

  opencv = new OpenCV(this);
  opencv.allocate(cam.rgbWidth(), cam.rgbHeight()); //size of image buffer

  size(640, 480);
  
  imgProcThread = new ImageProcessingThread("Image Processing Thread");
  imgProcThread.start();

  int windowsAway = 6; //the window of interest is six windows above the foreground window at the start
  windowOfInterest = User32.INSTANCE.GetForegroundWindow();
  for(int i = 0; i < windowsAway; i++)
  {
    windowOfInterest = User32.INSTANCE.GetWindow(windowOfInterest, new DWORD(User32.GW_HWNDPREV));
  }
  User32.INSTANCE.GetWindowText(windowOfInterest, windowText, strBuffSize);
  if(windowTitle.compareTo(Native.toString(windowText)) != 0)
  {
    println("ERROR: WRONG WINDOW OF INTEREST FOUND (title probably wrong)");
    exit();
  }

  //Ball setup
  int ballVelXY = 3;
  int diam = 50;
  circle = new Circle(width / 2, height / 2, ballVelXY, ballVelXY, diam);
  fill(16, 92, 1);
  
}


void keyPressed()
{
  keyTimer = millis();
}


void mousePressed()
{
  mouseWasPressed = true;
}


int mouseTimer = 0;
int windowIndex = 0;
int keyTimer = 0;
int currWindowCoverage = 0;
boolean mouseWasPressed = false;
boolean overlap = false;
boolean firstTime = true;


void draw()
{
  //println(frameRate);
  if(firstTime)
  { 
    //wait for other thread to start up
    int currTime = millis();
    while(millis() - currTime < 4000)
    {
    }
    firstTime = false;
  }
  
  //mouse activity detection
  mouseUpdate();

  //window overlap detection
  if(windowIndex == 10)
  {
    windowUpdate();
    windowIndex = 0;
  }
  else
  {
    windowIndex++;
  }

  //draw circle and trail after calculating user attention probability
  calculateAndDraw();
}


//updates the time since last activity with the mouse (movement or clicks)
void mouseUpdate()
{
  if(mouseX != pmouseX || mouseY != pmouseY || mouseWasPressed)
  {
    mouseTimer = millis();
    mouseWasPressed = false;
  }
}


//update whether the program window is overlapped or not
void windowUpdate()
{
  HWND currWindow = User32.INSTANCE.GetForegroundWindow();

  //get all the size/positions of windows above the window of interest
  while(true)
  {
    //So we don't get stuck in the loop if can't find the window of interest
    if(currWindow == null)
    {
      break;
    }
    RECT currRect = new RECT();
    User32.INSTANCE.GetWindowRect(currWindow, currRect);

    //see we are at the window of interest
    //if we are, save the size/position and exit search
    if(windowOfInterest.equals(currWindow))
    {
      rectOfInterest = currRect;
      break;
    }
    else
    {
      //add positions/size of current window and get next window
      aboveWindows.add(currRect);
      currWindow = User32.INSTANCE.GetWindow(currWindow, new DWORD(User32.GW_HWNDNEXT));
    }
  }
  checkOverlap();
  aboveWindows.clear();
}


//check if the window of interest is below any other windows
void checkOverlap()
{
  //compare above window positions to window of interest to see if they overlap
  for(RECT currRect: aboveWindows)
  {
    //four cases of non overlap
    if(rectOfInterest.left > currRect.right) //completely to the right
    {
      continue;
    }
    if(rectOfInterest.right < currRect.left) //completely to the left
    {
      continue;
    }
    if(rectOfInterest.top > currRect.bottom) //completely below
    {
      continue;
    }
    if(rectOfInterest.bottom < currRect.top) //completely above
    {
      continue;
    }
    //since none of the four cases are satisfied, there must be overlap
    overlap = true;
    addCollisionRect(currRect);
  }
  
  if(overlap)
  {
    currWindowCoverage = percentOverlap();
    overlappingRects.clear();
  }
  else
  {
    currWindowCoverage = 0;
  }
  overlap = false;
}


//finds the coordinates of the overlapping rectangle and adds it to the list of overlapping rectangles
void addCollisionRect(RECT overlapRect)
{
  RECT intersectRect = new RECT();
  intersectRect.left = max(rectOfInterest.left, overlapRect.left);
  intersectRect.right = min(rectOfInterest.right, overlapRect.right);
  intersectRect.top = max(rectOfInterest.top, overlapRect.top);
  intersectRect.bottom = min(rectOfInterest.bottom, overlapRect.bottom);
  overlappingRects.add(intersectRect);
}


//calculate percent overlap from global list of overlapping rectangles
int percentOverlap()
{ 
  int rectOfInterestWidth = rectOfInterest.right - rectOfInterest.left;
  int rectOfInterestHeight = rectOfInterest.bottom - rectOfInterest.top;
  boolean[][] pixelOverlap = new boolean[rectOfInterestWidth][rectOfInterestHeight];
  //initialize pixel array for overlap percentage calculation
  for(int i = 0; i < rectOfInterestWidth; i++)
  {
    for(int j = 0; j < rectOfInterestHeight; j++)
    {
      pixelOverlap[i][j] = false;
    }
  }
  //for each overlapping rectangle (window), go through all its pixels and
  //change the corresponding location in the pixelOverlap array to show that
  //there is overlap on that pixel
  for(RECT currRect: overlappingRects)
  {
    int currRectWidth = currRect.right - currRect.left;
    int currRectHeight = currRect.bottom - currRect.top;
    int startHorizontal = currRect.left - rectOfInterest.left;
    int startVertical = currRect.top - rectOfInterest.top;
    for(int k = startHorizontal; k < (startHorizontal + currRectWidth); k++)
    {
      for(int m = startVertical; m < (startVertical + currRectHeight); m++)
      {
        pixelOverlap[k][m] = true;
      }
    }
  }
  
  float numPixelsOverlapped = 0;
  //get how many pixels are overlapped
  for(int i = 0; i < rectOfInterestWidth; i++)
  {
    for(int j = 0; j < rectOfInterestHeight; j++)
    {
      if(pixelOverlap[i][j])
      {
        numPixelsOverlapped++;
      }
    }
  }
  float numPixels = rectOfInterestWidth * rectOfInterestHeight;
  float percentOverlap = numPixelsOverlapped / numPixels * 100.0;
  return (int) percentOverlap;
}


int addTailCount = 0;
int trailDiam = 10;


//stores the current state as the result of the current test
void calculateAndDraw()
{
  float attentionProbability;
  //max of one face for attention calculation
  if(imgProcThread.getCurrNumFaces() > 1)
  {
    imgProcThread.setCurrNumFaces(1);
  }
  //max of two eyes for attention calculation
  if(imgProcThread.getCurrNumEyes() > 2)
  {
    imgProcThread.setCurrNumEyes(2);
  }
  
  //formula to decide if the user is paying attention or not.  Magic number are used to
  //try and weight the different types of data input to calculate probability of user attention
  attentionProbability = (((5.0 - currWindowCoverage / 9.0) * 22.0)
    + (imgProcThread.getCurrNumFaces() * 200.0)
    + (imgProcThread.getCurrNumEyes() * 50.0)
    + max(0, ((10.0 - ((millis() - mouseTimer) / 1000.0)) * 8.0))
    + max(0, ((10.0 - ((millis() - keyTimer) / 1000.0)) * 5.0))
    ) / 540.0;
    
  //override probability if window is fully covered  
  if(currWindowCoverage == 100)
  {
    attentionProbability = 0.0;
  }
  
  if((int) (attentionProbability * 100.0) < 50)
  {
    if(addTailCount == 0)
    {
      trail.add(new Circle(circle.x, circle.y, 0, 0, trailDiam));
      addTailCount = 3;
    }
    addTailCount--;
  }
  else
  {
    if(trail.size() > 0)
    {
      if(addTailCount == 0)
      {
        trail.add(new Circle(circle.x, circle.y, 0, 0, trailDiam, trail.get(trail.size() - 1).opacity));
        addTailCount = 3;
      }
      addTailCount--;
    }
    //equation for finding how fast to remove old images.  Exponential equation so older images get removed faster
    //Doesn't get below 5 so that the tail will continue to be removed when it gets short 
    //Equation:   trail.size() = (removeSpeed ^ 3) / 5
    int removeSpeed = max(5, (int) pow(((float) trail.size() * 5.0), (1.0 / 3.0)));
    
    for(int i = 0; i < min(removeSpeed, trail.size()); i++)
    {
      Circle currTail = trail.get(i);
      currTail.opacity -= 30;
      if(currTail.opacity <= 30)
      {
        trail.remove(i);

      }
    }
  } 
  
  background(107, 142, 35);
  circle.update();

  //draw tail circles
  for(Circle currTail: trail)
  {
    currTail.drawCircle();
  }

  //draw main circle
  circle.drawCircle();                                                 
}
