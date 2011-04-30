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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "libfreenect.h"

#include <pthread.h>

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

int * depth_map;/*[ FREENECT_FRAME_PIX ]; */
int * old_depth_map;/*[ FREENECT_FRAME_PIX ];*/
int * diff_depth_map;/*[ FREENECT_FRAME_PIX ];*/
int * tmp_diff_depth_map;/*[ FREENECT_FRAME_PIX ];*/

int depth_frame = 0;
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



void DrawScene()
{
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
		got_depth = 0;
		jmin = depth_map[ 0 ];
		for ( i  = 1 ; i < FREENECT_FRAME_PIX ; i++ ) {
                  if (depth_map[ i ] == SHADOW) {
                    diff_depth_map[ i ] = SHADOW;
                  } else if (old_depth_map[ i ] == SHADOW) {
                    diff_depth_map[ i ] = SHADOW;
                  } else {
                    d = abs(depth_map[ i ] - old_depth_map[ i ]);
                    dv = abs(object_depth - depth_map[ i ]);
                    diff_depth_map[ i ] = (d > 1 && d < 30)?dv:SHADOW;//(d > 0)?d:0;
                  }
                  /* if (depth_frame != 0 && diff_depth_map[ i ] != SHADOW && diff_depth_map[ i ] != 0) {
                    fprintf( stdout, "diff: %d %d %d %d %d\n", depth_frame, i, diff_depth_map[i], depth_map[i], old_depth_map[i] );
                    } */
                  if (depth_map[ i ] != SHADOW) {
                    old_depth_map[ i ] = depth_map[ i ];
                    //dv = 255*abs(diff_depth_map[i])/255;
                  } else {
                  }

		}
                // smooth depth_map
                //despeckleInPlace( diff_depth_map );
                //smoothInPlace( diff_depth_map );

                int hit = 0;
                if (win > 0) {
                  for (i = 0; i < FREENECT_FRAME_PIX; i++) {
                    color_diff_depth_map[ 3 * i + REDOFF]    = (win%2)?255:0;
                    color_diff_depth_map[ 3 * i + BLUEOFF] = (win%2)?0:255;
                    color_diff_depth_map[ 3 * i + GREENOFF] = (win%2)?255:0;
                  }
                  hit = 0;
                  ghit = 0;
                  fprintf(stderr,"win %d",win);
                  win--;  
                } else {
                  for (i = 0; i < FREENECT_FRAME_PIX; i++) {
                    if (diff_depth_map[ i ] == SHADOW) {
                      color_diff_depth_map[ 3 * i + REDOFF] = 0;
                      color_diff_depth_map[ 3 * i + BLUEOFF] = depth_mid[3*i+1]>>1;
                      color_diff_depth_map[ 3 * i + GREENOFF] = depth_mid[3*i+2]>>1;
                    } else {
                      dv = diff_depth_map[i];
                      if (dv <= 10) {
                        hit++;                      
                      }
                      if (dv > 255) { dv = 255; }
                      color_diff_depth_map[ 3 * i + REDOFF]    = 255-dv;
                      color_diff_depth_map[ 3 * i + BLUEOFF] = 255-dv;
                      color_diff_depth_map[ 3 * i + GREENOFF] = 255-dv;
                    }
                  }
                }
                if (hit > 100) {
                  ghit++;
                  fprintf(stderr, "HITTING\n");
                } else {
                  ghit = (ghit > 0)?ghit-1:0;                  
                }
                if (ghit > 10) {
                  int v = object_depth;
                  while (abs(object_depth - v) < 200) {
                    int k = (960 - 350) / 3;
                    v = 350 + rand() % k + rand() % k + rand() % k;
                  }
                  object_depth = v;
                  hit = 0;
                  fprintf(stderr, "\n\n\n\n\n\nWE HIT IT [%d]\n\n\n\n", object_depth);
                  ghit = 0;
                  win = 10;
                  wotime = 0;
                } else {
                  wotime++;
                }
                int sum,sumleft,sumright,sumcenter;
                double avg,avgleft,avgright,avgcenter;
                calcStats( diff_depth_map, &avg, &sum);
                calcStatsForRegion( diff_depth_map, &avgcenter, &sumcenter, WIDTH/4, HEIGHT/4, WIDTH/2, HEIGHT/2);
                calcStatsForRegion( diff_depth_map, &avgleft, &sumleft, 0, 0, WIDTH/4, HEIGHT);
                calcStatsForRegion( diff_depth_map, &avgright, &sumright, 3*WIDTH/4, 0, WIDTH/4, HEIGHT);
                //fprintf(stderr, "i1 0 0 %d %f %d %f %d %f %d %f\n", sum, avg, sumcenter, avgcenter, sumleft, avgleft, sumright, avgright);
                //fprintf(stdout, "i1 0 0 %d %f %d %f %d %f %d %f\n", sum, avg, sumcenter, avgcenter, sumleft, avgleft, sumright, avgright);
                fprintf(stdout,"i2 0 0 %d %d\n",wotime,win);
		depth_frame++;
		fflush( stdout );
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
	/* glTexImage2D(GL_TEXTURE_2D, 0, 3, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, depth_front); */
	glTexImage2D(GL_TEXTURE_2D, 0, 3, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, color_diff_depth_map );

	glBegin(GL_TRIANGLE_FAN);
	glColor4f(255.0f, 255.0f, 255.0f, 255.0f);
	glTexCoord2f(0, 0); glVertex3f(0,0,0);
	glTexCoord2f(1, 0); glVertex3f(640,0,0);
	glTexCoord2f(1, 1); glVertex3f(640,480,0);
	glTexCoord2f(0, 1); glVertex3f(0,480,0);
	glEnd();

	// glBindTexture(GL_TEXTURE_2D, gl_rgb_tex);
	// if (current_format == FREENECT_VIDEO_RGB || current_format == FREENECT_VIDEO_YUV_RGB)
	// 	glTexImage2D(GL_TEXTURE_2D, 0, 3, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, rgb_front);
	// else
	// 	glTexImage2D(GL_TEXTURE_2D, 0, 1, 640, 480, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, rgb_front+640*4);
        // 
	// glBegin(GL_TRIANGLE_FAN);
	// glColor4f(255.0f, 255.0f, 255.0f, 255.0f);
	// glTexCoord2f(0, 0); glVertex3f(640,0,0);
	// glTexCoord2f(1, 0); glVertex3f(1280,0,0);
	// glTexCoord2f(1, 1); glVertex3f(1280,480,0);
	// glTexCoord2f(0, 1); glVertex3f(640,480,0);
	// glEnd();

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
		int pval = t_gamma[depth[i]];
		depth_map[ i ] = depth[ i ] ; /* pval; */
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
	freenect_set_video_format(f_dev, current_format);
	freenect_set_depth_format(f_dev, FREENECT_DEPTH_11BIT);
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
			freenect_set_video_format(f_dev, requested_format);
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
        SDL_WM_SetCaption("Goop",0);
        atexit(SDL_Quit);
        color_diff_depth_map = sdlSurface->pixels;


        for(;;) {
          DrawScene();
          while (SDL_PollEvent(&e)) {
            switch (e.type) {
            case SDL_KEYDOWN:
              if (e.key.keysym.sym == 'x') {
		exit(0);               
              } else if (e.key.keysym.sym == SDLK_ESCAPE) { //Escape
		exit(0);               
              } else if (e.key.keysym.sym == '+') {
              } else if (e.key.keysym.sym == '-') {
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
            
          }
          SDL_Delay(10);
        }


#endif


#ifdef DOGL
	// OS X requires GLUT to run on the main thread
	gl_threadfunc(NULL);

#endif        
	return 0;
}
