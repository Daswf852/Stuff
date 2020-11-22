#pragma once

#include <chrono>
#include <cmath>
#include <limits>
#include <random>
#include <span>
#include <sstream>
#include <thread>
#include <type_traits>
#include <vector>

#include <SFML/Graphics.hpp>
#include <spdlog/spdlog.h>

#include "thing.hpp"

namespace KMeans {

template<typename HPCType = long double>
class SFKMeans {
  public:
    SFKMeans(sf::Image &image, std::size_t clusterCount)
    : image(image)
    , clusterCount(clusterCount)
    , clusterAssignments(image.getSize().x * image.getSize().y)
    , clusterCenters(clusterCount) {
        std::fill(clusterAssignments.begin(), clusterAssignments.end(), static_cast<HPCType>(0));
        std::fill(clusterCenters.begin(), clusterCenters.end(), std::array<HPCType, 3>{0, 0, 0});

        std::random_device dev;
        std::mt19937_64 eng;
        std::uniform_real_distribution<HPCType> dist(static_cast<HPCType>(0), static_cast<HPCType>(255) + ((std::numeric_limits<HPCType>::is_integer) ? 1 : std::numeric_limits<HPCType>::epsilon()));

        for (auto &coord : clusterCenters) {
            coord[0] = dist(eng);
            coord[1] = dist(eng);
            coord[2] = dist(eng);
        }
    }

    ~SFKMeans() {}

    void CycleST() {
        AssignClusters(8);
        RemakeClusterCenters();
    }

    void DebugCenters() {
        for (typename decltype(clusterCenters)::size_type i = 0; i < clusterCount; i++) {
            spdlog::debug("Center {}: ({}, {}, {})", i, clusterCenters[i][0], clusterCenters[i][1], clusterCenters[i][2]);
        }
    }

    friend std::ostringstream &operator<<(std::ostringstream &stream, const SFKMeans &km) {
        return stream;
    }

    std::vector<sf::Color> GetCenters() {
        std::vector<sf::Color> ret;
        for (auto &center : clusterCenters) {
            sf::Color colour;
            colour.r = static_cast<uint8_t>(center[0]);
            colour.g = static_cast<uint8_t>(center[1]);
            colour.b = static_cast<uint8_t>(center[2]);
            ret.push_back(colour);
        }
        return ret;
    }

  private:
    sf::Image &image;
    std::size_t clusterCount;

    std::vector<uint_fast8_t> clusterAssignments;
    std::vector<std::array<HPCType, 3>> clusterCenters;

    static constexpr inline HPCType Distance(const std::array<HPCType, 3> &lhs, const std::array<HPCType, 3> &rhs) {
        HPCType d0 = (rhs[0] - lhs[0]) * (rhs[0] - lhs[0]);
        HPCType d1 = (rhs[1] - lhs[1]) * (rhs[1] - lhs[1]);
        HPCType d2 = (rhs[2] - lhs[2]) * (rhs[2] - lhs[2]);
        return std::sqrt(d0 + d1 + d2);
    }

    //HPC is higher percision coordinate btw. just a shorthand for saying that a color channel is of higher percision than or equal to the percision of an integer
    static constexpr inline std::array<HPCType, 3> GenerateHPC(const sf::Color &color) {
        return std::array<HPCType, 3>{static_cast<HPCType>(color.r), static_cast<HPCType>(color.g), static_cast<HPCType>(color.b)};
    }

    static constexpr inline std::array<HPCType, 3> &AddHPC(std::array<HPCType, 3> &lhs, const std::array<HPCType, 3> &rhs) {
        lhs[0] += rhs[0];
        lhs[1] += rhs[1];
        lhs[2] += rhs[2];
        return lhs;
    }

    //S as in scalar
    static constexpr inline std::array<HPCType, 3> &MulHPCS(std::array<HPCType, 3> &lhs, int rhs) {
        lhs[0] *= static_cast<HPCType>(rhs);
        lhs[1] *= static_cast<HPCType>(rhs);
        lhs[2] *= static_cast<HPCType>(rhs);
        return lhs;
    }

    static constexpr inline std::array<HPCType, 3> &DivHPCS(std::array<HPCType, 3> &lhs, int rhs) {
        lhs[0] /= static_cast<HPCType>(rhs);
        lhs[1] /= static_cast<HPCType>(rhs);
        lhs[2] /= static_cast<HPCType>(rhs);
        return lhs;
    }

    void AssignClusters(std::size_t threadCount = 1) {
        auto worker = [&](const sf::Color *imagePtr, std::size_t start, std::size_t amount) {
            std::size_t end = start + amount;
            for (unsigned int idx = start; idx < end; idx++) {
                const auto &thisCoordinate = GenerateHPC(imagePtr[idx]);
                typename decltype(clusterCenters)::size_type closestCenter = -1;
                HPCType closestDistance = std::numeric_limits<HPCType>::max();

                for (typename decltype(clusterCenters)::size_type currentCenter = 0; currentCenter < clusterCenters.size(); currentCenter++) {
                    const auto &currentCenterCoords = clusterCenters[currentCenter];
                    HPCType currentDistance = Distance(thisCoordinate, currentCenterCoords);
                    if (currentDistance <= closestDistance) {
                        closestDistance = currentDistance;
                        closestCenter = currentCenter;
                    }
                }

                clusterAssignments[idx] = closestCenter;
            }
        };

        std::size_t workPer = image.getSize().x * image.getSize().y / threadCount;
        std::size_t residue = image.getSize().x * image.getSize().y % threadCount;
        std::vector<std::thread> threads(threadCount);

        for (std::size_t i = 0; i < threadCount; i++)
            threads.at(i) = std::thread(worker, (const sf::Color *)image.getPixelsPtr(), i * workPer, workPer + ((i == threadCount - 1) ? residue : 0));

        for (auto &thread : threads)
            try {
                thread.join();
            } catch (...) {
            }
    }

    void RemakeClusterCenters(std::size_t threadCount = 1) {
        std::vector<std::size_t> clusterMembers(clusterCount);
        std::fill(clusterMembers.begin(), clusterMembers.end(), 0);
        std::fill(clusterCenters.begin(), clusterCenters.end(), std::array<HPCType, 3>{0, 0, 0});
        const sf::Color *imagePtr = (const sf::Color *)image.getPixelsPtr();

        for (auto i : clusterAssignments) {
            clusterMembers.at(i)++;
        }

        for (unsigned int idx = 0; idx < image.getSize().x * image.getSize().y; idx++) {
            auto clusterIdForPixel = clusterAssignments[idx];
            auto currentColorC = GenerateHPC(imagePtr[idx]);
            DivHPCS(currentColorC, clusterMembers[clusterIdForPixel]);
            AddHPC(clusterCenters[clusterIdForPixel], currentColorC);
        }
    }
};

class KMeansThing : public Thing {
  public:
    KMeansThing() {
        font.loadFromFile("./fonts/RobotoMono/RobotoMono-VariableFont_wght.ttf");
    }

    ~KMeansThing() override {}

    int DoThings(const std::vector<std::string> &arguments) override {
        sf::Image image;
        sf::Texture texture;
        sf::Sprite sprite;

        std::string filename(arguments.at(1));
        unsigned int clusterCount = std::stoul(arguments.at(2));

        image.loadFromFile(filename);
        texture.loadFromImage(image);
        sprite.setTexture(texture);

        unsigned int imageWidth = image.getSize().x;
        unsigned int imageHeight = image.getSize().y;
        unsigned int colourHeight = 64;
        float colourWidth = (float)imageWidth / (float)clusterCount;

        std::vector<sf::RectangleShape> colours(clusterCount);
        for (unsigned int i = 0; i < clusterCount; i++) {
            colours[i].setPosition(colourWidth * i, imageHeight);
            colours[i].setSize({colourWidth, (float)colourHeight});
            colours[i].setFillColor(sf::Color::Green);
            colours[i].setOutlineThickness(0.f);
        }

        KMeans::SFKMeans km(image, clusterCount);

        sf::RenderWindow win(sf::VideoMode(imageWidth, imageHeight + colourHeight), "KMeans", sf::Style::Close | sf::Style::Titlebar);

        std::chrono::duration<double, std::milli> lowestUpdateLength = std::chrono::duration<double, std::milli>(std::numeric_limits<float>::max());

        while (win.isOpen()) {
            sf::Event event;
            while (win.pollEvent(event))
                if (event.type == sf::Event::Closed)
                    win.close();

            std::chrono::time_point updateStart = std::chrono::system_clock::now();
            km.CycleST();
            std::chrono::duration<double, std::milli> updateLength = std::chrono::system_clock::now() - updateStart;
            if (updateLength < lowestUpdateLength)
                lowestUpdateLength = updateLength;

            auto newColours = km.GetCenters();
            for (unsigned int i = 0; i < clusterCount; i++) {
                colours[i].setFillColor(newColours[i]);
            }

            std::ostringstream oss;
            oss << "Last update took " << updateLength.count() << "ms\n";
            oss << "Shortest update took " << lowestUpdateLength.count() << "ms";
            sf::Text text(oss.str(), font, 24);
            text.setFillColor(sf::Color::White);
            text.setOutlineColor(sf::Color::Black);

            win.clear();
            win.draw(sprite);
            for (auto &colour : colours)
                win.draw(colour);
            win.draw(text);
            win.display();
        }
        return 0;
    }

  private:
    sf::Font font;
};

} // namespace KMeans