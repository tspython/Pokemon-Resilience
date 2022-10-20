# FOR THE LOVE OF GOD, DON'T TOUCH THIS SCRIPT SECTION
# I HAVE NO IDEA WHAT KIND OF MESS YOU COULD INFLICT UPON YOURSELF

# prevent from existing if running in UPI
if $DEBUG && !FileTest.exist?(Dir.pwd + "/_installer/Scripts.rxdata")
#===============================================================================
# ** Smart Downloader
#  module by Luka S.J.
#
#  Enjoy the script, and make sure to give credit!
#  (DO NOT ALTER THE NAMES OF THE INDIVIDUAL SCRIPT SECTIONS OR YOU WILL BREAK
#   YOUR SYSTEM!)
#-------------------------------------------------------------------------------
# Uses Berka's HTTP script (with modifications)
#===============================================================================
module Downloader
  @@queue = []
  @@filenames = []
  @@string = []
  @@finished = true
  @@index = 0
  @@inQueue = 0
  @@withGraphics = true
  @@output = false
  #-----------------------------------------------------------------------------
  #  Checks if any file is currently being downloaded
  #-----------------------------------------------------------------------------
  def self.downloading?
    return @@queue.length > 0
  end
  #-----------------------------------------------------------------------------
  #  Main module update loop
  #-----------------------------------------------------------------------------
  def self.update(block=nil,*args)
    if !self.downloading?
      @@inQueue = 0
      @@index = 0
      return
    end
    self.startNext if @@finished
    Net::HTTP.loop
    @@finished = Net::HTTP.finished?
    self.finishUp if @@finished
    block.call(*args) if !block.nil? && block.respond_to?(:call)
  end
  #-----------------------------------------------------------------------------
  #  Return the current downloading progress (as a percentage)
  #-----------------------------------------------------------------------------
  def self.progress?
    return 1 if @@inQueue <= 0
    file_progress = Net::HTTP.progress/100.0
    i = @@index - 1; i = 0 if i < 0
    q = @@inQueue - 1; q = 1 if q < 1
    global = i.to_f/q.to_f
    frac = 1.0/q.to_f
    prog = global + file_progress*frac
    return prog
  end
  #-----------------------------------------------------------------------------
  #  Adds file to download queue
  #-----------------------------------------------------------------------------
  def self.download(url, filename, string=false)
    self.createIfNecessary(filename)
    # File.delete(filename) if FileTest.exist?(filename)
    @@queue.push(url)
    @@inQueue += 1
    @@filenames.push(filename)
    @@string.push(string)
  end
  #-----------------------------------------------------------------------------
  #  Creates needed directories if they don't exist
  #-----------------------------------------------------------------------------
  def self.createIfNecessary(filename)
    vals = filename.split('/')
    vals.delete_at(vals.length-1)
    dir = ""
    for val in vals
      dir += "#{val}/"
      Dir.mkdir(dir) if !FileTest.directory?(dir)
    end
  end
  #-----------------------------------------------------------------------------
  #  Packs the downloaded packets into file and removes from queue
  #-----------------------------------------------------------------------------
  def self.finishUp
    @@queue.delete_at(0)
    @@filenames.delete_at(0)
    @@string.delete_at(0)
    @@output = Net::HTTP.conclude
    Net::HTTP.refresh
  end
  #-----------------------------------------------------------------------------
  #  Starts downloading the next file listed in the queue
  #-----------------------------------------------------------------------------
  def self.startNext
    url = @@queue[0]
    filename = @@filenames[0]
    string = @@string[0]
    @@finished = false
    @@index += 1
    Net::HTTP.download(url,filename,string)
  end
  #-----------------------------------------------------------------------------
  #  Stores the last downloaded ret
  #-----------------------------------------------------------------------------
  def self.output?
    return @@output
  end
  #-----------------------------------------------------------------------------
  #  Returns the number of items left to download
  #-----------------------------------------------------------------------------
  def self.items?
    return @@queue.length
  end
  #-----------------------------------------------------------------------------
  #  Lock the downloader from automatic updating with Graphics.update
  #-----------------------------------------------------------------------------
  def self.withGraphics?(val=nil)
    @@withGraphics = val if !val.nil? && val.is_a?(Boolean)
    return @@withGraphics
  end
  #-----------------------------------------------------------------------------
  #  To replace pbDownloadToString
  #-----------------------------------------------------------------------------
  def self.toString(url,block=nil,*args)
    self.download(url,"",true)
    loop do
      Graphics.update
      queue = self.items?
      8.times do
        self.update
        break if queue != self.items?
      end
      block.call(*args) if !block.nil? && block.respond_to?(:call)
      break if !self.downloading?
    end
    return self.output?
  end
  #-----------------------------------------------------------------------------
  #  To replace pbDownloadToFile
  #-----------------------------------------------------------------------------
  def self.toFile(url,file,block=nil,*args)
    self.download(url,file)
    loop do
      Graphics.update
      queue = self.items?
      8.times do
        self.update
        break if queue != self.items?
      end
      block.call(*args) if !block.nil? && block.respond_to?(:call)
      break if !self.downloading?
    end
    return self.output?
  end
end
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#                   Download Files with RGSS
#  by Berka                      v 2.1                  rgss 1
#  [url="http://www.rpgmakervx-fr.com&nbsp;&nbsp;"]http://www.rpgmakervx-fr.com&nbsp;&nbsp;[/url]                                     
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# thanks to: [url="http://www.66rpg.com"]http://www.66rpg.com[/url] for documentation on wininet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Error messages
#-------------------------------------------------------------------------------
module Berka
  module NetError
    ErrConIn="Unable to connect to Internet"
    ErrConFtp="Unable to connect to Ftp"
    ErrConHttp="Unable to connect to the Server"
    ErrNoFFtpIn="The file to be downloadeded doesn't exist"
    ErrNoFFtpEx="The file to be upload doesn't exist"
    ErrTranHttp="Http Download failed"
    ErrDownFtp="Ftp Download  failed"
    ErrUpFtp="Ftp Upload failed"
    ErrNoFile="No file to be downloaded"
    ErrMkdir="Unable to create a new directory"
  end
end
#-------------------------------------------------------------------------------
# Net::HTTP module for use with the above downloader module
#-------------------------------------------------------------------------------
module Net
  W = 'wininet'
  SPC = Win32API.new('kernel32','SetPriorityClass','pi','i').call(-1,128)
  IOA = Win32API.new(W,'InternetOpenA','plppl','l').call('',0,'','',0)
  IC = Win32API.new(W,'InternetConnectA','lplpplll','l')
  raise Berka::NetErrorErr::ConIn if IOA == 0
  module HTTP
     #--------------------------------------------------------------------------
     #  Win32API calls for processing
     #--------------------------------------------------------------------------
     IOU = Win32API.new(W,'InternetOpenUrl','lppllp','l')
     IRF = Win32API.new(W,'InternetReadFile','lpip','l')
     ICH = Win32API.new(W,'InternetCloseHandle','l','l')
     HQI = Win32API.new(W,'HttpQueryInfo','llppp','i')
     module_function
     # Gets the total octets downloaded
     def sizeloaded(i=''); return @read[i]; end
     # Gets the transfered octets
     def transfered; return @dloaded; end
     # Gets fetched packets
     def transfers; return @dls; end
     # Gets progress of the currently fetched file
     def progress
       i = @fich ? @fich : ''
       if !@read[i].nil? && !@size[i].nil?
         return 100 if @size[i] <= 0
         return @read[i].to_f/@size[i]*100
       end
     return 0
     end
     # Checks if file is loaded
     def loaded?(i=''); return @read[i] >= @size[i] rescue nil; end
     # Gets the transfer time
     def temps(i=''); return @tps[i] if loaded?(i); end
     # Gets size of file
     def size(i=''); return @size[i]; end
     # Clears current packets
     def refresh; @dls=[]; end
     #--------------------------------------------------------------------------
     #  Initialization of the download request
     #--------------------------------------------------------------------------
     def download(url,int='./',string=false)
       if url.nil?
         @finished = true
         return false
       end
       @url = url
       @int = int
       @string = string
       @dloaded||= 0
       @dls = [] if !@dls
       @i||= -1
       @size||= {}
       @read||= {}
       @tps = {}
       @a = url.split('/')
       @serv, @root, @fich = @a[2], @a[3..@a.size].join('/'), @a[-1]
       raise Berka::NetErrorErr::ErrNoFile if @fich.nil?
       @dls.push(@fich)
       @txt = ''
       @t = Time.now
       Berka::NetErrorErr::ErrConHttp if IC.call(IOA,@serv,80,'','',3,1,0) == 0  
       @f = IOU.call(IOA,@url,nil,0,0,0)
       @k = "\0"*1024
       HQI.call(@f,5,@k,[@k.size-1].pack('l'),nil)
       @read[@fich] = 0 
       @size[@fich] = @f
       @finished = false
     end
     #--------------------------------------------------------------------------
     #  Main loop for fetching packets
     #--------------------------------------------------------------------------
     def loop
       return if !@txt
       buf, n = ' '*1024, 0
       o = [n].pack('i!')
       r = IRF.call(@f,buf,1024,o)
       n = o.unpack('i!')[0]
       if r&&n == 0
         @finished = true
         return 
       end
       @txt << buf[0,n]
       @read[@fich] = @txt.size
     end
     #--------------------------------------------------------------------------
     #  Check if the current downloading queue is finished
     #--------------------------------------------------------------------------
     def finished?
       return @finished
     end
     #--------------------------------------------------------------------------
     #  Wraps up the packets and concludes downloading process
     #--------------------------------------------------------------------------
     def conclude
       return if !@finished
       return false if !@txt
       ret = ""
       if @string
         ret<<@txt
        else
         (File.open(@int,'wb')<<@txt).close if @txt != ''
         ret = true
       end
       @dloaded += @read[@fich]
       ICH.call(@f)
       sleep(0.01)
       @tps[@fich] = Time.now - @t
       return ret
     end
  end
end

class ::String
  def blank?
    blank = true
    s = self.split("")
    for l in s
      blank = false if l != ""
    end
    return blank
  end
end
#==============================================================================
# ** Package Manager
#------------------------------------------------------------------------------
#  main module used as a handler of all the items in the Package Database
#==============================================================================
module PackageManager
  @@package = {}
  @@index = 0
  @@indexes = {}
  @@log = {}
  @@promoted = {}
  @@community = {}
  # adds new package info to module
  def self.add(key,hash)
    @@package[key] = hash
    @@indexes[key] = @@index
    @@index += 1
  end
  # records the plugin as promoted
  def self.promote(key,hash)
    @@promoted[key] = hash
  end
  # adds to the new community section of home
  def self.community(*args)
    if args.length == 2
      @@community[args[0]] = args[1]
    elsif args.length == 1
      return @@community[args[0]]
    else
      return @@community
    end
  end
  # returns numeric index associated with key
  def self.index?(key)
    return @@indexes[key]
  end
  # returns all usable/compatible package keys
  def self.keys
    entries = Array.new(@@package.keys.length)
    for key in @@package.keys
      entries[@@indexes[key]] = key
    end
    entries.compact!
    return entries
  end
  # returns the recorded version of package
  def self.version?(key)
    return @@package[key]["version"]
  end
  # reads from the .dat file containing information about installed packages
  def self.log(key=nil)
    @@log, lset, lcred, lfil = File.loadData
    return nil if key.nil?
    return nil if !@@log.keys.include?(key)
    return @@log[key]
  end
  # checks whether or not the package is installed
  def self.installed?(key)
    return @@log.keys.include?(key)
  end
  # compares plugin versions
  def self.lowerVersion?(v1,v2)
    # converts first string into usable data
    v1 = v1.split(".")
    for i in 0...3
      if !v1[i]
        v1[i] = 0
        next
      end
      v1[i] = v1[i].to_i
    end
    # converts second string into usable data
    v2 = v2.split(".")
    for i in 0...3
      if !v2[i]
        v2[i] = 0
        next
      end
      v2[i] = v2[i].to_i
    end
    lower = false
    # compares first digit
    if v1[0] < v2[0]
      lower = true
    # compares second digit
    elsif v1[1] < v2[1] && v1[0] <= v2[0]
      lower = true
    # compares third digit
    elsif v1[2] < v2[2] && v1[1] <= v2[1] && v1[0] <= v2[0]
      lower = true
    end
    return lower
  end
  # returns the latest version of a plugin
  def self.latestVersion?(key)
    master = Downloader.toString(@@package[key]["master"])
    return self.version?(key) if !master
    lines = master.split("\r\n")
    versions = []
    # parses read data
    for i in 0...lines.length
      line = lines[i].split("#")[0]
	  next if line.nil?
      s = line[/\[.*?\]/]
	  if line.blank?
      elsif !s.nil?
        s.gsub!("[",""); s.gsub!("]","")
        versions.push(s)
      end
    end
    # returns last read version
    return self.version?(key) if versions.length < 1
    return versions[versions.length-1]
  end
  # returns the currently installed version
  def self.currentVersion?(key)
    return self.log(key)
  end
  # checks if plugin is out of date
  def self.outOfDate?(key)
    current = self.currentVersion?(key)
    return false if current.nil?
    return false if !self.installed?(key)
    latest = self.latestVersion?(key)
    # compares the two versions
    return self.lowerVersion?(current,latest)
  end
end
#===============================================================================
# ** Data Handlers
#-------------------------------------------------------------------------------
# Various functions used to locate folders and read folder contents
# (as well as some other things)
#===============================================================================
class File
  #-----------------------------------------------------------------------------
  #  Loads .dat file
  #-----------------------------------------------------------------------------
  def self.loadData
    args = []
    File.open("Data/upi.dat", 'rb') {|f|
      for i in 0...4
        args.push(Marshal.load(f))
      end
    }
    return *args
  end
end

# injects the database into the system
eval(Downloader.toString("https://drive.google.com/uc?export=download&id=0B4Pi8i4pFhL-SldoN2MzWURhWEU"))
update = []
for key in PackageManager.keys
  update.push(key) if PackageManager.outOfDate?(key)
end
# notifies user if plugins are out of date
if update.length > 0
  Kernel.pbMessage("Looks like one or more of your plugins is out of date. Hop into the Universal Plugin Installer to find out more!")
end

# end UPI check
end