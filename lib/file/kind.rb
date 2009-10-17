class File
  def self.kind(file, nofollow=false)
    k = [ :directory, :file ]
    k.unshift(:symlink) if nofollow
    return k.find{|w| self.send(w.to_s+'?', file)}
  end
end

