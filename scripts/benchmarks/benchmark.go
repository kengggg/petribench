package main

import (
	"fmt"
	"strconv"
)

// fibonacci generates fibonacci sequence up to n
func fibonacci(n int) []int {
	sequence := []int{0, 1}
	for len(sequence) < n {
		next := sequence[len(sequence)-1] + sequence[len(sequence)-2]
		sequence = append(sequence, next)
	}
	return sequence
}

// primeSieve implements Sieve of Eratosthenes to find primes up to limit
func primeSieve(limit int) []int {
	sieve := make([]bool, limit+1)
	for i := range sieve {
		sieve[i] = true
	}
	sieve[0] = false
	sieve[1] = false

	for i := 2; i*i <= limit; i++ {
		if sieve[i] {
			for j := i * i; j <= limit; j += i {
				sieve[j] = false
			}
		}
	}

	var primes []int
	for i, isPrime := range sieve {
		if isPrime {
			primes = append(primes, i)
		}
	}
	return primes
}

// memoryAllocator creates data structures to generate memory usage
func memoryAllocator() int {
	// Create slice of maps to use memory
	data := make([]map[string]interface{}, 1000)
	for i := 0; i < 1000; i++ {
		data[i] = map[string]interface{}{
			"id":    i,
			"value": strconv.Itoa(i * 42),
			"data":  make([]int, 10),
		}
		// Fill the slice
		for j := 0; j < 10; j++ {
			data[i]["data"].([]int)[j] = j
		}
	}

	// Generate fibonacci numbers
	fib := fibonacci(50)

	// Find prime numbers
	primes := primeSieve(1000)

	// Print some results
	fmt.Printf("Generated %d data entries\n", len(data))
	fmt.Printf("Fibonacci(50): %d numbers, last value: %d\n", len(fib), fib[len(fib)-1])
	fmt.Printf("Primes up to 1000: %d found\n", len(primes))
	fmt.Printf("Largest prime: %d\n", primes[len(primes)-1])

	return len(data) + len(fib) + len(primes)
}

func main() {
	fmt.Println("PetriBench Memory Benchmark")
	fmt.Println("------------------------------")

	result := memoryAllocator()

	fmt.Printf("Total operations: %d\n", result)
	fmt.Println("Benchmark completed successfully")
}