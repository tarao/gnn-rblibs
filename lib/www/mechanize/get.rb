require 'rubygems'
require 'mechanize'
require 'logger'

module WWW
  class Mechanize
    class Method
      attr_accessor :method, :domain, :verbose, :agent, :req

      def initialize(method, conf={}, verbose=nil)
        @method = method
        @domain = @method[:type] + '://' + @method[:domain]
        @verbose = verbose

        # user agent
        logger = conf[:logger] || (conf[:log] && Logger.new(conf[:log]))
        @agent = WWW::Mechanize.new{|a| a.log = logger if logger}
        @agent.ca_file = conf[:ssl_cert] || '/usr/share/ssl/cert.pem'
        @agent.user_agent_alias = conf[:ua_alias] if conf[:ua_alias]
        @agent.user_agent = conf[:ua] if conf[:ua]
        auth = @method[:auth]
        @agent.auth(auth[:user], auth[:pass]) if auth

        # request methods
        psend = proc{|rq,r| do_send(rq,r)}
        @req = {
          :get    => psend,
          :post   => psend,
          :form   => proc{|rq,r| do_form(rq,r)},
          :regexp => proc{|rq,r| do_parse(rq,r)},
        }

        return self
      end

      def do
        warn("#{@method[:name]}: retrieve by #{@method[:type]}") if @verbose
        result = { :obj => {} }

        @method[:requests].each do |req|
          begin
            if req.is_a?(String)
              result = @req[:get].call(req, result)
            elsif req.is_a?(Proc)
              result = req.call(self, req, result)
            elsif req.is_a?(Hash)
              key = @req.keys.find{|k| req.key?(k)}
              raise 'invalid method' unless key
              result = @req[key].call(req, result)
            else
              raise 'unknown method'
            end
          rescue => e
            warn("#{e}: #{req.to_s}") if @verbose
          end
        end

        return result
      end

      def do_send(req, result) # POST / GET
        m = (req.is_a?(Hash) && req[:post]) ? :post : :get
        uri = @domain + (req.is_a?(Hash) ? req[m] : req)
        params = req.is_a?(Hash) ? req[:params] : {}
        warn("#{m} #{uri}") if @verbose
        result[:page] = @agent.send(m.to_s, uri, params || {}) # reflective
        return result
      end

      def do_form(req, result) # form.submit
        raise 'no page at WWW.Mechanize.Method.do_form' unless result[:page]

        name = req[:form]
        f = result[:page].forms.find{|v| v.name == name} if name.is_a?(String)
        f = result[:page].forms[name] if name.is_a?(Integer)
        raise 'failed at WWW.Mechanize.Method.do_form' unless f

        f.action = req[:action] if req[:action]
        f.set_fields(req[:fields])
        warn("submit #{f.action}") if @verbose
        result[:page] = f.submit
        return result
      end

      def do_parse(req, result) # parse
        raise 'no page at WWW.Mechanize.Method.do_parse' unless result[:page]

        if result[:page].body =~ /#{req[:regexp]}/im
          warn("parse #{req[:regexp]}") if @verbose
          if req[:result].is_a?(Hash)
            req[:result].each do |key, val|
              result[:obj][key] = $~[val]
            end
          elsif req[:result].is_a?(String)
            $~.shift if $~.size > 1
            result[:obj][req[:result].to_sym] = $~
          else
            $~.shift if $~.size > 1
            result[:obj] = $~
          end
        else
          raise 'parse failed at WWW.Mechanize.Method.do_parse'
        end

        return result
      end
    end

    def self.get(methods, opt)
      v = opt[:verbose]
      r = opt[:require]
      c = opt[:config]

      result = { :obj => {} }
      methods = [ methods ] unless methods.is_a?(Array)
      methods.each do |val|
        m = Method.new(val, c, v)
        result = m.do
        break if r.all?{|k| result[:obj][k]}
      end

      return result
    end
  end
end
