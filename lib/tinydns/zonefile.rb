module DNSimple
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
      def to_s
        "A record: #{name} -> #{address} (ttl: #{ttl})"
      end
    end
    class CNAME < Record
      def initialize(name, domainname, ttl=3600)
        super(name, domainname, ttl)
      end
      def domainname
        content
      end
      def to_s
        "CNAME record: #{name} -> #{domainname} (ttl: #{ttl})"
      end
    end
    class MX < Record
      attr_reader :priority
      def initialize(name, domainname, ttl=3600, priority=0)
        super(name, domainname, ttl)
        @priority = priority.empty? ? 0 : priority
      end
      def domainname
        content
      end
      def to_s
        "MX record: #{name} -> #{domainname} (prio: #{priority}, ttl: #{ttl})"
      end
    end
    class TXT < Record
      def initialize(name, data, ttl=3600)
        super(name, data, ttl)
      end
      def data
        content
      end
      def to_s
        "TXT record: #{name} -> #{data} (ttl: #{ttl})"
      end
    end
    class SRV < Record
      attr_reader :priority
      def initialize(name, content, ttl=3600, priority=0)
        super(name, content, ttl)
        @priority = priority
      end
      def to_s
        "SRV record: #{name} -> #{domainname} (prio: #{priority}, content: #{content}, ttl: #{ttl})"
      end
    end
    class NAPTR < Record
      def to_s
        "NAPTR record: #{name} -> #{t.data} (ttl: #{ttl})"
      end
    end

    class Zonefile
      def self.load(s, quiet)
        zone = new

        s.split(/\n/).each do |line|
          next if line =~ /^\s*$/
            next if line =~ /^\s*#/
            record = parse_line(line, quiet)
          zone << record if record
        end

        zone
      end

      def self.parse_line(line, quiet)
        case line
        when /^\+([^:]+):([^:]+):?(.*)/ then Tinydns::A.new($1, $2, $3)
        when /^\=([^:]+):([^:]+):?(.*)/ then Tinydns::A.new($1, $2, $3)
        when /^C([^:]+):([^:]+):?(.*)/ then Tinydns::CNAME.new($1, $2, $3)
        when /^@([^:]+):([^:]*):([^:]+):?([^:]*):?([^:]*)/ then Tinydns::MX.new($1, $3, $5, $4)
        when /^\'([^:]+):([^:]+):?(.*)/ then Tinydns::TXT.new($1, $2, $3)
        when /^:([^:]+):33:([^:]+):?([^:]*):?(.*)/ then Tinydns::SRV.new($1, $2, $3, 4)
        when /^:([^:]+):35:([^:]+):?(.*)/ then Tinydns::NAPTR.new($1, $2, $3)
        else
          $stderr.puts "Skipping unsupported record: #{line}" unless quiet
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
end
