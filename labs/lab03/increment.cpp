#include <iostream>
#include <memory>
#include <vector>
#include <thread>
#include <mutex>
#include <condition_variable>

using namespace std;
using namespace std::chrono;

void increment(shared_ptr<int> value)
{
    // Loop 1 million times, incrementing value
    for (unsigned int i = 0; i < 1000000; ++i)
        // Increment value
        *value = *value + 1;
}

// Mutexes
mutex mut1;
mutex mut2;

void task1(condition_variable &cv, shared_ptr<int> counter, shared_ptr<int> num)
{
    cout << "task 1 - lvl1" << endl;
    auto lock1 = unique_lock<mutex>(mut1);
    for (int i = 0; i < 10000; i++)
    {
        *counter = *counter + 1;
        *num = *num + 5;
    }
    auto lock3 = unique_lock<mutex>(mut2);
    cout << "task 1 - lvl2" << endl;
    for (int i = 0; i < 10000; i++)
    {
        *num = *num + 5;
    }
}

void task2(condition_variable& cv, shared_ptr<int> counter, shared_ptr<int> num)
{
    cout << "task 2 - lvl1" << endl;
    auto lock2 = unique_lock<mutex>(mut2);
    for (int i = 0; i < 10000; i++)
    {
        *num = *num - 5;
        *counter = *counter - 1;
    }
    auto lock4 = unique_lock<mutex>(mut1);
    cout << "task 2 - lvl2" << endl;
    for (int i = 0; i < 10000; i++)
    {
        *counter = *counter - 1;
    }
}

int main(int argc, char **argv)
{
    /** ORIGINAL CODE : **
    
    // Create a shared int value
    auto value = make_shared<int>(0);

    // Create number of threads hardware natively supports
    auto num_threads = thread::hardware_concurrency();
    vector<thread> threads;
    for (unsigned int i = 0; i < num_threads; ++i)
        threads.push_back(thread(increment, value));

    // Join the threads
    for (auto &t : threads)
        t.join();

    // Display the value
    cout << "Value = " << *value << endl;
    */

    // DEADLOCKSTASK:
    vector<thread> threads;
    condition_variable cv;
    auto counter = make_shared<int>(0);
    auto number = make_shared<int>(0);
    
    threads.push_back(thread(task1,ref(cv), counter, number));
    threads.push_back(thread(task2, ref(cv), counter, number));

    this_thread::sleep_for(milliseconds(5));

    for (auto& t : threads)
    {
        t.join();
    }
}