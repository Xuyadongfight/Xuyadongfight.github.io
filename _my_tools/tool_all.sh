fullpath=$(pwd)
cd $fullpath

filename=$1
echo $filename

shell1=tool_1_chang_image_path.rb
shell2=tool_2_add_liquid_frontmatter.rb
shell3=tool_3_change_file_name.rb

$(./${shell1} ${filename})
$(./${shell2} ${filename})
$(./${shell3} ${filename})
