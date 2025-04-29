#!/bin/bash

# 定义生成的文件名
NAVBAR_FILE="_navbar.md"
SIDEBAR_FILE="_sidebar.md"
README_FILE="README.md"

# 定义需要忽略的文件夹和文件
IGNORE_DIRS=("assets" "img" "images")
IGNORE_FILES=("_sidebar.md" "_coverpage.md" "_navbar.md" "generate_files.sh" "index.html" "style.css" "README.md")

# 检查是否需要忽略某个文件夹
should_ignore_dir() {
  local dir="$1"
  for ignore_dir in "${IGNORE_DIRS[@]}"; do
    if [[ "$dir" == "$ignore_dir" ]]; then
      return 0
    fi
  done
  return 1
}

# 检查是否需要忽略某个文件
should_ignore_file() {
  local file="$1"
  for ignore_file in "${IGNORE_FILES[@]}"; do
    if [[ "$file" == "$ignore_file" ]]; then
      return 0
    fi
  done
  return 1
}

# 生成 _navbar.md 文件
generate_navbar() {
  # 清空或创建 _navbar.md 文件
  > "$NAVBAR_FILE"

  # 固定内容
  echo "* [首页](/)" >> "$NAVBAR_FILE"
  echo "* [导读](/README.md)" >> "$NAVBAR_FILE"

  # 遍历当前目录（即 docs 文件夹）的一级子目录
  find . -maxdepth 1 -type d ! -path . | while read -r dir; do
    # 获取一级目录名（去掉开头的 ./）
    dir_name=${dir#./}
    # 排除 assets 文件夹
    if [ "$dir_name" == "assets" ]; then
      continue
    fi
    # 输出一级目录
    echo "* $dir_name" >> "$NAVBAR_FILE"
    # 遍历一级目录下的二级子目录
    find "$dir" -maxdepth 1 -type d ! -path "$dir" | while read -r subdir; do
      # 获取二级目录名（去掉一级目录路径）
      subdir_name=${subdir#./$dir_name/}
      # 输出二级目录
      echo "  * [$subdir_name]($subdir/README.md)" >> "$NAVBAR_FILE"
    done
  done

  echo "_navbar.md 文件已生成"
}

# 生成 _sidebar.md 文件
generate_sidebar() {
  local dir="$1"
  local base_path="$2"
  local is_root="$3"

  # 进入目录
  cd "$dir" || return

  # 清空或创建 _sidebar.md 文件
  > "$SIDEBAR_FILE"

  # 如果是主目录，生成一级目录的标题和子目录链接
  if [[ "$is_root" == "true" ]]; then
    for subdir in */; do
      subdir_name=$(basename "$subdir")
      if ! should_ignore_dir "$subdir_name"; then
        echo "* $subdir_name" >> "$SIDEBAR_FILE"
        for subsubdir in "$subdir"*/; do
          subsubdir_name=$(basename "$subsubdir")
          if ! should_ignore_dir "$subsubdir_name"; then
            echo "  * [**$subsubdir_name**](${base_path#/docs}/$subdir_name/$subsubdir_name/README)" >> "$SIDEBAR_FILE"
          fi
        done
      fi
    done
    # 添加固定内容
    echo "* 敬请期待..." >> "$SIDEBAR_FILE"
  else
    # 如果是其他目录，生成当前目录的标题和 .md 文件链接
    echo "* **$(basename "$dir")**" >> "$SIDEBAR_FILE"
    for file in *; do
      if [ -f "$file" ] && ! should_ignore_file "$file" && [[ "$file" != "README.md" ]]; then
        file_name=$(basename "$file" .md)
        echo "  * [$file_name](${base_path#/docs}/$file_name)" >> "$SIDEBAR_FILE"
      fi
    done
  fi

  # 递归处理子目录
  for subdir in */; do
    subdir_name=$(basename "$subdir")
    if [ -d "$subdir" ] && ! should_ignore_dir "$subdir_name"; then
      generate_sidebar "$subdir" "${base_path#/docs}/$subdir_name" "false"
    fi
  done

  # 返回上级目录
  cd ..
}

# 生成 README.md 文件
generate_readme() {
  local dir="$1"
  local base_path="$2"

  # 进入目录
  cd "$dir" || return

  # 生成 README.md 文件
  echo "# $(basename "$dir")" > "$README_FILE"
  for file in *; do
    if [ -f "$file" ] && ! should_ignore_file "$file" && [[ "$file" != "README.md" ]]; then
      file_name=$(basename "$file" .md)
      echo "* [$file_name](${base_path#/docs}/$file_name)" >> "$README_FILE"
    fi
  done

  # 递归处理子目录
  for subdir in */; do
    subdir_name=$(basename "$subdir")
    if [ -d "$subdir" ] && ! should_ignore_dir "$subdir_name"; then
      generate_readme "$subdir" "${base_path#/docs}/$subdir_name"
    fi
  done

  # 返回上级目录
  cd ..
}

# 生成根目录的 README.md 文件
generate_root_readme() {
  cat <<EOF > /Users/cwx/Documents/projects/docsify-notes/docs/README.md
# 导读

cmo的个人博客

该项目用于记录个人学习笔记，有部分内容来自图书、博客、论坛等。

如有侵权等问题，请联系307502005@qq.com，本人会第一时间删除相关内容。

<small>笔记中的图片都来自网络(减小项目文件体积)，如果加载不出来，建议下载该项目到本地阅读</small>

# 目录

$(for dir in $(find /Users/cwx/Documents/projects/docsify-notes/docs -type d -mindepth 1 -maxdepth 1 ! -name "assets"); do
    echo "* **$(basename $dir)**"
    for subdir in $(find $dir -type d -mindepth 1 -maxdepth 1); do
        echo "    * [$(basename $subdir)]($(echo $subdir | sed 's|/Users/cwx/Documents/projects/docsify-notes/docs||g')/README)"
    done
done)
EOF

  echo "README.md generated successfully."
  chmod 644 /Users/cwx/Documents/projects/docsify-notes/docs/README.md
}

# 主函数
main() {
  # 生成 _navbar.md
  generate_navbar

  # 生成 _sidebar.md 和 README.md
  generate_sidebar "." "" "true"
  generate_readme "." ""

  # 生成根目录的 README.md
  generate_root_readme

  echo "所有文件生成完成！"
}

# 执行主函数
main