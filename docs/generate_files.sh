#!/bin/bash

# 定义生成的文件名
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
            echo "  * [**$subsubdir_name**]($base_path/$subdir_name/$subsubdir_name/README)" >> "$SIDEBAR_FILE"
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
        echo "  * [$file_name]($base_path/$file)" >> "$SIDEBAR_FILE"
      fi
    done
  fi

  # 递归处理子目录
  for subdir in */; do
    subdir_name=$(basename "$subdir")
    if [ -d "$subdir" ] && ! should_ignore_dir "$subdir_name"; then
      generate_sidebar "$subdir" "$base_path/$subdir_name" "false"
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
      echo "* [$file_name]($base_path/$file)" >> "$README_FILE"
    fi
  done

  # 递归处理子目录
  for subdir in */; do
    subdir_name=$(basename "$subdir")
    if [ -d "$subdir" ] && ! should_ignore_dir "$subdir_name"; then
      generate_readme "$subdir" "$base_path/$subdir_name"
    fi
  done

  # 返回上级目录
  cd ..
}

# 从当前目录开始生成文件
generate_sidebar "." "" "true"
generate_readme "." ""

echo "文件生成完成！"
