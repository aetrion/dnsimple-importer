require 'public_suffix'
require 'dnsimple'
require 'tinydns/zonefile'

DNSimple::Client.load_credentials

module DNSimple
  module Tinydns
    class ZoneImporter
      attr_accessor :dryrun, :quiet

      alias :dryrun? :dryrun
      alias :quiet? :quiet

      def import(f)
        puts "importing from '#{f}'" unless quiet?
        import_from_string(IO.read(f))
      end

      def import_from_string(s)
        zone = Tinydns::Zonefile.load(s, quiet)

        zone.records.each do |r|
          domain = dnsimple_domain(r.name)
          begin
            puts "Importing #{r}" unless quiet?
            import_record(domain, r)
            puts "Created record #{r}"
          rescue DNSimple::RecordExists => e
            puts "Record #{r} exists, skipping" unless quiet?
          rescue => e
            puts "Error importing #{r}: #{e.message}"
            puts e.backtrace.join("\n")
          end
        end
      end

      def dnsimple_domain(name)
        @domains ||= {}

        domain_name = PublicSuffix.parse(name).domain

        domain = @domains[domain_name]
        if (!domain)
          begin
            domain = DNSimple::Domain.find(domain_name)
            puts "Found domain: #{domain.inspect}" unless quiet?
          rescue DNSimple::RecordNotFound => e
            domain = DNSimple::Domain.create(domain_name) unless dryrun?
            puts "Created domain: #{domain.inspect}" unless dryrun?
          end
          @domains[domain_name] = domain
        end

        domain
      end

      def import_record(domain, r)
        case r
        when Tinydns::A
          DNSimple::Record.create(domain, host_name(r.name, domain.name), 'A', r.address, :ttl => r.ttl) unless dryrun?
        when Tinydns::CNAME
          DNSimple::Record.create(domain, host_name(r.name, domain.name), 'CNAME', r.domainname, :ttl => r.ttl) unless dryrun?
        when Tinydns::MX
          DNSimple::Record.create(domain, host_name(r.name, domain.name), 'MX', r.domainname, :ttl => r.ttl, :prio => r.priority) unless dryrun?
        when Tinydns::TXT then
          DNSimple::Record.create(domain, host_name(r.name, domain.name), 'TXT', r.data, :ttl => r.ttl) unless dryrun?
        when Tinydns::SRV then
          DNSimple::Record.create(domain, host_name(r.name, domain.name), 'SRV', r.content, :ttl => r.ttl, :prio => r.priority) unless dryrun?
        when Tinydns::NAPTR then
          DNSimple::Record.create(domain, host_name(r.name, domain.name), 'NAPTR', r.content, :ttl => r.ttl) unless dryrun?
        end
      end

      def host_name(n, d)
        n.gsub(/\.?#{d}\.?/, '')
      end
    end

  end
end
