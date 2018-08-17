#!/usr/bin/env bash

check_apps()
{
    app_list=("curl" "patch")

    for i in "${app_list[@]}"; do
        ! type -p "$i" > /dev/null && \
            missing+=("$i")
    done

    ((${#missing[@]} > 0)) && {
        for i in "${missing[@]}"; do
            printf "%s\\n" "Dependency: $i is not installed"
        done
        exit 1
    }
}

check_git_repo_url()
{
    if [[ "$(git -C "$1" config --get remote.origin.url)" == "$2" ]]; then
        return 0
    else
        return 1
    fi
}

clone()
{
    dir="${HOME}/Git"
    printf "%s" "Checking for ${dir}..."

    if [[ ! -e "${dir}" || ! -d "${dir}" ]]; then
        printf "%s\\n" "Does not exist, cloning to ${HOME}"
        dir="${HOME}"
    else
        printf "%s\\n" "OK"
    fi

    if [[ ! -e "${dir}/st" ]]; then
        clone="true"
        clone_dir="${dir}/st"
        printf "%s\\n" "Cloning \"git://git.suckless.org/st\" to ${clone_dir}"
    elif check_git_repo_url "${dir}/st" "git://git.suckless.org/st"; then
        clone="false"
        clone_dir="${dir}/st"
        printf "%s\\n" "Git repo for st already exist"
    else
        clone="true"
        printf -v clone_dir "%s%(%d-%m-%Y-%T)T" "${dir}/st-" "-1"
        printf "%s\\n" "Directory is not empty, using ${clone_dir}"
    fi

    [[ "${clone}" == "true" ]] && \
        git clone git://git.suckless.org/st "${clone_dir}"
}

copy_config()
{
    [[ -e "${clone_dir}/config.h" ]] && {
        printf "%s\\n" "Warning: Config file already exist. Backing up to config.h.bootstrap"
        mv "${clone_dir}/config.h" "${clone_dir}/config.h.bootstrap"
    }

    printf "%s\\n" "Copying config file"
    cp "${BASH_SOURCE%/*}/config.h" "${clone_dir}/config.h"
}

apply_patches()
{
    urls=(
        "https://st.suckless.org/patches/alpha/st-alpha-0.8.1.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-0.8.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.8.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-altscreen-0.8.diff"
    )

    cd "${clone_dir}" || exit 1

    for url in "${urls[@]}"; do
        printf "%s\\n" "Getting ${url}"
        patches+=("$(curl -L "${url}" 2> /dev/null)")
    done

    for patch in "${patches[@]}"; do
        patch -p1 <<< "${patch}"
    done
}

main()
{
    check_apps
    clone
    copy_config
    apply_patches
}

main "$@"
