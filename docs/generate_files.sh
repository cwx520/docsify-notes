#!/bin/bash

# 定义生成的文件名
SIDEBAR_FILE="_sidebar.md"
README_FILE="README.md"
NAVBAR_FILE="_navbar.md"

# 清空或创建文件
> "$SIDEBAR_FILE"
> "$README_FILE"
> "$NAVBAR_FILE"

# 生成 _navbar.md 的固定部分
echo "* [导读](/README.md)" >> "$NAVBAR_FILE"
echo "* [首页](/)" >> "$NAVBAR_FILE"
echo "" >> "$NAVBAR_FILE"

# 遍历所有一级目录
for dir in */; do
  dir_name=$(basename "$dir")

  # 生成 _sidebar.md 文件内容
  echo "* $dir_name" >> "$SIDEBAR_FILE"
  for subdir in "$dir"*/; do
    subdir_name=$(basename "$subdir")
    echo "  * [$subdir_name]($dir$subdir_name/README.md)" >> "$SIDEBAR_FILE"
  done

  # 生成 README.md 文件内容
  echo "# $dir_name" > "$dir/README.md"
  echo "这是 $dir_name 的 README 文件。" >> "$dir/README.md"

  # 生成 _navbar.md 文件内容
  echo "* $dir_name" >> "$NAVBAR_FILE"
  for subdir in "$dir"*/; do
    subdir_name=$(basename "$subdir")
    echo "  * [$subdir_name]($dir$subdir_name/README.md)" >> "$NAVBAR_FILE"
  done
done

echo "文件生成完成！"
