require 'formula'

class Alpscore < Formula
  homepage "http://alpscore.org"
  url "alpscore"
  sha256 "91117c4503d207383b298a934325e7787359ba97b322923735dfcb4f0b9997a0"
  version "0.3.1"

  # fetch current version fro git (fix with first release)
  url "https://github.com/ALPSCore/ALPSCore/archive/v0.3.1.tar.gz"

  # head version checked out from git
  head "https://github.com/ALPSCore/ALPSCore.git"

  # options
  option "with-python", "Build python module"
  option "with-static", "Build static instead of shared libraries"
  option "without-mpi", "Disable building with MPI support"
  option :cxx11
  option "with-doc",    "Build documentation"
  option "with-tests",  "Build tests"

  # Dependencies
  # cmake
  depends_on "cmake"   => :build
  # boost - check mpi and c++11
  boost_options = []
  boost_options << "with-mpi" if build.with? "mpi" 
  boost_options << "without-single" if build.with? "mpi" 
  boost_options << "c++11" if build.cxx11? 
  depends_on "boost" => boost_options
  # python
  depends_on "python"  => [:optional] if build.with?"python"
  # mpi, hdf5, boost-python
  if build.cxx11?
      depends_on "open-mpi" => ["c++11", :recommended] if build.with? "mpi" # boost has troubles with mpich
      depends_on "boost-python" => ["c++11"] if build.with?"python"
      depends_on "hdf5" => ["c++11"]
  else
      depends_on :mpi      => [:cc, :cxx, :recommended] if build.with?"mpi"
      depends_on "boost-python" if build.with?"python"
      depends_on "hdf5"   
  end

  def install
      args = std_cmake_args
      # force release mode (taken from eigen formula)
      args.delete "-DCMAKE_BUILD_TYPE=None"
      args << "-DCMAKE_BUILD_TYPE=Release"
      # handle static/shared build
      if build.with?"static"
          args << "-DBuildStatic=ON"
          args << "-DBuildShared=OFF"
      else
          args << "-DBuildStatic=OFF"
          args << "-DBuildShared=ON"
      end

      # check python compilation only with shared mode
      if build.with?"static" and build.with?"python"
          raise <<-EOS.undent
              Build python requires building shared libraries. Use "--without-static". 
          EOS
      end

      # handle mpi
      if build.with?"mpi"
         args << "-DENABLE_MPI=ON"
      else
         args << "-DENABLE_MPI=OFF"
      end

      # handle python
      if build.with?"python"
          args << "-DBuildPython=ON"
      else
          args << "-DBuildPython=OFF"
      end

      # documentation
      if build.with?"doc"
          args << "-DDocumentation=ON"
      else
          args << "-DDocumentation=OFF"
      end

      # tutorials
      if build.with?"tutorials"
          args << "-DBuildTutorials=ON"
      else
          args << "-DBuildTutorials=OFF"
      end

      # testing
      if build.with?"testing"
          args << "-DTesting=ON"
      else
          args << "-DTesting=OFF"
      end

    
      # do the actual install
      # ENV.deparallelize  # if your formula fails when building in parallel
      mkdir "tmp"
      chdir "tmp"
      system "cmake", *args, ".."
      system "make", "install" 
  end

      # Testing
  test do
    system "make", "test" # if this fails, try separate make/make install steps
  end
end
