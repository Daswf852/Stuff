#pragma once

#include <atomic>
#include <condition_variable>
#include <exception>
#include <mutex>
#include <spdlog/spdlog.h>
#include <thread>
#include <utility>

#include "utils.hpp"

namespace Shiba {

class Worker {
  public:
    Worker()
    : thread(std::thread()) {}

    ~Worker() {
        Quit();
        Join();
    }

    void Notify() {
        std::unique_lock lock(notificationMutex);
        notified = true;
        quitting = false;
        cv.notify_one();
    }

    void Quit(bool lock = true) {
        std::unique_lock<std::mutex> notifLock;
        if (lock) {
            std::unique_lock temp(notificationMutex);
            notifLock.swap(temp);
        }

        notified = true;
        quitting = true;
        cv.notify_one();
    }

    void Join(bool lock = true) {
        std::unique_lock<std::mutex> threadLock;
        if (lock) {
            std::unique_lock temp(threadMutex);
            threadLock.swap(temp);
        }

        try {
            if (thread.joinable()) {
                thread.join();
            }
        } catch (...) {
            HandleException(std::current_exception()); //probably couldn't join the thread in time
        }
    }

    bool Working() const {
        return working;
    }

    template<typename Func, typename... Args>
    void Work(Func &&func, Args &&... args) {
        std::unique_lock threadLock(threadMutex);
        Quit(false);
        Join(false);

        std::unique_lock notifLock(notificationMutex);
        notified = false;
        quitting = false;
        thread = std::thread(&Worker::WorkerWrapper<Func &&, Args &&...>, this, std::forward<Func &&>(func), std::forward<Args &&>(args)...);
    }

    template<typename Func, typename... Args>
    void WorkerWrapper(Func &&func, Args &&... args) {
        //spdlog::trace("a worker is starting");
        for (;;) {
            std::unique_lock notifLock(notificationMutex);
            if (notified && quitting)
                break;
            notifLock.unlock();

            std::unique_lock cvLock(cvMutex);
            cv.wait(cvLock);

            notifLock.lock();

            if (!notified) {
                spdlog::warn("spurious wake up on a worker");
                continue;
            }

            if (quitting)
                break;

            working = true;
            try {
                std::invoke(std::forward<Func>(func), args...);
            } catch (...) {
                HandleException(std::current_exception(), "A worker threw up");
            }
            working = false;
        }
        //spdlog::trace("a worker is quitting");
    }

  private:
    std::mutex threadMutex;
    std::thread thread;

    std::mutex cvMutex;
    std::condition_variable cv;

    std::mutex notificationMutex; //possible race: 2 notifications are made before the worker can respond to the first
                                  //not too big of an issue
    bool quitting = false;
    bool notified = false;

    std::atomic_bool working{false};
};

} // namespace Shiba