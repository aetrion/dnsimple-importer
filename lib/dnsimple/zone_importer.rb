module DNSimple
  class ZoneImporter

    VALID_TTLS = [60, 600, 3600, 86400]

    attr_reader :domain, :failed_records

    def initialize
      @failed_records = []
    end
    
    def sanitize_ttl(ttl)
      VALID_TTLS.detect {|a| a >= ttl} || VALID_TTLS.last
    end
    
    def import(f, name=nil)
      puts "importing from '#{f}'"
      name = extract_name(File.basename(f)) unless name
      puts "origin: #{name}"
      @domain = get_domain name
      puts "domain name: #{@domain.name}"

      DNSimple::Domain.debug_output $stdout if ENV['DNSSIMPLE_DEBUG']
      import_from_string(IO.read(f), name)
    end

    def import_from_string(s, name=nil)
      raise NotImplementedError
    end

    def extract_name(n)
      n = n.gsub(/\.db/, '')
      n = n.gsub(/\.txt/, '')
    end

    def host_name(n, d)
      n.gsub(/\.?#{d}\.?/, '')
    end

    def records_failed?
      !@failed_records.empty?
    end

    def record_failed(record, error)
      @failed_records << {:error => error, :record => record}
    end

    def get_domain(name)
      begin
        domain = DNSimple::Domain.find(name)
      rescue
        domain = DNSimple::Domain.create(name)
      end
      domain
    end
  end
end
