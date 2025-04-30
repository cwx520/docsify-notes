#!/bin/bash

# 设置中文环境以支持拼音排序
export LC_ALL=zh_CN.UTF-8

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
  > "$NAVBAR_FILE"
  echo "* [首页](/)" >> "$NAVBAR_FILE"
  echo "* [导读](/README.md)" >> "$NAVBAR_FILE"

  find . -maxdepth 1 -type d ! -path . -print0 | sort -z | while IFS= read -r -d '' dir; do
    dir_name=${dir#./}
    if should_ignore_dir "$dir_name"; then
      continue
    fi
    echo "* $dir_name" >> "$NAVBAR_FILE"
    find "$dir" -maxdepth 1 -type d ! -path "$dir" -print0 | sort -z | while IFS= read -r -d '' subdir; do
      subdir_name=${subdir#./$dir_name/}
      echo "  * [$subdir_name]($subdir/README.md)" >> "$NAVBAR_FILE"
    done
  done
  echo "_navbar.md 文件已生成"
}

# 生成 _sidebar.md 文件（关键修改点）
generate_sidebar() {
  local dir="$1"
  local base_path="$2"
  local is_root="$3"

  cd "$dir" || return
  > "$SIDEBAR_FILE"

  if [[ "$is_root" == "true" ]]; then
    while IFS= read -r -d '' subdir; do
      subdir_name=$(basename "$subdir")
      if ! should_ignore_dir "$subdir_name"; then
        echo "* $subdir_name" >> "$SIDEBAR_FILE"
        while IFS= read -r -d '' subsubdir; do
          subsubdir_name=$(basename "$subsubdir")
          if ! should_ignore_dir "$subsubdir_name"; then
            echo "  * [**$subsubdir_name**](${base_path#/docs}/$subdir_name/$subsubdir_name/README)" >> "$SIDEBAR_FILE"
          fi
        done < <(find "$subdir" -maxdepth 1 -type d ! -path "$subdir" -print0 | sort -z)
      fi
    done < <(find . -maxdepth 1 -type d ! -path . -print0 | sort -z)
    echo "* 敬请期待..." >> "$SIDEBAR_FILE"
  else
    echo "* **$(basename "$dir")**" >> "$SIDEBAR_FILE"
    while IFS= read -r -d '' file; do
      filename=$(basename "$file")  # 提取纯文件名
      if ! should_ignore_file "$filename" && [[ "$filename" != "README.md" ]]; then
        file_name=$(basename "$file" .md)
        echo "  * [$file_name](${base_path#/docs}/$file_name)" >> "$SIDEBAR_FILE"
      fi
    done < <(find . -maxdepth 1 -type f -name "*.md" -print0 | sort -z)
  fi

  while IFS= read -r -d '' subdir; do
    subdir_name=$(basename "$subdir")
    if ! should_ignore_dir "$subdir_name"; then
      generate_sidebar "$subdir" "${base_path#/docs}/$subdir_name" "false"
    fi
  done < <(find . -maxdepth 1 -type d ! -path . -print0 | sort -z)

  cd ..
}

# 生成 README.md 文件（关键修改点）
generate_readme() {
  local dir="$1"
  local base_path="$2"

  cd "$dir" || return
  echo "# $(basename "$dir")" > "$README_FILE"

  while IFS= read -r -d '' file; do
    filename=$(basename "$file")  # 提取纯文件名
    if ! should_ignore_file "$filename" && [[ "$filename" != "README.md" ]]; then
      file_name=$(basename "$file" .md)
      echo "* [$file_name](${base_path#/docs}/$file_name)" >> "$README_FILE"
    fi
  done < <(find . -maxdepth 1 -type f -name "*.md" -print0 | sort -z)

  while IFS= read -r -d '' subdir; do
    subdir_name=$(basename "$subdir")
    if ! should_ignore_dir "$subdir_name"; then
      generate_readme "$subdir" "${base_path#/docs}/$subdir_name"
    fi
  done < <(find . -maxdepth 1 -type d ! -path . -print0 | sort -z)

  cd ..
}

# 生成根目录的 README.md 文件
generate_root_readme() {
  local root_dir="/Users/cwx/Documents/projects/docsify-notes/docs"
  echo "11111111："+ $root_dir
  cat <<EOF > "$root_dir/README.md"
# 导读

cmo的个人博客

该项目用于记录个人学习笔记，有部分内容来自图书、博客、论坛等。

如有侵权等问题，请联系307502005@qq.com，本人会第一时间删除相关内容。

<small>笔记中的图片都来自网络(减小项目文件体积)，如果加载不出来，建议下载该项目到本地阅读</small>

# 目录

$(while IFS= read -r -d '' dir; do
    dir_name=$(basename "$dir")
    if ! should_ignore_dir "$dir_name"; then
      echo "* **$dir_name**"
      while IFS= read -r -d '' subdir; do
        subdir_name=$(basename "$subdir")
        echo "    * [$subdir_name]($(echo "$subdir" | sed "s|$root_dir||g")/README)"
      done < <(find "$dir" -maxdepth 1 -type d ! -path "$dir" -print0 | sort -z)
    fi
  done < <(find "$root_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z))
EOF

  echo "README.md 文件已生成"
  chmod 644 "$root_dir/README.md"
}

# 主函数
main() {
  generate_navbar
  generate_sidebar "." "" "true"
  generate_readme "." ""
  generate_root_readme
  echo "所有文件生成完成！"
}

# 执行主函数
main