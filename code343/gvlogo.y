%{
#define WIDTH 640
#define HEIGHT 480

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_thread.h>

static SDL_Window* window;
static SDL_Renderer* rend;
static SDL_Texture* texture;
static SDL_Thread* background_id;
static SDL_Event event;
static int running = 1;
static const int PEN_EVENT = SDL_USEREVENT + 1;
static const int DRAW_EVENT = SDL_USEREVENT + 2;
static const int COLOR_EVENT = SDL_USEREVENT + 3;

typedef struct color_t {
    unsigned char r;
    unsigned char g;
    unsigned char b;
} color;

typedef struct {
char name[50];
int value;
}Variable;
Variable variables[100];

static color current_color;
static double x = WIDTH / 2;
static double y = HEIGHT / 2;
static int pen_state = 1;
static double direction = 0.0;

int yylex(void);
int yyerror(const char* s);
void startup();
int run(void* data);
void prompt();
void penup();
void pendown();
void move(int num);
void turn(int dir);
void output(const char* s);
void change_color(int r, int g, int b);
void clear();
void goto_coordinates(int x, int y);
void print_coordinates();
void output(const char* s);
void save(const char* path);
void shutdown();
int retrieve_variable(const char* name);


%}

%union {
    float f;
    char* s;
}

%locations

%token SEP
%token PENUP
%token PENDOWN
%token PRINT
%token SAVE
%token COLOR
%token CLEAR
%token TURN
%token MOVE
%token GOTO
%token WHERE
%token <f> NUMBER
%token <s> VARIABLE
%token END
%token PLUS
%token SUB
%token MULT
%token DIV
%token ASSIGN
%token <s> QSTRING
%type <f> expression
%left PLUS SUB
%left MULT DIV

%%

program:    statement_list END            { printf("Program complete."); shutdown(); exit(0); };

statement_list: statement               
               | statement statement_list
               ;

statement: command_statement
         | control_statement
         | error_statement
         ;
command_statement: PENUP 	{penup();}
                 | PENDOWN	{pendown();}
                 | PRINT QSTRING	{output($2);}
                 | SAVE QSTRING		{save($2); }
                 | COLOR expression expression expression 	{ change_color($2, $3, $4); }
                 | CLEAR	{ clear(); }
                 | TURN expression	{ turn($2); }
                 | MOVE expression	{ move($2); }
                 ;

control_statement: GOTO expression ',' expression	{ goto_coordinates($2,$4); }
                 | WHERE	{ print_coordinates(); }
                 ;

error_statement: error '\n'
               ;



expression: NUMBER                 { $$ = (int)$1; }
            | VARIABLE             { $$ = retrieve_variable($1); }
            | expression PLUS expression { $$ = $1 + $3; }
            | expression SUB expression { $$ = $1 - $3; }
            | expression MULT expression { $$ = $1 * $3; }
            | expression DIV expression { $$ = $1 / $3; }
            | '(' expression ')'  { $$ = $2; }
            ;

%%


int yywrap() {
    return 1;
}

void prompt(){
	printf("gv_logo > ");
}

void penup(){
	printf("I am here");
	event.type = PEN_EVENT;		
	event.user.code = 0;
	SDL_PushEvent(&event);
}

void pendown() {
	event.type = PEN_EVENT;		
	event.user.code = 1;
	SDL_PushEvent(&event);
}

void move(int num){
	event.type = DRAW_EVENT;
	event.user.code = 1;
	event.user.data1 =(void*)(intptr_t) num;
	SDL_PushEvent(&event);
}

void turn(int dir){
	event.type = PEN_EVENT;
	event.user.code = 2;
	event.user.data1 = (void*)(intptr_t) dir;
	SDL_PushEvent(&event);
}

void goto_coordinates(int x, int y){
    x = x;
    y = y;
    if(pen_state == 1){
        SDL_SetRenderTarget(rend, texture);
        SDL_RenderDrawLine(rend, x, y, x, y);
        SDL_SetRenderTarget(rend, NULL);
        SDL_RenderCopy(rend, texture, NULL, NULL);
    }
}

#include <stdio.h>
#include "gvlogo.tab.h"

int main() {
    startup();
    return 0;
}

void print_coordinates(){
    printf("Current coordinates: (%f, %f)\n", x, y);
}

int retrieve_variable(const char* name) {
    for (int i = 0; i < 100; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            return variables[i].value;
        }
    }
    printf("No variable found\n");
    return 0;
}
void output(const char* s){
	printf("%s\n", s);
}

void change_color(int r, int g, int b){
	event.type = COLOR_EVENT;
	current_color.r = r;
	current_color.g = g;
	current_color.b = b;
	SDL_PushEvent(&event);
}

void clear(){
	event.type = DRAW_EVENT;
	event.user.code = 2;
	SDL_PushEvent(&event);
}

void startup(){
	SDL_Init(SDL_INIT_VIDEO);
	window = SDL_CreateWindow("GV-Logo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
	if (window == NULL){
		yyerror("Can't create SDL window.\n");
	}
	
	//rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE);
	rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE | SDL_RENDERER_TARGETTEXTURE);
	SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);
	texture = SDL_CreateTexture(rend, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, WIDTH, HEIGHT);
	if(texture == NULL){
		printf("Texture NULL.\n");
		exit(1);
	}
	SDL_SetRenderTarget(rend, texture);
	SDL_RenderSetScale(rend, 3.0, 3.0);

	background_id = SDL_CreateThread(run, "Parser thread", (void*)NULL);
	if(background_id == NULL){
		yyerror("Can't create thread.");
	}
	while(running){
		SDL_Event e;
		while( SDL_PollEvent(&e) ){
			if(e.type == SDL_QUIT){
				running = 0;
			}
			if(e.type == PEN_EVENT){
				if(e.user.code == 2){
					double degrees = ((intptr_t)e.user.data1) * M_PI / 180.0;
					direction += degrees;
				}
				pen_state = e.user.code;
			}
			if(e.type == DRAW_EVENT){
				if(e.user.code == 1){
					int num = (intptr_t)event.user.data1;
					double x2 = x + num * cos(direction);
					double y2 = y + num * sin(direction);
					if(pen_state != 0){
						SDL_SetRenderTarget(rend, texture);
						SDL_RenderDrawLine(rend, x, y, x2, y2);
						SDL_SetRenderTarget(rend, NULL);
						SDL_RenderCopy(rend, texture, NULL, NULL);
					}
					x = x2;
					y = y2;
				} else if(e.user.code == 2){
					SDL_SetRenderTarget(rend, texture);
					SDL_RenderClear(rend);
					SDL_SetTextureColorMod(texture, current_color.r, current_color.g, current_color.b);
					SDL_SetRenderTarget(rend, NULL);
					SDL_RenderClear(rend);
				}
			}
			if(e.type == COLOR_EVENT){
				SDL_SetRenderTarget(rend, NULL);
				SDL_SetRenderDrawColor(rend, current_color.r, current_color.g, current_color.b, 255);
			}
			if(e.type == SDL_KEYDOWN){
			}

		}
		//SDL_RenderClear(rend);
		SDL_RenderPresent(rend);
		SDL_Delay(1000 / 60);
	}
}

int run(void* data){
	prompt();
	yyparse();
}

void shutdown(){
	running = 0;
	SDL_WaitThread(background_id, NULL);
	SDL_DestroyWindow(window);
	SDL_Quit();
}

void save(const char* path){
	SDL_Surface *surface = SDL_CreateRGBSurface(0, WIDTH, HEIGHT, 32, 0, 0, 0, 0);
	SDL_RenderReadPixels(rend, NULL, SDL_PIXELFORMAT_ARGB8888, surface->pixels, surface->pitch);
	SDL_SaveBMP(surface, path);
	SDL_FreeSurface(surface);
}
