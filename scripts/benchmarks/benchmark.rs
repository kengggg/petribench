/*!
 * Simple benchmark script for memory measurement in Rust
 * Performs basic computational tasks to generate measurable memory usage
 */

use std::collections::HashMap;

#[derive(Debug)]
struct DataEntry {
    id: usize,
    value: String,
    data: Vec<usize>,
}

// Generate fibonacci sequence up to n
fn fibonacci(n: usize) -> Vec<u64> {
    let mut sequence = vec![0, 1];
    while sequence.len() < n {
        let next = sequence[sequence.len() - 1] + sequence[sequence.len() - 2];
        sequence.push(next);
    }
    sequence
}

// Sieve of Eratosthenes to find primes up to limit
fn prime_sieve(limit: usize) -> Vec<usize> {
    let mut sieve = vec![true; limit + 1];
    sieve[0] = false;
    if limit > 0 {
        sieve[1] = false;
    }
    
    let mut i = 2;
    while i * i <= limit {
        if sieve[i] {
            let mut j = i * i;
            while j <= limit {
                sieve[j] = false;
                j += i;
            }
        }
        i += 1;
    }
    
    sieve
        .into_iter()
        .enumerate()
        .filter_map(|(index, is_prime)| if is_prime { Some(index) } else { None })
        .collect()
}

// Allocate data structures to generate memory usage
fn memory_allocator() -> usize {
    // Create vector of structures to use memory
    let mut data = Vec::with_capacity(1000);
    for i in 0..1000 {
        let entry = DataEntry {
            id: i,
            value: (i * 42).to_string(),
            data: (0..10).collect(),
        };
        data.push(entry);
    }
    
    // Generate fibonacci numbers
    let fib = fibonacci(50);
    
    // Find prime numbers
    let primes = prime_sieve(1000);
    
    // Print some results
    println!("Generated {} data entries", data.len());
    println!("Fibonacci(50): {} numbers, last value: {}", fib.len(), fib.last().unwrap());
    println!("Primes up to 1000: {} found", primes.len());
    println!("Largest prime: {}", primes.last().unwrap());
    
    data.len() + fib.len() + primes.len()
}

fn main() {
    println!("PetriBench Memory Benchmark");
    println!("------------------------------");
    
    let result = memory_allocator();
    
    println!("Total operations: {}", result);
    println!("Benchmark completed successfully");
}