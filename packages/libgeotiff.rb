require 'package'

class Libgeotiff < Package
  description 'GeoTIFF is based on the TIFF format and is used as an interchange format for georeferenced raster imagery.'
  homepage 'https://github.com/OSGeo/libgeotiff'
  version '1.6.0'
  license 'GPL-2'
  compatibility 'all'
  source_url 'https://github.com/OSGeo/libgeotiff/releases/download/1.6.0/libgeotiff-1.6.0.tar.gz'
  source_sha256 '9311017e5284cffb86f2c7b7a9df1fb5ebcdc61c30468fb2e6bca36e4272ebca'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libgeotiff/1.6.0_armv7l/libgeotiff-1.6.0-chromeos-armv7l.tar.xz',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libgeotiff/1.6.0_armv7l/libgeotiff-1.6.0-chromeos-armv7l.tar.xz',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libgeotiff/1.6.0_i686/libgeotiff-1.6.0-chromeos-i686.tar.xz',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libgeotiff/1.6.0_x86_64/libgeotiff-1.6.0-chromeos-x86_64.tar.xz'
  })
  binary_sha256({
    aarch64: '5c83c9df55eb3c906814e64b05131b53b5bfc9ee6a47b08a1fd36a7973c1c765',
     armv7l: '5c83c9df55eb3c906814e64b05131b53b5bfc9ee6a47b08a1fd36a7973c1c765',
       i686: '6ed77cd71bf90cc71b2b27ebe174f2e0c3ed220432934dc5690e0440a1aa4ddb',
     x86_64: 'cae4083f50f50092b52b2a3856889a8698339f25b1b12aecd4a7f5b09572afca'
  })

  depends_on 'libjpeg'
  depends_on 'proj4'

  def self.build
    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system "cmake -DCMAKE_INSTALL_PREFIX=#{CREW_PREFIX} -DCMAKE_BUILD_TYPE=Release .. && make"
    end
  end

  def self.install
    Dir.chdir 'build' do
      system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
    end
  end
end
