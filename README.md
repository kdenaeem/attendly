# attendly

# Welcome to the Attendly Wiki
Here we will discuss and record various important information to do with our Solution and its implementation. 

[Here is a demo of the app](https://drive.google.com/file/d/1vbIJ7SuH_Qlw6YozkpivTz9K2_gEbVb5/view?usp=sharing)
![](https://drive.google.com/file/d/1vbIJ7SuH_Qlw6YozkpivTz9K2_gEbVb5/view?usp=sharing)
## Problem Statement and Solution
Our Solution for **Charity Right** is to use Deep Learning facial recognition software to mark and record attendance.  

Attendance is a critical measure wherein it allows Charity Right to ensure that the work they are doing is working in the schools. One challenge we identified is the workload faced by teachers, which can impact their ability to record attendance accurately, our solution aims to bring efficiency and transparency by a streamlined solution using Deep learning facial recognition software. This will give Charity Right with reliable data to evaluate the success of their school meals program, helping them continue to make a positive impact. 

## Solution Definition
For the solution, we have proposed a set of library that could potentially be used for facial recognition. 
 * Flutter 
 * Proposed Facial Recognition Libraries
    * FaceNet
      * Can be trained on custom datasets, allowing us to target diverse audience
      * Requires more computational resource
    * Google ML Kit
      * User Friendly and well documented, also comes with pre-trained algorithm 
      * allows for less custom dataset 
    * OpenCV
      * pretty powerful and extensive customisation tools
      * harder to integrate with flutter and takes a custom training model

We decided to use FaceNet model and [TensorFlow](https://pub.dev/packages/tflite_flutter) because we found that FaceNet was the most efficient model in terms of recognising faces. 

## Face Recognition Database
Using sqflite in flutter we now needed a system of storing the recognised and assigning them to a name so that once registered, they can be ticked off. 
![image](https://github.com/kdenaeem/attendly/assets/10659597/36ed308c-1171-4bbb-a6e0-1f949414b7c2)

This is a class definition for a recognition object that will be stored in the recognised faces database. 
As you can see there is an embedding object which is the way a model stores a face from the feature extraction into a vector array. Once a face is displayed on the camera, the embedding will be calculated and compared with the existing embedding on the database and we then use distance from the current embedding of the face displayed and compare this to the embeddings of each stored face in the database. 

The model used FaceNet has been trained to correctly identify faces by collecting millions of samples of faces through various machine learning techniques. For more info, please check this paper https://arxiv.org/ftp/arxiv/papers/1804/1804.07573.pdf


## Marking Attendance 
After successfully recognising the faces and storing them onto an sql database with a name and embedding, now its time to mark the attendance of the faces and store this as well on a database.
I've designed a model class that looks something like this 


![image](https://github.com/kdenaeem/attendly/assets/10659597/77e47323-5f8b-4644-9df4-e121b45a6875)


I also implemented a [factory method](https://dart.dev/language/constructors#factory-constructors) in flutter which helps return an instance form cache and this helps to improve our performance when marking the attendance in real time

![image](https://github.com/kdenaeem/attendly/assets/10659597/ceb2a267-b649-466b-8d6b-8e747dc8530f)

Now we have a model of the attendance record which can be used to store in a database. The next step is to modify the DatabaseHelper to include methods for updating and inserting the attendance record. 




