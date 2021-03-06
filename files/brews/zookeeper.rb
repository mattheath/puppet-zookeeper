require 'formula'

class Zookeeper < Formula
  homepage 'http://zookeeper.apache.org/'
  url 'http://www.apache.org/dyn/closer.cgi?path=zookeeper/zookeeper-3.4.5/zookeeper-3.4.5.tar.gz'
  sha1 'fd921575e02478909557034ea922de871926efc7'

  head 'http://svn.apache.org/repos/asf/zookeeper/trunk'

  version '3.4.5-boxen1'

  if build.head?
    depends_on :automake
    depends_on :libtool
  end

  option "perl",   "Build Perl bindings."
  option "python", "Build Python bindings."

  def install
    # Don't try to build extensions for PPC
    if Hardware.is_32_bit?
      ENV['ARCHFLAGS'] = "-arch i386"
    else
      ENV['ARCHFLAGS'] = "-arch i386 -arch x86_64"
    end

    # Prep work for svn compile.
    if build.head?
      system "ant", "compile_jute"

      cd "src/c" do
        system "autoreconf", "-if"
      end
    end

    build_python = build.include? "python"
    build_perl = build.include? "perl"

    # Build & install C libraries.
    cd "src/c" do
      system "./configure", "--disable-dependency-tracking",
                            "--prefix=#{prefix}",
                            "--without-cppunit"
      system "make install"
    end

    # Install Python bindings
    cd "src/contrib/zkpython" do
      system "python", "src/python/setup.py", "build"
      system "python", "src/python/setup.py", "install", "--prefix=#{prefix}"
    end if build_python

    # Install Perl bindings
    cd "src/contrib/zkperl" do
      system "perl", "Makefile.PL", "PREFIX=#{prefix}",
                                    "--zookeeper-include=#{include}/c-client-src",
                                    "--zookeeper-lib=#{lib}"
      system "make install"
    end if build_perl

    # Remove windows executables
    rm_f Dir["bin/*.cmd"]

    # Install Java stuff
    if build.head?
      system "ant"
      libexec.install %w(bin src/contrib src/java/lib)
      libexec.install Dir['build/*.jar']
    else
      libexec.install %w(bin contrib lib)
      libexec.install Dir['*.jar']
    end

  end
end