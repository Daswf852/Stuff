from conans import ConanFile, CMake

class BotPPConan(ConanFile):
    settings = "build_type"
    
    #requires =          \
    #    "spdlog/1.8.0", \ #broken

    generators = "cmake"
    
    def configure(self):
        self.settings.build_type = "Debug"