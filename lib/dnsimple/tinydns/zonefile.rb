module Tinydns
  class Record
    attr_reader :name
    attr_reader :content
    attr_reader :ttl
    def initialize(name, content, ttl=3600)
      @name = name
      @content = content
      if ttl.nil? or ttl == ''
        @ttl = 3600
      else
        @ttl = ttl.to_i
      end
    end
  end
  class A < Record
    def initialize(name, address, ttl=3600)
      super(name, address, ttl) 
    end
    def address
      content
    end
  end
  class CNAME < Record
    def initialize(name, domainname, ttl=3600)
      super(name, domainname, ttl)
    end
    def domainname
      content
    end
  end
  class MX < Record
    attr_reader :priority
    def initialize(name, domainname, ttl=3600, priority=0)
      super(name, domainname, ttl)
      @priority = priority
    end
    def domainname
      content
    end
  end
  class TXT < Record
    def initialize(name, data, ttl=3600)
      super(name, data, ttl)
    end
    def data
      content
    end
  end
  class SRV < Record
    attr_reader :priority
    def initialize(name, content, ttl=3600, priority=0)
      super(name, content, ttl)
      @priority = priority
    end
  end
  class NAPTR < Record
  end

  class Zonefile
    def self.load(s, name)
      zone = new(name)

      s.split(/\n/).each do |line|
        next if line =~ /^\s*$/
        next if line =~ /^\s*#/
        zone << parse_line(line)
      end

      zone
    end

    def self.parse_line(line)
      case line
      when /^\+([^:]+):([^:]+):?(.*)/ then Tinydns::A.new($1, $2, $3) 
      when /^C([^:]+):([^:]+):?(.*)/ then Tinydns::CNAME.new($1, $2, $3)
      when /^@([^:]+):([^:]*):([^:]+):?([^:]*):?([^:]*)/ then Tinydns::MX.new($1, $3, $5, $4)
      when /^\'([^:]+):([^:]+):?(.*)/ then Tinydns::TXT.new($1, $2, $3)
      when /^:([^:]+):33:([^:]+):?([^:]*):?(.*)/ then Tinydns::SRV.new($1, $2, $3, 4)
      when /^:([^:]+):35:([^:]+):?(.*)/ then Tinydns::NAPTR.new($1, $2, $3)
      else
        raise "Unsupported record: #{line}"
      end
    end

    def <<(record)
      records << record
    end

    def records
      @records ||= []
    end
  end
end
