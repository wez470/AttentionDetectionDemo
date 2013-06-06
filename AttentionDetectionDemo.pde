import SimpleOpenNI.*; //for kinect openni libraries
import monclubelec.javacvPro.*; //for opencv libraries
import java.awt.*; //for rectange
import com.sun.jna.platform.win32.*; //for win32 libraries
import com.sun.jna.*; //for JNA libraries
import com.sun.jna.platform.win32.WinDef.*; //for win32 definitions
import java.util.ArrayList;

OpenCV opencv; 
SimpleOpenNI cam;
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


void setup()
{  
  cam = new SimpleOpenNI(this); //initialize kinect camera
  cam.setMirror(true);
  cam.enableRGB();

  opencv = new OpenCV(this);
  opencv.allocate(cam.rgbWidth(), cam.rgbHeight()); //size of image buffer

  size(cam.rgbWidth(), cam.rgbHeight());

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
  int diam = 90;
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
int keyTimer = 0;
int currNumFaces = 0;
int currNumEyes = 0;
int framesFace = 10; //frame counter for detecting faces. set to 10 so detection happens on first frame
int framesPerFace = 10; //number of frames that go by before doing face detection again
int framesEyes = 5; //frame counter for detecting eyes. set to 5 to offset face detection
int framesPerEyes = 10; //number of frames that go by before doing eye detection again
int currWindowCoverage = 0;
boolean mouseWasPressed = false;
boolean overlap = false;


void draw()
{
  boolean imgProcessed = false;
  
  if(framesFace >= framesPerFace)
  {
    cam.update(); //get new frame/info from kinect
    opencv.copy(cam.rgbImage()); //get the current frame into opencv

    opencv.cascade("C:/opencv/data/haarcascades/", "haarcascade_frontalface_alt_tree.xml"); //initialize detection of face
    faceRect = opencv.detect(false); //get rectangle array of faces

    currNumFaces = faceRect.length;
    framesFace = 0;
    imgProcessed = true;
  }
  else
  {
    framesFace++;
  }
  
  if(framesEyes >= framesPerEyes)
  {
    cam.update(); //get new frame/info from kinect
    opencv.copy(cam.rgbImage()); //get the current frame into opencv
    
    opencv.cascade("C:/opencv/data/haarcascades/", "haarcascade_eye.xml"); //initialize detection of eyes
    eyeRect = opencv.detect(false); //get rectangle array of eyes

    currNumEyes = eyeRect.length;
    framesEyes = 0;
    imgProcessed= true;
  }
  else
  {
    framesEyes++;
  }
  
  //mouse activity detection
  if(!imgProcessed)
  {
    mouseUpdate();
  }

  //window overlap detection
  if(!imgProcessed)
  {
    windowUpdate();
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


//stores the current state as the result of the current test
void calculateAndDraw()
{
  float attentionProbability;
  //max of one face for attention calculation
  if(currNumFaces > 1)
  {
    currNumFaces = 1;
  }
  //max of two eyes for attention calculation
  if(currNumEyes > 2)
  {
    currNumEyes = 2;
  }
  
  //formula to decide if the user is paying attention or not.  Magic number are used to
  //try and weight the different types of data input to calculate probability of user attention
  attentionProbability = (((5.0 - currWindowCoverage / 9.0) * 22.0)
    + (currNumFaces * 200.0)
    + (currNumEyes / 2.0 * 100.0)
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
    trail.add(new Circle(circle.x, circle.y, 0, 0, circle.diam));
  }
  else
  {
    trail.add(new Circle(circle.x, circle.y, 0, 0, circle.diam));
    int removeCount = 0;
    //equation for finding how fast to remove old images.  Exponential equation so older images get removed faster
    //removeSpeed never goes below double speed.
    //Equation:   trail.size() = 1.5 * removeSpeed ^ 4
    int removeSpeed = max(2, (int) pow(((float) trail.size() / 1.5), 0.25));
    
    while(removeCount < removeSpeed && !trail.isEmpty())
    {
      trail.remove(0); //remove the oldest circle from the list to draw
      removeCount++;
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


