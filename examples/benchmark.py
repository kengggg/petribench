#!/usr/bin/env python3
"""
Simple benchmark script for memory measurement
Performs basic computational tasks to generate measurable memory usage
"""

def fibonacci(n):
    """Generate fibonacci sequence up to n"""
    sequence = [0, 1]
    while len(sequence) < n:
        sequence.append(sequence[-1] + sequence[-2])
    return sequence

def prime_sieve(limit):
    """Sieve of Eratosthenes to find primes up to limit"""
    sieve = [True] * (limit + 1)
    sieve[0] = sieve[1] = False
    
    for i in range(2, int(limit**0.5) + 1):
        if sieve[i]:
            for j in range(i*i, limit + 1, i):
                sieve[j] = False
    
    return [i for i, is_prime in enumerate(sieve) if is_prime]

def memory_allocator():
    """Allocate some data structures to generate memory usage"""
    # Create lists and dictionaries to use memory
    data = []
    for i in range(1000):
        data.append({'id': i, 'value': str(i * 42), 'data': list(range(10))})
    
    # Generate fibonacci numbers
    fib = fibonacci(50)
    
    # Find prime numbers
    primes = prime_sieve(1000)
    
    # Print some results
    print(f"Generated {len(data)} data entries")
    print(f"Fibonacci(50): {len(fib)} numbers, last value: {fib[-1]}")
    print(f"Primes up to 1000: {len(primes)} found")
    print(f"Largest prime: {primes[-1]}")
    
    return len(data) + len(fib) + len(primes)

if __name__ == "__main__":
    print("PetriBench Memory Benchmark")
    print("-" * 30)
    
    result = memory_allocator()
    
    print(f"Total operations: {result}")
    print("Benchmark completed successfully")