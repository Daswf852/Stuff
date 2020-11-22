#include <spdlog/spdlog.h>

#include "stuff/kmeans/kmeans.hpp"

int main(int argc, char **argv) {
    spdlog::set_level(spdlog::level::trace);
    spdlog::flush_on(spdlog::level::trace);

    std::vector<std::string> arguments(argc);
    for (int i = 0; i < argc; i++)
        arguments.at(i) = std::string(argv[i]);

    KMeans::KMeansThing km;
    km.DoThings(arguments);
    return 0;
}