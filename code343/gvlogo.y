%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_thread.h>

// Define constants and structures
#define WIDTH 640
#define HEIGHT 480

typedef struct {
    int x;
    int y;
} position;

// Global variables
static SDL_Window* window;
static SDL_Renderer* rend;
static SDL_Texture* texture;
static SDL_Thread* background_id;
static SDL_Event event;
static int running = 1;
static const int PEN_EVENT = SDL_USEREVENT + 1;
static const int DRAW_EVENT = SDL_USEREVENT + 2;
static const int COLOR_EVENT = SDL_USEREVENT + 3;
static position current_pos = {WIDTH / 2, HEIGHT / 2};
static int pen_state = 1;
static double direction = 0.0;

// Function prototypes
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
void save(const char* path);
void shutdown();
void goto_position(int x, int y);
void print_position();

%}

%union {
    float f;
    int i;
    char* s;
}

%locations

%token SEP
%token PENUP
%token PENDOWN
%token PRINT
%token CHANGE_COLOR
%token COLOR
%token CLEAR
%token TURN
%token LOOP
%token MOVE
%token NUMBER
%token END
%token SAVE
%token GOTO
%token WHERE
%token PLUS SUB MULT DIV
%token<s> STRING QSTRING
%type<i> expression

%%

program: statement_list END { printf("Program complete."); shutdown(); exit(0); };

statement_list: statement | statement statement_list;

statement: command SEP { prompt(); } | error '\n' { yyerrok; prompt(); };

command: PENUP { penup(); } | PENDOWN { pendown(); } | PRINT QSTRING { output($2); } | SAVE STRING { save($2); } | COLOR NUMBER NUMBER NUMBER { change_color($2, $3, $4); } | CLEAR { clear(); } | TURN expression { turn($2); } | MOVE expression { move($2); } | GOTO expression expression { goto_position($2, $3); } | WHERE { print_position(); };

expression: NUMBER PLUS expression { $$ = $1 + $3; } | NUMBER MULT expression { $$ = $1 * $3; } | NUMBER SUB expression { $$ = $1 - $3; } | NUMBER DIV expression { $$ = $1 / $3; } | NUMBER { $$ = $1; };

%%

int main(int argc, char** argv){
    startup();
    return 0;
}

int yyerror(const char* s){
    printf("Error: %s\n", s);
    return -1;
}

void prompt(){
    printf("gv_logo > ");
}

void penup(){
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
    event.user.data1 = num;
    SDL_PushEvent(&event);
}

void turn(int dir){
    event.type = PEN_EVENT;
    event.user.code = 2;
    event.user.data1 = dir;
    SDL_PushEvent(&event);
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

void save(const char* path){
    SDL_Surface *surface = SDL_CreateRGBSurface(0, WIDTH, HEIGHT, 32, 0, 0, 0, 0);
    SDL_RenderReadPixels(rend, NULL, SDL_PIXELFORMAT_ARGB8888, surface->pixels, surface->pitch);
    SDL_SaveBMP(surface, path);
    SDL_FreeSurface(surface);
}

void startup(){
    SDL_Init(SDL_INIT_VIDEO);
    window = SDL_CreateWindow("GV-Logo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    if (window == NULL){
        yyerror("Can't create SDL window.\n");
    }
    
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
                    double degrees = ((int)e.user.data1) * M_PI / 180.0;
                    direction += degrees;
                }
                pen_state = e.user.code;
            }
            if(e.type == DRAW_EVENT){
                if(e.user.code == 1){
                    int num = (int)event.user.data1;
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

void goto_position(int x, int y) {
    x = x < 0 ? 0 : (x >= WIDTH ? WIDTH - 1 : x);
    y = y < 0 ? 0 : (y >= HEIGHT ? HEIGHT - 1 : y);
    x = (int)x;
    y = (int)y;
    if (pen_state != 0) {
        SDL_SetRenderTarget(rend, texture);
        SDL_RenderDrawLine(rend, x, y, x, y);
        SDL_SetRenderTarget(rend, NULL);
        SDL_RenderCopy(rend, texture, NULL, NULL);
    }
    current_pos.x = x;
    current_pos.y = y;
}

void print_position() {
    printf("Current position: (%d, %d)\n", current_pos.x, current_pos.y);
}
