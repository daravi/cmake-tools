from conans import ConanFile

class CMakeToolsConan(ConanFile):
    name = "cmake-tools"
    version = "1.0.0"
    url = "https://github.com/daravi/cmake-tools"
    license = "MIT"
    description = "Conan package for CMake (includes my helpers functions)"
    generators = "cmake"
    exports_sources = ["Utils.cmake", "cmake/*"]
    no_copy_source = True

    requires = (
        "cmake/3.18.4"
    )

    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}

    def package(self):
        self.copy("*")

    def package_id(self):
        self.info.header_only()
