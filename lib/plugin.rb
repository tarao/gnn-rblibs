class Plugin
  @@list = []
  def self.load(dir)
    Dir::glob("#{dir}/*.rb").each do |fname|
      open(fname) do |src|
        begin
          val = instance_eval(src.read.untaint, fname, 1)
          @@list << val if val
          warn("loaded plugin: #{fname}")
        rescue
          warn($!)
        end
      end
    end
  end

  attr_reader :api
  def initialize(args)
    @api = []
    @@list.each do |klass|
      begin
        @api += klass.new(*args).api
      rescue
        warn($!)
      end
    end
  end
end
