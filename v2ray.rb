require 'package'

class V2ray < Package
  description 'A platform for building proxies to bypass network restrictions.'
  homepage 'https://www.v2ray.com/'
  version '{{VERSION}}'
  source_url 'https://github.com/v2ray/v2ray-core/archive/{{VERSION}}.zip'
  source_sha256 '{{SOURCE_SHA256}}'

  binary_url ({
    aarch64: 'https://github.com/{{USER}}/{{REPO}}/releases/download/{{VERSION}}/v2ray-chromeos-aarch64.tar.xz',
    armv7l: 'https://github.com/{{USER}}/{{REPO}}/releases/download/{{VERSION}}/v2ray-chromeos-armv7l.tar.xz',
      i686: 'https://github.com/{{USER}}/{{REPO}}/releases/download/{{VERSION}}/v2ray-chromeos-i686.tar.xz',
    x86_64: 'https://github.com/{{USER}}/{{REPO}}/releases/download/{{VERSION}}/v2ray-chromeos-x86_64.tar.xz',
  })
  binary_sha256 ({
    aarch64: '{{SHA256_AARCH64}}',
    armv7l: '{{SHA256_ARMV7L}}',
      i686: '{{SHA256_I686}}',
    x86_64: '{{SHA256_X86_64}}',
  })

  def self.postinstall
    FileUtils.chmod('u=x,go=x', CREW_PREFIX + '/share/v2ray/v2ray')
    FileUtils.chmod('u=x,go=x', CREW_PREFIX + '/share/v2ray/v2ctl')

    puts
    puts 'To start using v2ray, type `v2ray`.'.lightblue
    puts
    puts 'You can use customer config. about how to use v2ray command, see https://www.v2ray.com/'.lightblue
    puts 'If you want to remove v2ray'.lightblue
    puts
    puts 'crew remove v2ray'.lightblue
    puts
  end

end
