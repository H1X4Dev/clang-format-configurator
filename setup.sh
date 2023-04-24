#!/bin/bash
set -e

#Default options:
useSystemBinaries=y
# Use all online versions OR the list of mandatory versions
useAllOnlineVersions=n
mandatoryVersions=""
buildHead=n
installSystemdService=n

echo "Options for this setup:"

if [[ $useAllOnlineVersions == [Yy] ]]; then
    echo "* Version to add: All"
else
    echo "* Version to add: $mandatoryVersions"
    echo "Note: versions that not found localy will be downloaded"
fi

if [[ $useSystemBinaries == [Yy] ]]; then
    echo "* Use system clang-format versions: YES"
else 
    echo "* Use system clang-format versions: NO"
fi

if [[ $installSystemdService == [Yy] ]]; then
    echo "* Install systemd service for server: YES"
else
    echo "* Install systemd service for server: NO"
fi

while true
do
    read -rp "Do you want to proceed? (Yn)" yn
    case $yn in
        [Nn]* ) exit;;
        [Yy]* ) break;;
        '' ) break;;
    esac
done

formatted_array=""

function tar_flags {
    echo "x$(echo "$1" | sed '
        /\.xz$/c\J
        /\.gz$/c\z
    ')"
}

function generate_source_url_from_version {
    echo "http://llvm.org/releases/$1/cfe-$1.src.tar.xz"
}

function generate_binary_url_from_version {
    local ver
    ver=$1
    template_urls=""
    template_urls+=" http://llvm.org/releases/$ver/clang+llvm-$ver-x86_64-linux-gnu-ubuntu-16.04.tar.xz"
    template_urls+=" http://llvm.org/releases/$ver/clang+llvm-$ver-x86_64-linux-gnu-ubuntu16.04.tar.xz"
    template_urls+=" http://llvm.org/releases/$ver/clang+llvm-$ver-x86_64-linux-gnu-ubuntu-14.04.tar.xz"
    template_urls+=" http://llvm.org/releases/$ver/clang+llvm-$ver-x86_64-linux-gnu-ubuntu14.04.tar.xz"
    template_urls+=" http://llvm.org/releases/$ver/clang+llvm-$ver-x86_64-linux-gnu-debian8.tar.xz"
    set +e
    for url in $template_urls
    do
        wget -q --spider "$url"
        result=$?
        if [ $result -eq 0 ]; then
            echo "$url"
            break
        fi
    done
    set -e
}

function generate_default_options_list {
    local version
    local listOfBaseStyles
    version=$1
    listOfBaseStyles=$(echo -n "$($2 "$version.src/docs/ClangFormatStyleOptions.rst")")
    jsFilename="${version}.src/docs/defaults.js"
    echo "{" > "$jsFilename"
    for style in $listOfBaseStyles
    do
        echo "\"${style}\" : " >> "$jsFilename"
        "${version}/bin/clang-format" -style="$style" -dump-config > "${version}.src/docs/${style}.yaml"
        $yaml_parser "${version}.src/docs/${style}.yaml" >> "$jsFilename"
        echo "," >> "$jsFilename"
        rm -f "${version}.src/docs/${style}.yaml"
    done
    #removing last ,
    sed -i '$ d' "$jsFilename"
    echo "}" >> "$jsFilename"
}

yaml_parser="$PWD/node_modules/js-yaml/bin/js-yaml.js"
parser_awk="$PWD/parser.awk"

pushd server/llvm

#filling local list only if usage enabled
local_versions=""
if [[ $useSystemBinaries == [Yy] ]]; then
    #get all installed binaries of clang-format and skip not existing directories warnings
    clang_local_binaries=$(echo -n "$(find {,/usr}/{,s}bin/clang-format{,-[0-9]*} 2>/dev/null)")
    for clang_bin in $clang_local_binaries
    do
        version=$(${clang_bin} --version | sed 's/.*version \([^ -]*\).*/\1/')
        local_versions+="$version\n"
        #echo "Found local version: $version - ${clang_bin}"
        formatted_array+=" ${version},$(generate_source_url_from_version "${version}"),${clang_bin}"
    done

    echo "Found local versions"
    echo -e "$local_versions" | column -c 50
    local_versions=$(echo -e "$local_versions")
fi

versionsToGenerate=""
if [[ $useAllOnlineVersions == [Yy] ]]; then
    page_content=$(curl http://releases.llvm.org --compressed --silent)
    online_versions=$(echo "$page_content" | grep -Po "['[0-9]+.*,\s+'[0-9\.]+']" | grep -Po "(([0-9]\.)+([0-9]))")

    echo "Found versions on website:"
    echo "$online_versions" | column -c 50

    versionsToGenerate=$online_versions
else
    versionsToGenerate=$mandatoryVersions
fi

echo "Getting binary links"
for normal_version in $versionsToGenerate
do
    min_version=3.5.2
    if (echo -e "$normal_version\n$min_version" | sort -V -C); then
        echo "Version $normal_version is too old to handle automatically, skipping."
        continue
    fi

    if [ -d "$normal_version" ] && [ -d "$normal_version.src" ]; then
        echo "Already installed $normal_version, skipping."
        continue
    fi

    echo "$normal_version... "

    #adding online version if only not in local list
    if [ "${local_versions/$normal_version}" = "$local_versions" ]; then
        # shellcheck disable=SC2086
        formatted_array+=" $normal_version,$(generate_source_url_from_version $normal_version),$(generate_binary_url_from_version $normal_version)"       
    fi
done

for tuple in $formatted_array
do
    IFS=","
    # shellcheck disable=SC2086
    set $tuple
    version=$1
    source_url="https://raw.githubusercontent.com/llvm/llvm-project/release/15.x/clang/docs/ClangFormatStyleOptions.rst"
    binary_url=$3
    #Checking urls
    echo "checking $source_url"
    set +e
    wget -q --spider "$source_url"
    result=$?
    if [ $result -ne 0 ]; then
        echo "Wrong source url for version $version. Skipping"
        continue
    fi
    if [ ! -f "$binary_url" ]; then
        wget -q --spider "$binary_url"
        result=$?
        if [ $result -ne 0 ]; then
            echo "Wrong binary url for version $version. Skipping"
            continue
        fi
    fi
    set -e
    #end of check

    if [ ! -d "$version" ]; then
        mkdir "$version"
        if [ -f "$binary_url" ]; then
                echo "Creating symlink $version"
                mkdir -p "$version/bin"
                ln -s "$binary_url" "$version/bin/clang-format"
        else
                echo "cannot setup $version because its not installed on system"
        fi
    fi

    if [ ! -d "$version.src" ]
    #then
        echo "Downloading $version.src"
        mkdir "$version.src"
        mkdir "$version.src/docs"
        cd "$version.src/docs"
        wget "$source_url" --quiet
        cd ../../
        generate_default_options_list "$version" "$parser_awk"
    fi
done

popd

echo "Doing npm install"
npm install

if [[ $installSystemdService == [yY] ]]; then
    install_dir=$(pwd)
    npm_binary=$(which npm)
    config_content=$(cat clang-format-configurator.service)
    config_content="${config_content//%NPM_BINARY_PLACEHOLDER%/$npm_binary}"
    config_content="${config_content//%WORKING_DIRECTORY_PLACEHOLDER%/$install_dir}"
    config_content="${config_content//%USER_PLACEHOLDER%/$USER}"
    echo "$config_content" | sudo tee /etc/systemd/system/clang-format-configurator.service > /dev/null
    sudo chmod 644 /etc/systemd/system/clang-format-configurator.service
    sudo systemctl enable clang-format-configurator
    sudo systemctl restart clang-format-configurator
    echo "Installed systemd service"
fi

echo "Done"
