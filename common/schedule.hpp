#pragma once

#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <exception>
#include <functional>
#include <thread>

#include "utils.hpp"
#include "worker.hpp"

namespace Shiba {

enum class ScheduleType {
    Timeout,
    BasicInterval,
    TickInterval
};

template<ScheduleType SType>
class Schedule {
  public:
    template<typename Func>
    Schedule(std::chrono::milliseconds timing, Func &&func)
    : timing(timing) {
        worker.Work(std::move(func));
        if constexpr (SType == ScheduleType::Timeout) {
            notifierThread = std::thread(&Schedule<SType>::TimeoutNotifier, this);
        } else if constexpr (SType == ScheduleType::BasicInterval) {
            notifierThread = std::thread(&Schedule<SType>::BasicIntervalNotifier, this);
        } else if constexpr (SType == ScheduleType::TickInterval) {
            notifierThread = std::thread(&Schedule<SType>::TickIntervalNotifier, this);
        }
    }

    ~Schedule() {
        Cancel();
        Join();
    }

    void Cancel() {
        cancel = true;
        cv.notify_one();
    }

    void Join() {
        if (notifierThread.joinable())
            try {
                notifierThread.join();
            } catch (...) {
                HandleException(std::current_exception(), "Joining schedule notifier thread");
            }
    }

  private:
    std::chrono::milliseconds timing;
    Worker worker;

    std::mutex cvMutex{};
    std::condition_variable cv{};
    std::atomic_bool cancel{false};
    std::thread notifierThread;

    void TimeoutNotifier() {
        std::chrono::time_point until = std::chrono::system_clock::now() + timing;

        std::unique_lock cvLock(cvMutex);
        cv.wait_until(cvLock, until);

        if (cancel)
            return;

        worker.Notify();
    }

    void BasicIntervalNotifier() {
        while (!cancel) {
            std::unique_lock cvLock(cvMutex);
            cv.wait_for(cvLock, timing);

            if (cancel)
                break;

            worker.Notify();
        }
    }

    void TickIntervalNotifier() {
        std::chrono::time_point start = std::chrono::system_clock::now();
        std::chrono::time_point lastExecution = start;

        auto getNextTimepoint = [&]() {
            std::chrono::time_point<std::chrono::system_clock> point;
            unsigned long skipped = 0;

            auto timePassed = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - lastExecution);
            skipped = timePassed / timing;

            point = lastExecution + (timing * (skipped + 1));

            return std::make_pair<std::chrono::time_point<std::chrono::system_clock>, unsigned long>(std::move(point), (unsigned long)skipped);
        };

        while (!cancel) {
            auto tp = getNextTimepoint();

            std::unique_lock cvLock(cvMutex);
            cv.wait_until(cvLock, tp.first);

            if (cancel)
                break;

            lastExecution = std::chrono::system_clock::now();
            worker.Notify();
        }
    }
};

/*template<typename Func>
using Timeout = Schedule<ScheduleType::Timeout, Func>;
template<typename Func>
using Interval = Schedule<ScheduleType::BasicInterval, Func>;
template<typename Func>
using TickInterval = Schedule<ScheduleType::TickInterval, Func>;*/

typedef Schedule<ScheduleType::Timeout> Timeout;
typedef Schedule<ScheduleType::BasicInterval> Interval;
typedef Schedule<ScheduleType::TickInterval> TickInterval;

} // namespace Shiba