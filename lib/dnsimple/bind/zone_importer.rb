require 'dns/zonefile'
require 'dnsimple'
DNSimple::Client.load_credentials

module DNSimple
  module Bind
    class ZoneImporter

      attr_accessor :dryrun, :quiet

      alias :dryrun? :dryrun
      alias :quiet? :quiet
        
      def import(f, name=nil)
        puts "importing from '#{f}'"
        name = extract_name(File.basename(f)) unless name 
        import_from_string(IO.read(f), name)
      end

      def import_from_string(s, name=nil)
        #DNSimple::Domain.debug_output $stdout
        
        zone = DNS::Zonefile.load(s, name)
        puts "origin: #{name}"

        unless dryrun?
          domain = nil
          begin
            domain = DNSimple::Domain.find(name, {})
          rescue => e
            domain = DNSimple::Domain.create(name, {})
          end
          puts "domain name: #{domain.name}"
        end

        zone.records.each do |r|
          begin
            puts "importing #{r.inspect}"
            import_record(domain, r) unless dryrun?
          rescue => e
            puts "Error importing #{r}: #{e.message}"
            puts e.backtrace.join("\n")
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

      def clean_name(n)
        n.gsub(/\.$/, '')
      end

      def import_record(domain, r)
        case r
          when DNS::A then
            puts "A record: #{r.host} -> #{r.address} (ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'A', r.address, :ttl => r.ttl) 
          when DNS::AAAA then
            puts "AAAA record: #{r.host} -> #{r.address} (ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'AAAA', r.address, :ttl => r.ttl)
          when DNS::CNAME then
            puts "CNAME record: #{r.host} -> #{r.domainname} (ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'CNAME', clean_name(r.domainname), :ttl => r.ttl)
          when DNS::NS then
            if host_name(r.host, domain.name).blank?
              puts "Skip NS record for SLD: #{r.host} -> #{r.domainname}"
            else
              puts "NS record: #{r.host} -> #{r.domainname} (ttl: #{r.ttl})"
              DNSimple::Record.create(domain, host_name(r.host, domain.name), 'NS', clean_name(r.domainname), :ttl => r.ttl)
            end
          when DNS::PTR then
            puts "PTR record: #{r.host} -> #{r.domainname} (ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'CNAME', clean_name(r.domainname), :ttl => r.ttl)
          when DNS::MX then
            puts "MX record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'MX', clean_name(r.domainname), :ttl => r.ttl, :prio => r.priority)
          when DNS::TXT then
            puts "TXT record: #{r.host} -> #{r.data} (ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'TXT', r.data, :ttl => r.ttl)
          when DNS::SRV then
            puts "SRV record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, weight: #{r.weight}, port: #{r.port}, ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'SRV', "#{r.weight} #{r.port} #{r.domainname}", :ttl => r.ttl, :prio => r.priority)
          when DNS::NAPTR then
            puts "NAPTR record: #{r.host} -> #{t.data} (ttl: #{r.ttl})"
            DNSimple::Record.create(domain, host_name(r.host, domain.name), 'NAPTR', r.data, :ttl => r.ttl)
          end
      end

    end
  end
end
