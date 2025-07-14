#!/usr/bin/env node

/**
 * Simple benchmark script for memory measurement in Node.js
 * Performs basic computational tasks to generate measurable memory usage
 */

// Generate fibonacci sequence up to n
function fibonacci(n) {
    const sequence = [0, 1];
    while (sequence.length < n) {
        const next = sequence[sequence.length - 1] + sequence[sequence.length - 2];
        sequence.push(next);
    }
    return sequence;
}

// Sieve of Eratosthenes to find primes up to limit
function primeSieve(limit) {
    const sieve = new Array(limit + 1).fill(true);
    sieve[0] = sieve[1] = false;
    
    for (let i = 2; i * i <= limit; i++) {
        if (sieve[i]) {
            for (let j = i * i; j <= limit; j += i) {
                sieve[j] = false;
            }
        }
    }
    
    return sieve
        .map((isPrime, index) => isPrime ? index : null)
        .filter(num => num !== null);
}

// Allocate data structures to generate memory usage
function memoryAllocator() {
    // Create arrays and objects to use memory
    const data = [];
    for (let i = 0; i < 1000; i++) {
        data.push({
            id: i,
            value: String(i * 42),
            data: Array.from({ length: 10 }, (_, j) => j)
        });
    }
    
    // Generate fibonacci numbers
    const fib = fibonacci(50);
    
    // Find prime numbers
    const primes = primeSieve(1000);
    
    // Print some results
    console.log(`Generated ${data.length} data entries`);
    console.log(`Fibonacci(50): ${fib.length} numbers, last value: ${fib[fib.length - 1]}`);
    console.log(`Primes up to 1000: ${primes.length} found`);
    console.log(`Largest prime: ${primes[primes.length - 1]}`);
    
    return data.length + fib.length + primes.length;
}

function main() {
    console.log("PetriBench Memory Benchmark");
    console.log("------------------------------");
    
    const result = memoryAllocator();
    
    console.log(`Total operations: ${result}`);
    console.log("Benchmark completed successfully");
}

// Run if this is the main module
if (require.main === module) {
    main();
}