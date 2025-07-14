#include <iostream>
#include <vector>
#include <string>
#include <memory>
#include <sstream>

/*
 * Simple benchmark script for memory measurement in C++
 * Performs basic computational tasks to generate measurable memory usage
 */

struct DataEntry {
    int id;
    std::string value;
    std::vector<int> data;
    
    DataEntry(int id) : id(id), data(10) {
        std::ostringstream oss;
        oss << id * 42;
        value = oss.str();
        
        for (int i = 0; i < 10; i++) {
            data[i] = i;
        }
    }
};

// Generate fibonacci sequence up to n
std::vector<int> fibonacci(int n) {
    std::vector<int> sequence;
    if (n <= 0) return sequence;
    
    sequence.push_back(0);
    if (n == 1) return sequence;
    
    sequence.push_back(1);
    
    for (int i = 2; i < n; i++) {
        sequence.push_back(sequence[i-1] + sequence[i-2]);
    }
    
    return sequence;
}

// Sieve of Eratosthenes to find primes up to limit
std::vector<int> prime_sieve(int limit) {
    std::vector<bool> sieve(limit + 1, true);
    std::vector<int> primes;
    
    if (limit < 2) return primes;
    
    sieve[0] = sieve[1] = false;
    
    for (int i = 2; i * i <= limit; i++) {
        if (sieve[i]) {
            for (int j = i * i; j <= limit; j += i) {
                sieve[j] = false;
            }
        }
    }
    
    for (int i = 2; i <= limit; i++) {
        if (sieve[i]) {
            primes.push_back(i);
        }
    }
    
    return primes;
}

// Allocate data structures to generate memory usage
int memory_allocator() {
    // Create vector of data entries to use memory
    std::vector<std::unique_ptr<DataEntry>> data;
    data.reserve(1000);
    
    for (int i = 0; i < 1000; i++) {
        data.push_back(std::make_unique<DataEntry>(i));
    }
    
    // Generate fibonacci numbers
    auto fib = fibonacci(50);
    if (fib.empty()) {
        return -1;
    }
    
    // Find prime numbers
    auto primes = prime_sieve(1000);
    if (primes.empty()) {
        return -1;
    }
    
    // Print some results
    std::cout << "Generated " << data.size() << " data entries" << std::endl;
    std::cout << "Fibonacci(50): " << fib.size() << " numbers, last value: " << fib.back() << std::endl;
    std::cout << "Primes up to 1000: " << primes.size() << " found" << std::endl;
    std::cout << "Largest prime: " << primes.back() << std::endl;
    
    return static_cast<int>(data.size() + fib.size() + primes.size());
}

int main() {
    std::cout << "PetriBench C++ Memory Benchmark" << std::endl;
    std::cout << "------------------------------" << std::endl;
    
    int result = memory_allocator();
    
    if (result < 0) {
        std::cout << "Memory allocation failed" << std::endl;
        return 1;
    }
    
    std::cout << "Total operations: " << result << std::endl;
    std::cout << "Benchmark completed successfully" << std::endl;
    
    return 0;
}