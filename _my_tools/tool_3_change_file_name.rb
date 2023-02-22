#!/usr/bin/env ruby
file_path = $*[0]
puts file_path

file_name = File::basename(file_path)
file_dirname = File::dirname(file_path)

puts file_dirname
puts file_name

file_name_new = file_dirname + "/2020-01-01-" + file_name

puts file_name_new

File::rename(file_path,file_name_new)

