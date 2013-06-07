//Thread for processing eyes and face in camera images
class EyeProcessingThread extends Thread
{
  boolean running;
  String id;
  int wait;

  int currNumFaces = 0;
  int currNumEyes = 0;
  
  EyeProcessingThread(int w, String s)
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
      //Eye Detection
      cam.update(); //get new frame/info from kinect
      opencv.copy(cam.rgbImage()); //get the current frame into opencv
    
      opencv.cascade("C:/opencv/data/haarcascades/", "haarcascade_eye.xml"); //initialize detection of eyes
      eyeRect = opencv.detect(false); //get rectangle array of eyes
  
      setCurrNumEyes(eyeRect.length);
      
      try
      {
        sleep((long) wait);
      } catch(Exception e)
      {
      }
    }
  }
  
  synchronized int getCurrNumEyes()
  {
    return currNumEyes;
  }
  
  synchronized void setCurrNumEyes(int eyes)
  {
    currNumEyes = eyes;
  }
  
  void quit()
  {
    running = false;
    interrupt();
  }
}
