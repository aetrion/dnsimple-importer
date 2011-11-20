require 'dns/zonefile'
require 'dnsimple'
DNSimple::Client.load_credentials

module DNSimple
  module Bind
    class ZoneImporter
      def import(f, name=nil)
        puts "importing from '#{f}'"
        name = extract_name(File.basename(f)) unless name 
        import_from_string(IO.read(f), name)
      end

      def import_from_string(s, name=nil)
        DNSimple::Domain.debug_output $stdout if ENV['DNSSIMPLE_DEBUG']
        
        zone = DNS::Zonefile.load(s, name)
        puts "origin: #{name}"

        domain = nil
        begin
          domain = DNSimple::Domain.find(name)
        rescue => e
          domain = DNSimple::Domain.create(name) 
        end
        puts "domain name: #{domain.name}"
        
        failed_records = []

        zone.records.each do |r|
          ttl = dnsimple_ttl r.ttl
          begin
            case r
            when DNS::A then
              puts "A record: #{r.host} -> #{r.address} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'A', r.address, :ttl => ttl) 
            when DNS::AAAA then
              puts "AAAA record: #{r.host} -> #{r.address} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'AAAA', r.address, :ttl => ttl)
            when DNS::CNAME then
              puts "CNAME record: #{r.host} -> #{r.domainname} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'CNAME', r.domainname, :ttl => ttl)
            when DNS::NS then
              if host_name(r.host, domain.name).blank?
                puts "Skip NS record for SLD: #{r.host} -> #{r.domainname}"
              else
                puts "NS record: #{r.host} -> #{r.domainname} (ttl: #{ttl}, orig #{r.ttl})"
                DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'NS', r.domainname, :ttl => ttl)
              end
            when DNS::PTR then
              puts "PTR record: #{r.host} -> #{r.domainname} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'CNAME', r.domainname, :ttl => ttl)
            when DNS::MX then
              puts "MX record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'MX', r.domainname, :ttl => ttl, :prio => r.priority)
            when DNS::TXT then
              puts "TXT record: #{r.host} -> #{r.data} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'TXT', r.data, :ttl => ttl)
            when DNS::SRV then
              puts "SRV record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, weight: #{r.weight}, port: #{r.port}, ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'SRV', "#{r.weight} #{r.port} #{r.domainname}", :ttl => ttl, :prio => r.priority)
            when DNS::NAPTR then
              puts "NAPTR record: #{r.host} -> #{t.data} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'NAPTR', r.data, :ttl => ttl)
            end
          rescue DNSimple::RecordExists => e
              puts "...already exists."
          rescue Error => e
            failed_records << {:error => e, :record => r}
          end

        end
        if not failed_records.empty?
          puts "Some records could not be processed:"
          failed_records.each do |record|
            r = record[:record]
            puts "#{r.host} #{r.class} #{r.address if r.respond_to?(:address)} #{r.domainname if r.respond_to?(:domainname)} -> #{record[:error]}"
          end
        end
      end

      def host_name(n, d)
        n.gsub(/\.?#{d}\.?/, '')
      end

      def extract_name(n)
        n = n.gsub(/\.db/, '')
        n = n.gsub(/\.txt/, '')
      end
      
      VALID_TTLS = [60, 600, 3600, 86400]
      def dnsimple_ttl ttl
        VALID_TTLS.detect {|a| a >= ttl} || VALID_TTLS.last
      end
        
    end
  end
end
