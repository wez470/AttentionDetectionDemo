//Thread for processing eyes and face in camera images
class FaceProcessingThread extends Thread
{
  boolean running;
  String id;
  int wait;

  int currNumFaces = 0;
  int currNumEyes = 0;
  
  FaceProcessingThread(int w, String s)
  {
    wait = w;
    id = s;
    running = false;
  }
  
  void start()
  {
    running = true;

    super.start();
  }
  
  void run()
  {
    while(running)
    {
      //Face Detection
      cam.update(); //get new frame/info from kinect
      opencv.copy(cam.rgbImage()); //get the current frame into opencv
  
      opencv.cascade("C:/opencv/data/haarcascades/", "haarcascade_frontalface_alt_tree.xml"); //initialize detection of face
      faceRect = opencv.detect(false); //get rectangle array of faces
  
      setCurrNumFaces(faceRect.length);
      
      try
      {
        sleep((long) wait);
        wait = 1000;
      } catch(Exception e)
      {
      }
    }
  }
  
  synchronized int getCurrNumFaces()
  {
    return currNumFaces;
  }
  
  synchronized void setCurrNumFaces(int faces)
  {
    currNumFaces = faces;
  }
  
  void quit()
  {
    running = false;
    interrupt();
  }
}
