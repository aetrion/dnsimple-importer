require 'dns/zonefile'
require 'dnsimple'
DNSimple::Client.load_credentials

module DNSimple
  module Bind
    class ZoneImporter < DNSimple::ZoneImporter
      def import_from_string(s, name=nil)
        zone = DNS::Zonefile.load(s, name)
        zone.records.each do |r|
          ttl = sanitize_ttl r.ttl
          begin
            case r
            when DNS::A then
              puts "A record: #{r.host} -> #{r.address} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'A', r.address, :ttl => ttl) 
            when DNS::CNAME then
              puts "CNAME record: #{r.host} -> #{r.domainname} (ttl: #{ttl}, orig #{r.ttl})"
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
            when DNS::AAAA then
              puts "AAAA record: #{r.host} -> #{r.address} (ttl: #{ttl}, orig #{r.ttl})"
              DNSimple::Record.create(domain.name, host_name(r.host, domain.name), 'AAAA', r.address, :ttl => ttl)
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
