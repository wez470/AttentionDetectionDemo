//Thread for processing eyes and face in camera images
class ImageProcessingThread extends Thread
{
  boolean running;
  String id;
  int faceCount;
  int eyeCount;
  int currNumFaces = 0;
  int currNumEyes = 0;
  
  ImageProcessingThread(String s)
  {
    id = s;
    faceCount = 10;
    eyeCount = 5;
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
      try
      {
      if(faceCount >= 10)
      {
        //Face Detection
        cam.update(); //get new frame/info from kinect
        opencv.copy(cam.rgbImage()); //get the current frame into opencv
    
        opencv.cascade("C:/opencv/data/haarcascades/", "haarcascade_frontalface_alt_tree.xml"); //initialize detection of face
        faceRect = opencv.detect(false); //get rectangle array of faces
    
        setCurrNumFaces(faceRect.length);
        faceCount = 0;
      }
      else
      {
        faceCount++;
      }
      
      if(eyeCount >= 10)
      {
        //Eye Detection
        cam.update(); //get new frame/info from kinect
        opencv.copy(cam.rgbImage()); //get the current frame into opencv
      
        opencv.cascade("C:/opencv/data/haarcascades/", "haarcascade_eye.xml"); //initialize detection of eyes
        eyeRect = opencv.detect(false); //get rectangle array of eyes
    
        setCurrNumEyes(eyeRect.length);
        eyeCount = 0;
      }
      else
      {
        eyeCount++;
      }
      } catch(Exception e)
      {
        println("Ran out of memory. Aborting");
        exit();
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
