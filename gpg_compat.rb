require 'rubygems'
require 'gpgme'

# GPG errors on my ubuntu. there is a posting about it already:
# http://www.mail-archive.com/sup-talk@rubyforge.org/msg04459.html
# tweak GPGME for sup compatibility
module GPGME
    class Data
        class << self
            def empty
                self.empty!
            end
        end

        def to_str
            read
        end
    end
end

def GPGME.detach_sign payload, opts
    crypto = GPGME::Crypto.new
    crypto.detach_sign(payload, opts)
end

def GPGME.encrypt recipients, payload, opts
    opts[:recipients] = recipients
    crypto = GPGME::Crypto.new
    crypto.encrypt(payload, opts)
end
