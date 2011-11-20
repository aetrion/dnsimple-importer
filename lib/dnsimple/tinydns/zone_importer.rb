require 'dnsimple'
DNSimple::Client.load_credentials

module DNSimple
  module Tinydns
    class ZoneImporter < DNSimple::ZoneImporter
      def import_from_string(s, name=nil)
        zone = Tinydns::Zonefile.load(s, name)
        zone.records.each do |r|
          begin
            case r
            when Tinydns::A
              puts "A record: #{r.host} -> #{r.address} (ttl: #{r.ttl})"
              create_record( r.host, 'A', r.address, :ttl => r.ttl)
            when Tinydns::CNAME
              puts "CNAME record: #{r.host} -> #{r.domainname} (ttl: #{r.ttl})"
              create_record( r.host, 'CNAME', r.domainname, :ttl => r.ttl
            when Tinydns::MX
              puts "MX record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, ttl: #{r.ttl})"
              create_record( r.host, 'MX', r.domainname, :ttl => r.ttl, :prio => r.priority)
            when DNS::TXT then
              puts "TXT record: #{r.host} -> #{r.data} (ttl: #{r.ttl})"
              create_record( r.host, 'TXT', r.data, :ttl => r.ttl)
            when DNS::SRV then
              puts "SRV record: #{r.host} -> #{r.domainname} (prio: #{r.priority}, content: #{r.content}, ttl: #{r.ttl})"
              create_record( r.host, 'SRV', r.content, :ttl => r.ttl, :prio => r.priority)
            when DNS::NAPTR then
              puts "NAPTR record: #{r.host} -> #{t.data} (ttl: #{r.ttl})"
              create_record( r.host, 'NAPTR', r.content, :ttl => r.ttl)
            end
          rescue DNSimple::RecordExists
            puts "...already exists."
          rescue Error => e
            puts "...failed."
            record_failed r, e
          end

          end
        end
      end
    end
  end
end
