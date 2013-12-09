/*
 * This file is part of the OpenKinect Project. http://www.openkinect.org
 *
 * Copyright (c) 2010 individual OpenKinect contributors. See the CONTRIB file
 * for details.
 *
 * This code is licensed to you under the terms of the Apache License, version
 * 2.0, or, at your option, the terms of the GNU General Public License,
 * version 2.0. See the APACHE20 and GPL2 files for the text of the licenses,
 * or the following URLs:
 * http://www.apache.org/licenses/LICENSE-2.0
 * http://www.gnu.org/licenses/gpl-2.0.txt
 *
 * If you redistribute this file in source form, modified or unmodified, you
 * may:
 *   1) Leave this header intact and distribute it under the same terms,
 *      accompanying it with the APACHE20 and GPL20 files, or
 *   2) Delete the Apache 2.0 clause and accompany it with the GPL2 file, or
 *   3) Delete the GPL v2 clause and accompany it with the APACHE20 file
 * In all cases you must keep the copyright notice intact and include a copy
 * of the CONTRIB file.
 *
 * Binary distributions must follow the binary distribution requirements of
 * either License.
 */

/*
	TODOS
        - [ ] Scan left to right
        - [ ] Output stuff
        - [ ] Top Bar and Lower Bar
*/
static const double pi = 3.14159265358979323846;

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "libfreenect.h"
#include "old.h"
#include <pthread.h>

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <cv.h>
#include <highgui.h>
#include <vector>

#include "lo/lo.h"

#define ADDRESS "127.0.0.1"
#define PORT 57120




#define WINDOW "mainWin"

using namespace cv;
using namespace std;


// for OSC

#define SDL 1

#ifdef DOGL
#define REDOFF 2
#define BLUEOFF 1
#define GREENOFF 0
#endif

#ifdef SDL
#define REDOFF 0
#define BLUEOFF 1
#define GREENOFF 2

#include <SDL/SDL.h>

#endif

#define WIDTH 640
#define HEIGHT 480

#ifdef DOGL
#if defined(__APPLE__)
#include <GLUT/glut.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#else
#include <GL/glut.h>
#include <GL/gl.h>
#include <GL/glu.h>
#endif
#endif

#include <math.h>



pthread_t freenect_thread;
volatile int die = 0;

int g_argc;
char **g_argv;

int window;

pthread_mutex_t gl_backbuf_mutex = PTHREAD_MUTEX_INITIALIZER;

// back: owned by libfreenect (implicit for depth)
// mid: owned by callbacks, "latest frame ready"
// front: owned by GL, "currently being drawn"
uint8_t *depth_mid, *depth_front, *color_diff_depth_map;
uint8_t *rgb_back, *rgb_mid, *rgb_front;

#ifdef DOGL
GLuint gl_depth_tex;
GLuint gl_rgb_tex;
#endif

freenect_context *f_ctx;
freenect_device *f_dev;
int freenect_angle = 0;
int freenect_led;

freenect_video_format requested_format = FREENECT_VIDEO_RGB;
freenect_video_format current_format = FREENECT_VIDEO_RGB;

pthread_cond_t gl_frame_cond = PTHREAD_COND_INITIALIZER;
int got_rgb = 0;
int got_depth = 0;

uint16_t gthreshold = 1024;

int * depth_map;/*[ FREENECT_FRAME_PIX ]; */
int * old_depth_map;/*[ FREENECT_FRAME_PIX ];*/
int * diff_depth_map;/*[ FREENECT_FRAME_PIX ];*/
int * tmp_diff_depth_map;/*[ FREENECT_FRAME_PIX ];*/

int depth_frame = 1024;
#define SHADOW 2047
#define WIDTH 640
#define HEIGHT 480

#ifdef SDL
SDL_Surface * sdlSurface = NULL;
#endif

int object_depth = 500;
int ghit = 0;
int win = 0;
int wotime = 0;

int gdegree = 0;
int gtempo = 1;
int gyline = HEIGHT/2;

bool gkeydown = false;
char gkeysym = ' ';

#define MYCVTYPE CV_32S
//define MYCVTYPE CV_32F

cv::Mat lastDepthFrame(HEIGHT, WIDTH, MYCVTYPE);
cv::Mat depthFrame(HEIGHT, WIDTH, MYCVTYPE);

lo_address lo_t = lo_address_new("127.0.0.1", "57120");


void clearBorders( int * map ) {
  for (int y = 0 ; y < HEIGHT; y++) {
    map[WIDTH * y + 0] = 0;
    map[WIDTH * y + WIDTH - 1] = 0;
  }
  for (int x = 0 ; x < WIDTH; x++) {
    map[x] = 0;
    map[FREENECT_FRAME_PIX - WIDTH + x] = 0;
  }

}

void despeckleInPlace( int * map ) {
  clearBorders( tmp_diff_depth_map );
  for (int y = 1 ; y < HEIGHT-1; y++) {
    for (int x = 1 ; x < WIDTH-1; x++) {
      int cnt = (map[WIDTH*(y+1) + x] > 0)
        + (map[WIDTH*(y-1) + x] > 0)
        + (map[WIDTH*(y) + x + 1] > 0)
        + (map[WIDTH*(y) + x - 1] > 0);
      tmp_diff_depth_map[ WIDTH * y + x ] = (cnt > 2)?map[ WIDTH * y + x]:0;
    }
  }
  memcpy( map, tmp_diff_depth_map, sizeof(int) * FREENECT_FRAME_PIX );
}


void smoothInPlace( int * map ) {
  clearBorders( map );
  for (int y = 1 ; y < HEIGHT-1; y++) {
    for (int x = 1 ; x < WIDTH-1; x++) {
      int V = WIDTH * y + x;
      int cnt = map[V - WIDTH - 1] + map[V - WIDTH] + map[V - WIDTH + 1] +
        map[V] + map[V] + map[V + 1] +
        map[V + WIDTH - 1] + map[V + WIDTH] + map[V + WIDTH + 1];
      tmp_diff_depth_map[ V ] = cnt / 9;
    }
  }
  memcpy( map, tmp_diff_depth_map, sizeof(int) * FREENECT_FRAME_PIX );
}

void maxThresholdInPlace( int * map ) {
  for (int y = 1 ; y < HEIGHT-1; y++) {
    for (int x = 1 ; x < WIDTH-1; x++) {
      int V = WIDTH * y + x;
      int value = map[V];
      map[V] = (value > gthreshold)?gthreshold:value;
    }
  }
}

void calcStats( int * map, double * avg, int * sum ) {
  int summation = 0;
  for(int i = 0 ; i < FREENECT_FRAME_PIX; i++) {
    summation += map[ i ];
  }
  *avg = (double)summation / (double)FREENECT_FRAME_PIX;
  *sum = summation;
}

void calcStatsForRegion( int * map, double * avg, int * sum, int startx, int starty, int width, int height ) {
  int summation = 0;
  for(int y = 0; y < height; y++) {
    for(int x = 0; x < width; x++) {
      summation += map[ WIDTH * (starty+y) + (startx+x) ];
    }
  }
  *avg = (double)summation / (double)(width * height);
  *sum = summation;
}

double semivariogram(Mat & m, int n) {
  // https://en.wikipedia.org/wiki/Variogram
  int x[n];
  int y[n];
  for (int i = 0 ; i < n; i++) {
    x[i] = rand() % WIDTH;
    y[i] = rand() % HEIGHT;
  }
  float dist[n][n];
  for (int i = 0; i < n; i++) {
    for (int j = i; j < n; j++) {
      float v = m.at<int>(y[i],x[i]) - m.at<int>(y[j],x[j]);      
      float v2 = v * v;
      dist[i][j] = v2;
      dist[j][i] = v2;
    }
  }
  Mat distm( n, n, CV_32F, dist, n * sizeof( float ) );
  Scalar mean;
  Scalar std;
  meanStdDev( distm, mean, std ); // 1/N * sum( dists squared )
  //fprintf(stderr, "MEAN: %e STD: %e \n", mean[0], std[0]);
  return sqrt(mean[0]);
}

// this variogram is to deal with the fact that I don't like the 0s they are special values
double semivariogram(Mat & m, int n, int minthreshold) {
  // https://en.wikipedia.org/wiki/Variogram
  int x[n];
  int y[n];
  for (int i = 0 ; i < n; i++) {
    x[i] = rand() % WIDTH;
    y[i] = rand() % HEIGHT;
  }
  float dist[n][n];
  for (int i = 0; i < n; i++) {
    for (int j = i; j < n; j++) {
      int d1 = m.at<int>(y[i],x[i]);
      int d2 = m.at<int>(y[j],x[j]);      
      float v =  (d1 < minthreshold || d2 < minthreshold)?0.0:(d1 - d2);
      
      float v2 = v * v;
      dist[i][j] = v2;
      dist[j][i] = v2;
    }
  }
  Mat distm( n, n, CV_32F, dist, n * sizeof( float ) );
  Scalar mean;
  Scalar std;
  meanStdDev( distm, mean, std ); // 1/N * sum( dists squared )
  //fprintf(stderr, "MEAN: %e STD: %e \n", mean[0], std[0]);
  return sqrt(mean[0]);
}

void mirrorDiff(Mat & m, double * meanout, double * stddevout) {
  Mat mflip;
  flip(m, mflip, 1); //flip around Y axis = 1, X = 0, -1 both
  Scalar mean;
  Scalar std;
  //fprintf(stderr, "MEAN: %e STD: %e \n", mean[0], std[0]);
  Mat diff;
  absdiff( m, mflip, diff);
  meanStdDev( diff, mean, std ); // 1/N * sum( dists squared )
  //fprintf(stderr, "MEAN: %e STD: %e \n", mean[0], std[0]);
  *meanout = mean[0];
  *stddevout = std[0];
}
// From http://stackoverflow.com/questions/3486172/angle-between-3-points#3487062
int getAngleABC( Point a, Point b, Point c )
{
  Point ab( b.x - a.x, b.y - a.y );
  Point cb( b.x - c.x, b.y - c.y );

  float dot = (ab.x * cb.x + ab.y * cb.y); // dot product
  float cross = (ab.x * cb.y - ab.y * cb.x); // cross product
  
  float alpha = atan2(cross, dot);
  
  return (int) floor(alpha * 180. / pi + 0.5);
}

static int dfirst = 1;
// Does everything
void DrawScene()
{
  Vector<string> output(300);

	pthread_mutex_lock(&gl_backbuf_mutex);

	// When using YUV_RGB mode, RGB frames only arrive at 15Hz, so we shouldn't force them to draw in lock-step.
	// However, this is CPU/GPU intensive when we are receiving frames in lockstep.
	if (current_format == FREENECT_VIDEO_YUV_RGB) {
		while (!got_depth && !got_rgb) {
			pthread_cond_wait(&gl_frame_cond, &gl_backbuf_mutex);
		}
	} else {
		while ((!got_depth || !got_rgb) && requested_format != current_format) {
			pthread_cond_wait(&gl_frame_cond, &gl_backbuf_mutex);
		}
	}

	if (requested_format != current_format) {
		pthread_mutex_unlock(&gl_backbuf_mutex);
		return;
	}

	uint8_t *tmp;

	if (got_depth) {

		int i = 0;
		int j = 0;
		int jmin = 0;
		int mprn = 200;
                int d = 0;
                int dv = 0;
		tmp = depth_front;
		depth_front = depth_mid;
		depth_mid = tmp;
                memcpy(color_diff_depth_map, depth_mid, WIDTH*HEIGHT*3);
		got_depth = 0;
		jmin = depth_map[ 0 ];
                Mat depthFrame(HEIGHT,WIDTH, MYCVTYPE, depth_map, sizeof(int) * WIDTH);
                

                //fprintf(stdout,"{ \"type\":\"frame\", \"frame\":%d, \"channels\":%d, \"BPP\":%d, \"W\":%d, \"H\":%d, \"WS\":%d, \"FPS\":%d, \"jmin\":%d, \"threshold\":%d,", //note lack ofnewline
               //         depth_frame,
               //         1,
               //         32,
               //         WIDTH,
               //         HEIGHT,
               //         WIDTH*sizeof(int), 
               //         30,
               //         jmin,
               //         gthreshold);

                /*

                Scalar mean;
                Scalar stddev;
                // has a mask..
                meanStdDev(depthFrame, mean, stddev);
                //fprintf(stdout,"\t\"mean\":%e, \"std\":%e, ",mean[0],stddev[0]);


                double mdiff;
                double mstd; 
                mirrorDiff( depthFrame, &mdiff, &mstd );
                //fprintf(stdout,"\t\"meanmirror\":%e,\"stdmirror\":%e,\t ", mdiff, mstd);
                

                Mat gray(HEIGHT, WIDTH, CV_8U);
                depthFrame.convertTo( gray, CV_8U);
                Moments mo = cv::moments( gray );
                double svariogram = semivariogram( depthFrame, 1000, 256 );
                svariogram = (svariogram != svariogram)?-666.0:svariogram;
                //fprintf( stdout, "\t\"semivariogram\":%e,\t", svariogram );


                Scalar diffMean;
                Scalar diffSTD ;
                Mat diffGray;
                {
                  Mat tmpGray1 = gray.colRange(0,WIDTH-1);
                  Mat tmpGray2 = gray.colRange(1,WIDTH);
                  diffGray = tmpGray2 - tmpGray1;
                  meanStdDev(diffGray, diffMean, diffSTD);
                  //fprintf(stdout,"\t\"diffMean\":%e,\"diffSTD\":%e,\t", diffMean[0], diffSTD[0]);
                }

                */

                //fprintf(stdout,"\t\"spacial-moments\":[%e,%e,%e,%e,%e,%e,%e,%e,%e,%e],\t",
                //       mo.m00, mo.m10, mo.m01, mo.m20, mo.m11, mo.m02, mo.m30, mo.m21, mo.m12, mo.m03);
                //fprintf(stdout,"\t\"central-moments\":[%e,%e,%e,%e,%e,%e,%e],\t", mo.mu20, mo.mu11, mo.mu02, mo.mu30, mo.mu21, mo.mu12, mo.mu03);

                /*

                double hu[7];
                cv::HuMoments( mo, hu );
                //fprintf(stdout,"\t\"hu\":[%e,%e,%e,%e,%e,%e],\t", hu[0], hu[1],hu[2],hu[3],hu[4],hu[5],hu[6]);

		// contour stuff
		vector<vector<Point> > contours;
		findContours( gray, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE );
                ////fprintf(stdout,"\t\"hulls\":[");
                //bool first = true;

                */

		Scalar color( rand()&255, rand()&255, rand()&255 );	
		Mat dst(HEIGHT, WIDTH, CV_8UC3, color_diff_depth_map);
		//drawContours(  dst , contours, -1, color, 3);

                /*

                // get convex hulls
                vector<vector<Point> >hulls ( contours.size() );
                for( int i = 0; i < contours.size(); i++ ) {
                  convexHull( Mat(contours[i]), hulls[i], false ); 
                }
                //fprintf(stdout,"\t\"hulls\":[\t");
                bool first = true;
                for (int i = 0; i < contours.size(); i++) {
                  double area = contourArea(hulls[i]);
                  if ( area > 1024 ) {
                    Scalar color( rand()&255, rand()&255, rand()&255 );	
                    drawContours( dst, hulls, i, color, 3);//, 8, vector<Vec4i>(), 0, Point() );
                    vector<Point> hull = hulls[i];
                    //fprintf(stdout,"%c{\"area\":%e,\"sides\":%d,\"points\":[",(first?' ':','), area, hull.size());
                    int hullsize = hull.size();
                    vector<double> angles( hullsize );
                    for (int j = 0; j < hullsize; j++) {
                      Point hx1 = hull[j];
                      Point hx2 = hull[(j+1)%hullsize];
                      Point hx3 = hull[(j+2)%hullsize];
                      angles[j] = getAngleABC( hx1, hx2, hx3 );                     
                      //fprintf(stdout,"%c%d,%d,%f",((j==0)?' ':','),  hx1.x, hx1.y, angles[j]);

                    }                 
                    Scalar amean;
                    Scalar astd;
                    meanStdDev(angles, amean, astd);                    
                    //fprintf(stdout,"],\"anglemean\":%e,\"anglestd\":%e}\t", amean[0], astd[0]); 
                    first = false;
                  }
                }
                //fprintf(stdout,"],\t"); 


                */

		gdegree = (gdegree + gtempo) % 360;
		const int len = min(WIDTH,HEIGHT)/2;

		//double theta = gdegree * (pi / 180.0f);
		//double xprime = len * cos( theta ) - 0 * sin(theta);
		//double yprime = len * sin( theta ) + 0 * cos(theta);
                int xprime = WIDTH-1;
		#define NSamples 100
		int samples[NSamples];
		for (int i = 0; i < NSamples; i++) {
			int x = 0 + i*xprime/(NSamples - 1);
			int y = gyline;// + i*yprime/(NSamples - 1);
			int sample = depth_map[x + y * WIDTH];
			samples[i] = sample;
		}
                //fprintf(stdout,"\t\"samples\":[");
		for (int i = 0; i < NSamples; i++) {
			if (i == 0) {
				fprintf(stdout,"%d", samples[i]);
			} else {
				fprintf(stdout,",%d", samples[i]);
			}
		}
                fprintf(stdout,"\n");
                //fprintf(stdout,"],\t");
                lo_blob btest = lo_blob_new(NSamples * sizeof(int), samples);
                lo_send(lo_t, "/samples", "b", btest);

		line( dst, Point2f(0, gyline), Point2f(WIDTH, gyline), Scalar(0,0,255), 4); 

		flip(dst,dst,1);


                /*
                const int hSize = 8;
                const int arr[] = { hSize };
                const int * histSize = arr;
                // 255 (pure spectrum color)
                const float srangesf[] = {0,256};
                const float * sranges[] = {srangesf};
                const int channelsi = 0;
                const int * channels = &channelsi;
                const Mat m[] = { gray  };
                const Mat mask;
                Mat hist;
	        try {
                	cv::calcHist( m, 1, &channelsi, mask,//do not use mask
                	              hist, 1, (const int*)histSize, (const float **)sranges,
                	              true, // the histogram is uniform
                	              false );
                	//fprintf(stdout,"\t\t\"hist\":[\t\t\t");
                	for( int h = 0; h < hSize; h++ ) {
                	  float binVal = hist.at<float>(h, 0);
                	  //fprintf(stdout,"%s%e",((h==0)?"":","),binVal);
                	}
                	//fprintf(stdout,"]\t");
                } catch (exception &e) {
			cout << e.what() << endl;
		}
                Mat diff(HEIGHT,WIDTH,MYCVTYPE);

                absdiff(depthFrame,lastDepthFrame,diff);
                meanStdDev(diff, mean, stddev);
                //fprintf(stdout,"\t,\"meandiff\":%e, \"stddiff\":%e\t",mean[0],stddev[0]);



                Mat left( diff, Range(0,HEIGHT-1),Range(0,WIDTH/3) );
                Mat right( diff, Range(0,HEIGHT-1), Range(2*WIDTH/3, WIDTH-1));
                Mat center( diff, Range(0,HEIGHT-1), Range(2*WIDTH/5, 4*WIDTH/5));

                meanStdDev(left, mean, stddev);
                //fprintf(stdout,"\t,\"leftmean\":%e, \"leftstd\":%e ",mean[0],stddev[0]);
                meanStdDev(right, mean, stddev);
                //fprintf(stdout,"\t,\"rightmean\":%e, \"rightstd\":%e ",mean[0],stddev[0]);
                meanStdDev(center, mean, stddev);
                //fprintf(stdout,"\t,\"centermean\":%e, \"centerstd\":%e ",mean[0],stddev[0]);
                

                */

                depthFrame.copyTo(lastDepthFrame);

                if (gkeydown) {
                  //fprintf(stdout,",\"keydown\":\"%c\"", gkeysym);
                  //gkeydown = false;
                }
                
                //fprintf(stdout,"}\n");


		depth_frame++;
                //fflush( stdout );



	}
	if (got_rgb) {
		tmp = rgb_front;
		rgb_front = rgb_mid;
		rgb_mid = tmp;
		got_rgb = 0;
	}

	pthread_mutex_unlock(&gl_backbuf_mutex);
#ifdef SDL
        SDL_Flip(sdlSurface);
#endif


#ifdef DOGL        
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();

	glEnable(GL_TEXTURE_2D);

	glBindTexture(GL_TEXTURE_2D, gl_depth_tex);

	glTexImage2D(GL_TEXTURE_2D, 0, 3, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, color_diff_depth_map );

	glBegin(GL_TRIANGLE_FAN);
	glColor4f(255.0f, 255.0f, 255.0f, 255.0f);
	glTexCoord2f(0, 0); glVertex3f(0,0,0);
	glTexCoord2f(1, 0); glVertex3f(640,0,0);
	glTexCoord2f(1, 1); glVertex3f(640,480,0);
	glTexCoord2f(0, 1); glVertex3f(0,480,0);
	glEnd();


	glutSwapBuffers();
#endif

}

#ifdef DOGL
void keyPressed(unsigned char key, int x, int y)
{
	if (key == 27) {
		die = 1;
		pthread_join(freenect_thread, NULL);
		glutDestroyWindow(window);
		free(color_diff_depth_map);
                free(depth_map);
                free(old_depth_map);
                free(diff_depth_map);
		free(depth_mid);
		free(depth_front);
		free(rgb_back);
		free(rgb_mid);
		free(rgb_front);
		pthread_exit(NULL);
	}
	if (key == 'w') {
		freenect_angle++;
		if (freenect_angle > 30) {
			freenect_angle = 30;
		}
	}
	if (key == 's') {
		freenect_angle = 0;
	}
	if (key == 'f') {
		if (requested_format == FREENECT_VIDEO_IR_8BIT)
			requested_format = FREENECT_VIDEO_RGB;
		else if (requested_format == FREENECT_VIDEO_RGB)
			requested_format = FREENECT_VIDEO_YUV_RGB;
		else
			requested_format = FREENECT_VIDEO_IR_8BIT;
	}
	if (key == 'x') {
		freenect_angle--;
		if (freenect_angle < -30) {
			freenect_angle = -30;
		}
	}
	if (key == '1') {
		freenect_set_led(f_dev,LED_GREEN);
	}
	if (key == '2') {
		freenect_set_led(f_dev,LED_RED);
	}
	if (key == '3') {
		freenect_set_led(f_dev,LED_YELLOW);
	}
	if (key == '4') {
		freenect_set_led(f_dev,LED_BLINK_GREEN);
	}
	if (key == '5') {
		// 5 is the same as 4
		freenect_set_led(f_dev,LED_BLINK_GREEN);
	}
	if (key == '6') {
		freenect_set_led(f_dev,LED_BLINK_RED_YELLOW);
	}
	if (key == '0') {
		freenect_set_led(f_dev,LED_OFF);
	}

	freenect_set_tilt_degs(f_dev,freenect_angle);
}
#endif

#ifdef DOGL
void ReSizeGLScene(int Width, int Height)
{
	glViewport(0,0,Width,Height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	//glOrtho (0, 1280, 480, 0, -1.0f, 1.0f);
        glOrtho (0, 640, 480, 0, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
}

void InitGL(int Width, int Height)
{
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0);
	glDepthFunc(GL_LESS);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glShadeModel(GL_SMOOTH);
	glGenTextures(1, &gl_depth_tex);
	glBindTexture(GL_TEXTURE_2D, gl_depth_tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glGenTextures(1, &gl_rgb_tex);
	glBindTexture(GL_TEXTURE_2D, gl_rgb_tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	ReSizeGLScene(Width, Height);
}
#endif


#ifdef DOGL
void *gl_threadfunc(void *arg)
{
  fprintf(stderr,"GL thread\n");

	glutInit(&g_argc, g_argv);

	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH);
	//glutInitWindowSize(1280, 480);
	glutInitWindowSize(640, 480);
	glutInitWindowPosition(0, 0);

	window = glutCreateWindow("LibFreenect");

	glutDisplayFunc(&DrawScene);
	glutIdleFunc(&DrawScene);
	glutReshapeFunc(&ReSizeGLScene);
	glutKeyboardFunc(&keyPressed);

	//InitGL(1280, 480);
	InitGL(640, 480);

	glutMainLoop();

	return NULL;
}
#endif
uint16_t t_gamma[2048];

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp)
{
	int i;
	uint16_t *depth = (uint16_t*)v_depth;

	pthread_mutex_lock(&gl_backbuf_mutex);
	for (i=0; i<FREENECT_FRAME_PIX; i++) {
		// Thresholding is being done here
                depth[i] = (depth[ i ] > gthreshold)?0:depth[i];//gthreshold:depth[ i ] ; 
		int pval = t_gamma[depth[i]];
		depth_map[ i ] = depth[ i ]; // (depth[ i ] > gthreshold)?gthreshold:depth[ i ] ; /* pval; */
		int lb = pval & 0xff;
		switch (pval>>8) {
			case 0:
				depth_mid[3*i+0] = 255;
				depth_mid[3*i+1] = 255-lb;
				depth_mid[3*i+2] = 255-lb;
				break;
			case 1:
				depth_mid[3*i+0] = 255;
				depth_mid[3*i+1] = lb;
				depth_mid[3*i+2] = 0;
				break;
			case 2:
				depth_mid[3*i+0] = 255-lb;
				depth_mid[3*i+1] = 255;
				depth_mid[3*i+2] = 0;
				break;
			case 3:
				depth_mid[3*i+0] = 0;
				depth_mid[3*i+1] = 255;
				depth_mid[3*i+2] = lb;
				break;
			case 4:
				depth_mid[3*i+0] = 0;
				depth_mid[3*i+1] = 255-lb;
				depth_mid[3*i+2] = 255;
				break;
			case 5:
				depth_mid[3*i+0] = 0;
				depth_mid[3*i+1] = 0;
				depth_mid[3*i+2] = 255-lb;
				break;
			default:
				depth_mid[3*i+0] = 0;
				depth_mid[3*i+1] = 0;
				depth_mid[3*i+2] = 0;
				break;
		}
	}
	got_depth++;
	pthread_cond_signal(&gl_frame_cond);
	pthread_mutex_unlock(&gl_backbuf_mutex);
}


void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp)
{
	pthread_mutex_lock(&gl_backbuf_mutex);

	// swap buffers
	assert (rgb_back == rgb);
	rgb_back = rgb_mid;
	freenect_set_video_buffer(dev, rgb_back);
	rgb_mid = (uint8_t*)rgb;

	got_rgb++;
	pthread_cond_signal(&gl_frame_cond);
	pthread_mutex_unlock(&gl_backbuf_mutex);
}

void *freenect_threadfunc(void *arg)
{
	int accelCount = 0;

	freenect_set_tilt_degs(f_dev,freenect_angle);
	freenect_set_led(f_dev,LED_RED);
	freenect_set_depth_callback(f_dev, depth_cb);
	freenect_set_video_callback(f_dev, rgb_cb);
        freenect_set_video_mode(f_dev, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, current_format));
        freenect_set_depth_mode(f_dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_11BIT));

	freenect_set_video_buffer(f_dev, rgb_back);

	freenect_start_depth(f_dev);
	freenect_start_video(f_dev);

	fprintf(stderr,"'w'-tilt up, 's'-level, 'x'-tilt down, '0'-'6'-select LED mode, 'f'-video format\n");

	while (!die && freenect_process_events(f_ctx) >= 0) {
		//Throttle the text output
		if (accelCount++ >= 2000)
		{
			accelCount = 0;
			freenect_raw_tilt_state* state;
			freenect_update_tilt_state(f_dev);
			state = freenect_get_tilt_state(f_dev);
			double dx,dy,dz;
			freenect_get_mks_accel(state, &dx, &dy, &dz);
			fprintf(stderr,"\r raw acceleration: %4d %4d %4d  mks acceleration: %4f %4f %4f", state->accelerometer_x, state->accelerometer_y, state->accelerometer_z, dx, dy, dz);
			fflush(stdout);
		}

		if (requested_format != current_format) {
			freenect_stop_video(f_dev);
			//freenect_set_video_format(f_dev, requested_format);
			freenect_set_video_mode(f_dev, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, requested_format));

			freenect_start_video(f_dev);
			current_format = requested_format;
		}
	}

	printf("\nshutting down streams...\n");

	freenect_stop_depth(f_dev);
	freenect_stop_video(f_dev);

	freenect_close_device(f_dev);
	freenect_shutdown(f_ctx);

	printf("-- done!\n");
	return NULL;
}

int main(int argc, char **argv)
{
	int res;
        
#ifdef SDL 
        SDL_Event e;
        SDL_MouseMotionEvent m;

#endif
#ifdef DOGL
	color_diff_depth_map = (uint8_t*)malloc(640*480*3);
#endif
        int pixels = 640*480;
        srand(time(0));

	
        depth_mid = (uint8_t*)malloc(640*480*3);
        depth_map = (int *) malloc(sizeof(int)*pixels);
        memset(depth_map, 0, sizeof(int)*pixels);
        old_depth_map = (int *) malloc(sizeof(int)*pixels);
        memset(old_depth_map, 0, sizeof(int)*pixels);
        diff_depth_map = (int *) malloc(sizeof(int)*pixels);
        memset(diff_depth_map, 0, sizeof(int)*pixels);
        tmp_diff_depth_map = (int *) malloc(sizeof(int)*pixels);
        memset(tmp_diff_depth_map, 0, sizeof(int)*pixels);

	depth_front = (uint8_t*)malloc(640*480*3);
	rgb_back = (uint8_t*)malloc(640*480*3);
	rgb_mid = (uint8_t*)malloc(640*480*3);
	rgb_front = (uint8_t*)malloc(640*480*3);

	//printf("Kinect camera test\n");

	int i;
	for (i=0; i<2048; i++) {
		float v = i/2048.0;
		v = powf(v, 3)* 6;
		t_gamma[i] = v*6*256;
	}


	g_argc = argc;
	g_argv = argv;

	if (freenect_init(&f_ctx, NULL) < 0) {
		printf("freenect_init() failed\n");
		return 1;
	}

	freenect_set_log_level(f_ctx, FREENECT_LOG_DEBUG);

	int nr_devices = freenect_num_devices (f_ctx);
	fprintf (stderr,"Number of devices found: %d\n", nr_devices);

	int user_device_number = 0;
	if (argc > 1)
		user_device_number = atoi(argv[1]);

	if (nr_devices < 1)
		return 1;

	if (freenect_open_device(f_ctx, &f_dev, user_device_number) < 0) {
		printf("Could not open device\n");
		return 1;
	}

        
        


	res = pthread_create(&freenect_thread, NULL, freenect_threadfunc, NULL);
	if (res) {
		printf("pthread_create failed\n");
		return 1;
	}





#ifdef SDL

        sdlSurface = SDL_SetVideoMode(WIDTH , HEIGHT, 24, 0); 
        SDL_WM_SetCaption("Shape Of Sound",0);
        atexit(SDL_Quit);
        color_diff_depth_map = (uint8_t*) sdlSurface->pixels;

        SDL_EnableKeyRepeat(30, 10);

        for(;;) {
          DrawScene();
          while (SDL_PollEvent(&e)) {
            switch (e.type) {
            case SDL_KEYUP:
              gkeydown = false;
              break;
            case SDL_KEYDOWN:
              gkeydown = true;
              gkeysym = e.key.keysym.sym;
              if (e.key.keysym.sym == 'x') {
		exit(0);               
              } else if (e.key.keysym.sym == SDLK_ESCAPE) { //Escape
		exit(0);               
              } else if (e.key.keysym.sym == 'k') {
              	gtempo--;
              } else if (e.key.keysym.sym == 'l') {
              	gtempo++;
              } else if (e.key.keysym.sym == '[') {
              	gyline--;
              } else if (e.key.keysym.sym == ']') {
              	gyline++;
              } else if (e.key.keysym.sym == 'h') {
              	gthreshold=(gthreshold>1024-10)?1024:(gthreshold+10);
              } else if (e.key.keysym.sym == 'j') {
              	gthreshold=(gthreshold<256+10)?256:(gthreshold-10);
              } else if (e.key.keysym.sym == 'r') {
		freenect_angle=0;
                freenect_set_tilt_degs(f_dev,freenect_angle);
              } else if (e.key.keysym.sym == '=') {
		freenect_angle++;
		if (freenect_angle > 30) {
                  freenect_angle = 30;
		}
                freenect_set_tilt_degs(f_dev,freenect_angle);
                        
              } else if ( e.key.keysym.sym == '-') {
		freenect_angle--;
		if (freenect_angle < -30) {
                  freenect_angle = -30;
		}
                freenect_set_tilt_degs(f_dev,freenect_angle);

              }
              break;
            case SDL_QUIT:
              exit(0);
            case SDL_MOUSEMOTION:
            case SDL_MOUSEBUTTONDOWN:
              m = e.motion;
              /* paint in the cursor on click */
                if (m.state) {
                } /* if state */
            } /* event type */
          } /* Poll */
          SDL_Delay(33);          
        }




#endif


#ifdef DOGL
	// OS X requires GLUT to run on the main thread
	gl_threadfunc(NULL);

#endif        
	return 0;
}
