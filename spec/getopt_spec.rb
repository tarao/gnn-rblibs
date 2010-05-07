require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/getopt')

describe GetOpt, 'when neither argument nor spec is given' do
  before do
    @argv = GetOpt.new([])
  end

  it 'should be empty' do
    @argv.args.should be_empty
    @argv.rest.should be_empty
    @argv[:arg].should be_nil
  end

  after do
    @argv = nil
  end
end

describe GetOpt, 'when bool arguments are given' do
  before do
    @argv = GetOpt.new(%w'
      --hoge=true
      --foo
      --no-bar
      --tarao=3
      -xyz
      -vvv
    ', %w'
      hoge
      foo
      bar
      tarao
      x|xflag
      y|yflag
      v|vlevel
    ')
  end

  it 'should be accessible by string or symbol' do
    @argv[:hoge].should === @argv['hoge']
    @argv[:foo].should === @argv['foo']
    @argv[:bar].should === @argv['bar']
    @argv[:tarao].should === @argv['tarao']
    @argv[:xflag].should === @argv['xflag']
    @argv[:yflag].should === @argv['yflag']
    @argv[:vlevel].should === @argv['vlevel']
  end

  it 'should have flags on' do
    @argv[:hoge].should == true
    @argv[:foo].should == true
    @argv[:xflag].should == true
    @argv[:yflag].should == true
    @argv[:vlevel].should_not be_nil
  end

  it 'should accept value as boolean' do
    @argv[:tarao].should == true
  end

  it 'should have flags off' do
    @argv[:bar].should === false
  end

  it 'should ignore flags not in the spec' do
    @argv[:z].should be_nil
    @argv[:zflag].should be_nil
  end

  it 'should store unparsed arguments' do
    @argv.args[0].should == '-z'
  end

  it 'should increment the flag' do
    @argv[:vlevel].should == 3
  end

  after do
    @argv = nil
  end
end

describe GetOpt, 'when integer arguments are given' do
  before do
    @argv = GetOpt.new(%w'
      --hoge=4
      --foo=-5
      -b 100
      --tarao=tarao
      -xy
    ', %w'
      hoge=i
      foo=i
      b|bar=i
      tarao=i
      x|xflag
      y|yvalue=i
    ')
  end

  it 'should accept values' do
    @argv[:hoge].should == 4
    @argv[:foo].should == -5
    @argv[:bar].should == 100
  end

  it 'should accept value as integer' do
    @argv[:tarao].should == 0
  end

  it 'should not accept integer values as a flag' do
    @argv[:yvalue].should be_nil
    @argv.args[0].should == '-y'
  end

  after do
    @argv = nil
  end
end

describe GetOpt, 'when string arguments are given' do
  before do
    @argv = GetOpt.new(%w'
      --hoge=hoge
      -f foo
      --bar=true
      --tarao=3
      -xy
    ', %w'
      hoge=s
      f|foo=s
      bar=s
      tarao=s
      x|xflag
      y|yvalue=s
    ')
  end

  it 'should accept values' do
    @argv[:hoge].should == 'hoge'
    @argv[:foo].should == 'foo'
    @argv[:bar].should == 'true'
    @argv[:tarao].should == '3'
  end

  it 'should not accept string values as a flag' do
    @argv[:yvalue].should be_nil
    @argv.args[0].should == '-y'
  end

  after do
    @argv = nil
  end
end

describe GetOpt, 'when positional arguments are given' do
  before do
    @argv = GetOpt.new(%w'
      -xyw
      --
      file1
      file2
      -x false
      -z
    ', %w'
      x|xflag
      y|yflag
      z|zflag
    ')
  end

  it 'should accept normal arguments' do
    @argv[:xflag].should == true
    @argv[:yflag].should == true
    @argv[:zflag].should be_nil
  end

  it 'should store unparsed arguments' do
    @argv.args[0].should == '-w'
  end

  it 'should accept positional arguments' do
    @argv.rest[0].should == 'file1'
    @argv.rest[1].should == 'file2'
    @argv.rest[2].should == '-x'
    @argv.rest[3].should == 'false'
    @argv.rest[4].should == '-z'
  end

  after do
    @argv = nil
  end
end
