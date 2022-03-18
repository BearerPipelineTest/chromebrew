require 'package'

class Python3 < Package
  description 'Python is a programming language that lets you work quickly and integrate systems more effectively.'
  homepage 'https://www.python.org/'
  @_ver = '3.10.3'
  version @_ver
  license 'PSF-2.0'
  compatibility 'all'
  source_url "https://www.python.org/ftp/python/#{@_ver}/Python-#{@_ver}.tar.xz"
  source_sha256 '596c72de998dc39205bc4f70ef0dbf7edec740a306d09b49a9bd0a77806730dc'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/python3/3.10.3_armv7l/python3-3.10.3-chromeos-armv7l.tar.zst',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/python3/3.10.3_armv7l/python3-3.10.3-chromeos-armv7l.tar.zst',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/python3/3.10.3_i686/python3-3.10.3-chromeos-i686.tar.zst',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/python3/3.10.3_x86_64/python3-3.10.3-chromeos-x86_64.tar.zst'
  })
  binary_sha256({
    aarch64: '5b420fb5cf3fa3fb2bc4bc5abb15e212cf3b49d42bbea71997687af91aaaf597',
     armv7l: '5b420fb5cf3fa3fb2bc4bc5abb15e212cf3b49d42bbea71997687af91aaaf597',
       i686: '4d5d15fde337083bbdb2c1e00b89d22ab3c7de167f6e31af3882643b92f3bd8f',
     x86_64: '0cbb6b71baff03210c0953f01671b5cfdf33bbcdbd5aeaa8fbf7bee74244a274'
  })

  depends_on 'autoconf_archive' => :build
  depends_on 'krb5' => :build
  depends_on 'libtirpc' => :build
  depends_on 'bz2' # R
  depends_on 'expat' # R
  depends_on 'gdbm' # R
  depends_on 'glibc' # R
  depends_on 'libdb' # R
  depends_on 'libffi' # R
  depends_on 'mpdecimal' # R
  depends_on 'ncurses' # R
  depends_on 'openssl' # R
  depends_on 'readline' # R
  depends_on 'sqlite' # R
  depends_on 'xzutils' # R
  depends_on 'zlibpkg' # R
  # depends_on 'tcl' # Needed for tkinter support
  # depends_on 'tk'  # Needed for tkinter support

  def self.patch
    system "sed -i -e 's:#{CREW_LIB_PREFIX}:\$(get_libdir):g' \
		Lib/distutils/command/install.py \
		Lib/distutils/sysconfig.py \
		Lib/site.py \
		Lib/sysconfig.py \
		Lib/test/test_site.py \
		Makefile.pre.in \
		Modules/getpath.c \
		setup.py"
  end

  def self.prebuild
    # Ensure that internal copies of expat, libffi and zlib aren't used
    FileUtils.rm_rf 'Modules/expat'
    FileUtils.rm_rf Dir.glob('Modules/_ctypes/libffi*')
    FileUtils.rm_rf 'Modules/zlib'
  end

  def self.build
    @cppflags = "-I#{CREW_PREFIX}/include/ncursesw"
    # python requires /usr/local/lib, so leave as is but specify -rpath
    @ldflags = "-Wl,-rpath,-L#{CREW_LIB_PREFIX}"

    # CREW_ENV_OPTIONS don't work so we have to make our own
    @py_common_flags = "'-O2 -pipe -fuse-ld=gold -flto-partition=none -ffat-lto-objects -flto'"

    # Using /tmp breaks test_distutils, test_subprocess.
    # Proxy setting breaks test_httpservers, test_ssl,
    # test_urllib, test_urllib2, test_urllib2_localnet.
    # So, modifying environment variable to make pass tests.

    system 'autoreconf -fiv'
    Dir.mkdir 'builddir'
    Dir.chdir 'builddir' do
      system "env OPT='-g0' CFLAGS=#{@py_common_flags} CXXFLAGS=#{@py_common_flags} \
        CC='#{CREW_TGT}-gcc -pthread' \
        CXX='#{CREW_TGT}-g++' \
        CPPFLAGS='#{@cppflags}' \
        LDFLAGS='#{@ldflags}' \
      ../configure #{CREW_OPTIONS} \
        --with-computed-gotos \
        --enable-loadable-sqlite-extensions \
        --without-ensurepip \
        --enable-optimizations \
        --with-platlibdir='lib#{CREW_LIB_SUFFIX}' \
        --with-system-ffi \
        --with-system-expat \
        --with-system-libmpdec \
        --with-libc= \
        --enable-shared"
      system 'make'
    end
  end

  def self.check
    # Chromebook doesn't allow SIGHUP, so disable SIGHUP test
    system 'sed', '-i', 'Lib/test/test_asyncio/test_events.py', '-e', "/Don't have SIGHUP/s/win32/linux/"
    system 'sed', '-i', 'Lib/test/test_asyncio/test_subprocess.py', '-e', "/Don't have SIGHUP/s/win32/linux/"

    # Chromebook returns EINVAL for F_NOTIFY DN_MULTISHOT, so disable test_fcntl_64_bit
    system 'sed', '-i', 'Lib/test/test_fcntl.py', '-e', '/ARM Linux returns EINVAL for F_NOTIFY DN_MULTISHOT/s/$/\
    @unittest.skipIf(platform.system() == '"'Linux'"', "Chromeos returns EINVAL for F_NOTIFY DN_MULTISHOT")/'

    # imaplib test used to use a kind of security hole on a server in university and the hole is closed now.
    # See https://bugs.python.org/issue30175 and https://github.com/python/cpython/pull/1320/files for details.
    system 'sed', '-i', 'Lib/test/test_imaplib.py',
           '-e', '/test_logincapa_with_client_certfile/i\ \ \ \ @unittest.skipIf(True,\
                     "bpo-30175: FIXME: cyrus.andrew.cmu.edu doesn\'t accept "\
                     "our randomly generated client x509 certificate anymore")',
           '-e', '/test_logincapa_with_client_ssl_context/i\ \ \ \ @unittest.skipIf(True,\
                     "bpo-30175: FIXME: cyrus.andrew.cmu.edu doesn\'t accept "\
                     "our randomly generated client x509 certificate anymore")'

    # Using /tmp breaks test_distutils, test_subprocess
    # Proxy setting breaks test_httpservers, test_ssl,
    # test_urllib, test_urllib2, test_urllib2_localnet
    # system "http_proxy= https_proxy= ftp_proxy= make test"
  end

  def self.install
    Dir.chdir 'builddir' do
      system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
    end

    # Remove conflicting binaries
    FileUtils.rm "#{CREW_DEST_PREFIX}/bin/wheel" if File.exist? "#{CREW_DEST_PREFIX}/bin/wheel"

    # Make python3 the default python
    FileUtils.ln_sf 'python3', "#{CREW_DEST_PREFIX}/bin/python"
  end
end
