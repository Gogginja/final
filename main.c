#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Define constants for the number of each type of resource
#define NUM_MIXERS 2
#define NUM_REFRIGERATORS 2
#define NUM_BOWLS 3
#define NUM_SPOONS 5
#define NUM_OVENS 1

// Semaphores for resources
sem_t mixer_sem, pantry_sem, refrigerator_sem[NUM_REFRIGERATORS], bowl_sem, spoon_sem, oven_sem;

// Initialize resources
void initialize_resources() {
    sem_init(&mixer_sem, 0, NUM_MIXERS);
    sem_init(&pantry_sem, 0, 1);
    for (int i = 0; i < NUM_REFRIGERATORS; i++) {
        sem_init(&refrigerator_sem[i], 0, 1);
    }
    sem_init(&bowl_sem, 0, NUM_BOWLS);
    sem_init(&spoon_sem, 0, NUM_SPOONS);
    sem_init(&oven_sem, 0, NUM_OVENS);
}

// Baker structure
typedef struct {
    int id;
    char* color;
} Baker;

// Function to simulate getting ingredients from the pantry
void get_ingredients(Baker *baker) {
    sem_wait(&pantry_sem);
    printf("%s Baker %d is getting ingredients from the pantry.\n", baker->color, baker->id);
    sleep(1); // Simulate time taken to gather ingredients
    sem_post(&pantry_sem);
}

// Function to mix ingredients
void mix_ingredients(Baker *baker) {
    sem_wait(&mixer_sem);
    sem_wait(&bowl_sem);
    sem_wait(&spoon_sem);
    printf("%s Baker %d is mixing ingredients.\n", baker->color, baker->id);
    sleep(2); // Simulate mixing time
    sem_post(&spoon_sem);
    sem_post(&bowl_sem);
    sem_post(&mixer_sem);
}

// Function to bake the mixed ingredients
void bake(Baker *baker) {
    sem_wait(&oven_sem);
    printf("%s Baker %d is baking.\n", baker->color, baker->id);
    sleep(3); // Simulate baking time
    sem_post(&oven_sem);
}

void *baker_routine(void *arg) {
    Baker *baker = (Baker *)arg;
    get_ingredients(baker);
    mix_ingredients(baker);
    bake(baker);
    printf("%s Baker %d has finished baking.\n", baker->color, baker->id);
    return NULL;
}

int main() {
    initialize_resources();
    int num_bakers;
    printf("Enter the number of bakers: ");
    scanf("%d", &num_bakers);

    pthread_t bakers[num_bakers];
    Baker baker_data[num_bakers];

    for (int i = 0; i < num_bakers; i++) {
        baker_data[i].id = i;
        baker_data[i].color = (i % 2 == 0) ? "\x1B[31m" : "\x1B[34m"; // Red or Blue
        pthread_create(&bakers[i], NULL, baker_routine, &baker_data[i]);
    }

    for (int i = 0; i < num_bakers; i++) {
        pthread_join(bakers[i], NULL);
    }

    return 0;
}
