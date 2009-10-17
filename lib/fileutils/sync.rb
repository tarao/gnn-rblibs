require 'file/kind'
require 'dir/each_leaf'
require 'fileutils'

module FileUtils
  class Sync
    def self.each_leaf(src, dst, flag=0, nf=false, block=nil)
      block = Proc.new if block_given?
      if [File.kind(src, nf), File.kind(dst, nf)].all?{|k| k == :directory}
        Dir.children(src, flag) do |file|
          target = File.join(dst, File.basename(file))
          self.each_leaf(file, target, flag, nf, block) # recursive
        end
      else
        block && block.call(src, dst)
      end
    end

    def self.conflict?(src, dst, nofollow=false)
      return File.kind(src, nofollow) != File.kind(dst, nofollow)
    end

    def self.uptodate?(s, d)
      cond = false
      cond ||= !File.exist?(d)
      cond ||= File.file?(s) && File.file?(d) && FileUtils.uptodate?(s, d)
      return cond
    end

    def initialize(opt={})
      @cond = opt[:cond] || {}
      @cond[:conflict] ||= proc{|s,d| self.class.conflict?(s,d)}
      @cond[:uptodate] ||= proc{|s,d| self.class.uptodate?(s,d)}

      @method = opt[:method] || {}
      @method[:conflict] ||= proc{}
      @method[:uptodate] ||= proc do |s, d|
        FileUtils.cp_r(s, d, {:preserve => true})
      end
      @method[:nothing] ||= proc{}

      @flag = opt[:flag] || 0
      @nofollow = opt[:nofollow] || false
    end

    def sync(src, dst)
      self.class.each_leaf(src, dst, @flag, @nofollow) do |s,d|
        none = proc{ :nothing }
        what = [ :conflict, :uptodate ].find(none){|w| @cond[w].call(s, d)}
        @method[what].call(s, d)
      end
    end
  end

  def sync(src, dst, opt={})
    Sync.new(opt).sync(src, dst)
  end

  module_function :sync
end
