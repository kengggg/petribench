using System;
using System.Collections.Generic;
using System.Linq;

/**
 * Simple benchmark script for memory measurement in C#
 * Performs basic computational tasks to generate measurable memory usage
 * 
 * Note: This requires compilation with .NET SDK:
 * dotnet new console -o benchmark
 * cp Benchmark.cs benchmark/Program.cs  
 * cd benchmark && dotnet build
 * docker run -v $(pwd)/bin/Debug/net8.0:/app petribench-csharp dotnet benchmark.dll
 */

namespace PetriBench
{
    public class DataEntry
    {
        public int Id { get; set; }
        public string Value { get; set; }
        public List<int> Data { get; set; }
        
        public DataEntry(int id, string value, List<int> data)
        {
            Id = id;
            Value = value;
            Data = data;
        }
    }
    
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
            
            return sieve
                .Select((isPrime, index) => new { isPrime, index })
                .Where(x => x.isPrime)
                .Select(x => x.index)
                .ToList();
        }
        
        // Allocate data structures to generate memory usage
        static int MemoryAllocator()
        {
            // Create list of objects to use memory
            var data = new List<DataEntry>();
            for (int i = 0; i < 1000; i++)
            {
                var entryData = Enumerable.Range(0, 10).ToList();
                var entry = new DataEntry(i, (i * 42).ToString(), entryData);
                data.Add(entry);
            }
            
            // Generate fibonacci numbers
            var fib = Fibonacci(50);
            
            // Find prime numbers
            var primes = PrimeSieve(1000);
            
            // Print some results
            Console.WriteLine($"Generated {data.Count} data entries");
            Console.WriteLine($"Fibonacci(50): {fib.Count} numbers, last value: {fib.Last()}");
            Console.WriteLine($"Primes up to 1000: {primes.Count} found");
            Console.WriteLine($"Largest prime: {primes.Last()}");
            
            return data.Count + fib.Count + primes.Count;
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
}