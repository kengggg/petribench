import java.util.*;

/**
 * Simple benchmark script for memory measurement in Java
 * Performs basic computational tasks to generate measurable memory usage
 */
public class Benchmark {
    
    static class DataEntry {
        int id;
        String value;
        List<Integer> data;
        
        DataEntry(int id, String value, List<Integer> data) {
            this.id = id;
            this.value = value;
            this.data = data;
        }
    }
    
    // Generate fibonacci sequence up to n
    public static List<Long> fibonacci(int n) {
        List<Long> sequence = new ArrayList<>();
        sequence.add(0L);
        sequence.add(1L);
        
        while (sequence.size() < n) {
            int size = sequence.size();
            long next = sequence.get(size - 1) + sequence.get(size - 2);
            sequence.add(next);
        }
        
        return sequence;
    }
    
    // Sieve of Eratosthenes to find primes up to limit
    public static List<Integer> primeSieve(int limit) {
        boolean[] sieve = new boolean[limit + 1];
        Arrays.fill(sieve, true);
        sieve[0] = sieve[1] = false;
        
        for (int i = 2; i * i <= limit; i++) {
            if (sieve[i]) {
                for (int j = i * i; j <= limit; j += i) {
                    sieve[j] = false;
                }
            }
        }
        
        List<Integer> primes = new ArrayList<>();
        for (int i = 2; i <= limit; i++) {
            if (sieve[i]) {
                primes.add(i);
            }
        }
        
        return primes;
    }
    
    // Allocate data structures to generate memory usage
    public static int memoryAllocator() {
        // Create list of objects to use memory
        List<DataEntry> data = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            List<Integer> entryData = new ArrayList<>();
            for (int j = 0; j < 10; j++) {
                entryData.add(j);
            }
            
            DataEntry entry = new DataEntry(i, String.valueOf(i * 42), entryData);
            data.add(entry);
        }
        
        // Generate fibonacci numbers
        List<Long> fib = fibonacci(50);
        
        // Find prime numbers
        List<Integer> primes = primeSieve(1000);
        
        // Print some results
        System.out.println("Generated " + data.size() + " data entries");
        System.out.println("Fibonacci(50): " + fib.size() + " numbers, last value: " + fib.get(fib.size() - 1));
        System.out.println("Primes up to 1000: " + primes.size() + " found");
        System.out.println("Largest prime: " + primes.get(primes.size() - 1));
        
        return data.size() + fib.size() + primes.size();
    }
    
    public static void main(String[] args) {
        System.out.println("PetriBench Memory Benchmark");
        System.out.println("------------------------------");
        
        int result = memoryAllocator();
        
        System.out.println("Total operations: " + result);
        System.out.println("Benchmark completed successfully");
    }
}