#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * Simple benchmark script for memory measurement in C
 * Performs basic computational tasks to generate measurable memory usage
 */

typedef struct {
    int id;
    char value[20];
    int data[10];
} DataEntry;

// Generate fibonacci sequence up to n
int* fibonacci(int n, int* length) {
    int* sequence = malloc(n * sizeof(int));
    if (!sequence) return NULL;
    
    sequence[0] = 0;
    sequence[1] = 1;
    *length = 2;
    
    for (int i = 2; i < n; i++) {
        sequence[i] = sequence[i-1] + sequence[i-2];
        (*length)++;
    }
    
    return sequence;
}

// Sieve of Eratosthenes to find primes up to limit
int* prime_sieve(int limit, int* count) {
    char* sieve = calloc(limit + 1, sizeof(char));
    if (!sieve) return NULL;
    
    // Initialize sieve (0 = prime, 1 = not prime)
    sieve[0] = sieve[1] = 1;
    
    for (int i = 2; i * i <= limit; i++) {
        if (!sieve[i]) {
            for (int j = i * i; j <= limit; j += i) {
                sieve[j] = 1;
            }
        }
    }
    
    // Count primes
    *count = 0;
    for (int i = 2; i <= limit; i++) {
        if (!sieve[i]) (*count)++;
    }
    
    // Extract primes
    int* primes = malloc(*count * sizeof(int));
    if (!primes) {
        free(sieve);
        return NULL;
    }
    
    int index = 0;
    for (int i = 2; i <= limit; i++) {
        if (!sieve[i]) {
            primes[index++] = i;
        }
    }
    
    free(sieve);
    return primes;
}

// Allocate data structures to generate memory usage
int memory_allocator() {
    // Create array of structures to use memory
    DataEntry* data = malloc(1000 * sizeof(DataEntry));
    if (!data) return -1;
    
    for (int i = 0; i < 1000; i++) {
        data[i].id = i;
        snprintf(data[i].value, sizeof(data[i].value), "%d", i * 42);
        for (int j = 0; j < 10; j++) {
            data[i].data[j] = j;
        }
    }
    
    // Generate fibonacci numbers
    int fib_length;
    int* fib = fibonacci(50, &fib_length);
    if (!fib) {
        free(data);
        return -1;
    }
    
    // Find prime numbers
    int prime_count;
    int* primes = prime_sieve(1000, &prime_count);
    if (!primes) {
        free(data);
        free(fib);
        return -1;
    }
    
    // Print some results
    printf("Generated %d data entries\n", 1000);
    printf("Fibonacci(50): %d numbers, last value: %d\n", fib_length, fib[fib_length-1]);
    printf("Primes up to 1000: %d found\n", prime_count);
    printf("Largest prime: %d\n", primes[prime_count-1]);
    
    int result = 1000 + fib_length + prime_count;
    
    // Cleanup
    free(data);
    free(fib);
    free(primes);
    
    return result;
}

int main() {
    printf("PetriBench Memory Benchmark\n");
    printf("------------------------------\n");
    
    int result = memory_allocator();
    
    if (result < 0) {
        printf("Memory allocation failed\n");
        return 1;
    }
    
    printf("Total operations: %d\n", result);
    printf("Benchmark completed successfully\n");
    
    return 0;
}