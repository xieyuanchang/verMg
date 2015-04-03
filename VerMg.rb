require 'FileUtils'
require 'zlib' // crc32lib
include Zlib 

FILESPILT = "/"
CRC_FILE_EXTEND = ".crc32"
FIRST_VER = "1.0.0.000"
VER_INFO_DIR ="verInfo"
HISTORY ="history"

FileUtils.mkdir_p VER_INFO_DIR

class VerMg
    def initialize(dirName, *file_extend)
        puts getInfo
        @file_extend = file_extend.collect { |x| "." + x.gsub(/^\./, "") }
        @dirName = dirName.gsub("\\",FILESPILT)
        @cur_VER = FIRST_VER
        @crcMap = {}
        initCrcMap
        @lastVerFile = lastCRC_File
        if !@lastVerFile
            puts "Add Directory:[#{@dirName}] into VerMg."
            writeCrcFile
        end
    end
    
    def update
        if @lastVerFile
            FileUtils.mkdir_p HISTORY
            cur_VER = nextVerNo
            if(compare(lastVerMap) { |updateFile| xcopy(updateFile ,cur_VER)})
                puts "Update VerNo to [#{cur_VER}]"
                writeCrcFile(cur_VER)
            else
                puts "There is not file has been changed. " 
            end
        end
    end
    
    def getInfo()
        return "VerMg :1.0.0.0 2014.10.18 created by xieyuanchang "
    end
    
    def nextVerNo
        lastVer = @lastVerFile
        [VER_INFO_DIR ,FILESPILT ,File::basename(@dirName) ,"_" ,CRC_FILE_EXTEND].each { |x| lastVer = lastVer.gsub(x ,"")}
        lastVer.succ
    end
    
    def initCrcMap(dir = @dirName)
        Dir::glob(dir + FILESPILT + "*").each { |f|
            if File::ftype(f) == "directory"
                initCrcMap(f)
            else
                File.open(f) do |crc_f| 
                    if (@file_extend.size == 0 || @file_extend.index(File::extname(f)))
                        @crcMap[f] =crc32(crc_f.read) 
                    end
                end
            end
        }
    end
    
    def getVerNoCrcFile(verNo="*")
         #example:verInfo/kanri_1.0.0.000.crc32
         #example:verInfo/kanri_*.crc32
        "#{VER_INFO_DIR}#{FILESPILT}#{File::basename(@dirName)}_#{verNo}#{CRC_FILE_EXTEND}"
    end
    
    def writeCrcFile(verNo = FIRST_VER)
        fileWriter = File::new(getVerNoCrcFile(verNo), "w")
        @crcMap = @crcMap.sort
        @crcMap.each do |crc_file ,crc_code|
            fileWriter.write("#{crc_file}=>#{crc_code}\n") 
        end
        fileWriter.close
        fileWriter = nil
    end
    
    def lastVerMap
        map = {}
        fileReader = File::open(@lastVerFile, "r")
        fileReader.each_line do |line|
            data = line.chomp.split("=>")
            map[data[0]] = data[1] if (data.size >= 2)
        end
        return map
    end
    
    def lastCRC_File
        maxCrcFile = nil
        Dir::glob(getVerNoCrcFile).each { |f|
            maxCrcFile = f if !maxCrcFile
            maxCrcFile = f if (f > maxCrcFile)
        }
        return maxCrcFile
    end
    
    def xcopy(copyFile, verNo)
        destFile = copyFile.gsub(@dirName, HISTORY + FILESPILT + File::basename(@dirName) + "_"+ verNo)
        FileUtils.mkdir_p File::dirname(destFile)
        FileUtils.cp(copyFile,destFile)
    end
    
    def compare(lastVerMap)
        changed = false
        @crcMap.each do |crc_file ,crc_code| 
            if (lastVerMap[crc_file].to_s != crc_code.to_s)
                if lastVerMap[crc_file]
                    puts "Changed : #{crc_file} [#{lastVerMap[crc_file]}=>#{crc_code}]" 
                else
                    puts "Added   : #{crc_file} [#{crc_code}]" 
                end
                changed = true
                yield crc_file if block_given?
            end
        end
        return changed
    end
end

ARGV.each do|a| 
    if File::ftype(a) == "directory"
        puts "################################### VerMg[#{a}] START ###################################" 
        verMg = VerMg.new(a)
        #verMg = VerMg.new(a,"txt","class","dll")
        verMg.update
        puts "################################### VerMg[#{a}] END   ###################################" 
    else
        puts "error : #{a} is not a directory."
    end
  
end 
