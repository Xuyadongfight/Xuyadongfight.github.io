#!/usr/bin/env ruby
file_path = $*[0]

aFile = File.new(file_path,"r")
content_origin=""
if aFile
    content_origin = aFile.read
end
aFile.close
    
liquid_title = "---\nlayout: post\ntitle: 标题1\nsubtitle: 副标题1\ncategories: 分类1\ntags: [标签1,标签2]\n---\n"
content_final = liquid_title + content_origin

aFile = File.new(file_path,"w")
if aFile
    aFile.write(content_final)
end
aFile.close

#str_origin = "resources"
#str_new = "/assets/images/resources"
#
#File.open(file_path,"r:utf-8") do |lines|
#    buffer = lines.read.gsub(str_origin,str_new)
#    File.open(file_path,"w"){|l|
#        l.write(buffer)
#    }

#File.open(file_path,"r+") do |lines|
#    line_change_resources = lines.read.gsub!(/resources/,"/assets/images/resources")
#    line_final = line_change_resources.gsub!(/ =.*\)/,")")
#    puts line_final
##    lines.each_line do |line|
##        line_change_resources = line.sub(/resources/,"/assets/images/resources")
##        line_final = line_change_resources.sub(/ =.*\)/,")")
##        puts line
##        puts line_final
##        buffer = lines.read.gsub(line,line_final)
##        File.open(file_path,"w"){|l|
##            l.write(buffer)
##        }
##    end
#end
