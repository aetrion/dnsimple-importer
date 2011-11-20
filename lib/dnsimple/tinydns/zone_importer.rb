module DNSimple
  module Tinydns
    class ZoneImporter
      def import(f, name=nil)
        puts "importing from '#{f}'"
        name = extract_name(File.basename(f)) unless name
        import_from_string(IO.read(f), name)
      end

      def import_from_string(s, name=nil)
        zone = Tinydns::Zonefile.load(s, name)

        domain = nil
        begin
          domain = DNSimple::Domain.find(name)
        rescue => e
          domain = DNSimple::Domain.create(name) 
        end
        puts "domain name: #{domain.name}"

        zone.records.each do |r|
          begin
            case r
            when Tinydns::A
              puts "A record: #{r.host} -> #{r.address} (ttl: #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'A', r.address, :ttl => r.ttl)
            when Tinydns::CNAME
              puts "CNAME record: #{r.host} -> #{r.domainname} (ttl: #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'CNAME', r.domainname, :ttl => r.ttl
            when Tinydns::MX
              puts "MX record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, ttl: #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'MX', r.domainname, :ttl => r.ttl, :prio => r.priority)
            when DNS::TXT then
              puts "TXT record: #{r.host} -> #{r.data} (ttl: #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'TXT', r.data, :ttl => r.ttl)
            when DNS::SRV then
              puts "SRV record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, content: #{r.content}, ttl: #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'SRV', r.content, :ttl => r.ttl, :prio => r.priority)
            when DNS::NAPTR then
              puts "NAPTR record: #{r.host} -> #{t.data} (ttl: #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'NAPTR', r.content, :ttl => r.ttl)
            end
          rescue DNSimple::RecordExists
            puts "...already exists."
          end
        end
      end

      def extract_name(n)
        n = n.gsub(/\.db/, '')
        n = n.gsub(/\.txt/, '')
      end
    end
  end
end
