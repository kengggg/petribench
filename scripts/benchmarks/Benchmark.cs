using System;
using System.Collections.Generic;

/**
 * Simple benchmark script for memory measurement in C#
 * Performs basic computational tasks to generate measurable memory usage
 * Single class - no separate classes for simplicity
 */
class Program
{
    // Generate fibonacci sequence up to n
    static List<long> Fibonacci(int n)
    {
        var sequence = new List<long> { 0, 1 };
        
        while (sequence.Count < n)
        {
            long next = sequence[sequence.Count - 1] + sequence[sequence.Count - 2];
            sequence.Add(next);
        }
        
        return sequence;
    }
    
    // Sieve of Eratosthenes to find primes up to limit
    static List<int> PrimeSieve(int limit)
    {
        var sieve = new bool[limit + 1];
        Array.Fill(sieve, true);
        sieve[0] = sieve[1] = false;
        
        for (int i = 2; i * i <= limit; i++)
        {
            if (sieve[i])
            {
                for (int j = i * i; j <= limit; j += i)
                {
                    sieve[j] = false;
                }
            }
        }
        
        var primes = new List<int>();
        for (int i = 2; i <= limit; i++)
        {
            if (sieve[i])
            {
                primes.Add(i);
            }
        }
        
        return primes;
    }
    
    // Allocate data structures to generate memory usage
    static int MemoryAllocator()
    {
        // Create simple string data to use memory
        var data = new List<string>();
        for (int i = 0; i < 1000; i++)
        {
            data.Add($"Entry{i}:{i * 42}");
        }
        
        // Create nested lists for memory usage
        var nestedData = new List<List<int>>();
        for (int i = 0; i < 100; i++)
        {
            var subList = new List<int>();
            for (int j = 0; j < 10; j++)
            {
                subList.Add(i * j);
            }
            nestedData.Add(subList);
        }
        
        // Generate fibonacci numbers
        var fib = Fibonacci(50);
        
        // Find prime numbers
        var primes = PrimeSieve(1000);
        
        // Print some results
        Console.WriteLine($"Generated {data.Count} data entries");
        Console.WriteLine($"Created {nestedData.Count} nested data structures");
        Console.WriteLine($"Fibonacci(50): {fib.Count} numbers, last value: {fib[fib.Count - 1]}");
        Console.WriteLine($"Primes up to 1000: {primes.Count} found");
        Console.WriteLine($"Largest prime: {primes[primes.Count - 1]}");
        
        return data.Count + nestedData.Count + fib.Count + primes.Count;
    }
    
    static void Main(string[] args)
    {
        Console.WriteLine("PetriBench Memory Benchmark");
        Console.WriteLine("------------------------------");
        
        int result = MemoryAllocator();
        
        Console.WriteLine($"Total operations: {result}");
        Console.WriteLine("Benchmark completed successfully");
    }
}