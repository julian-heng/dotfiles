#!/usr/bin/env bash

check_app()
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

count()
{
    printf "%s" "$#"
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

    if [[ ! -e "${dir}/st" ]] || (($(count "${dir}/st/"*) == 1)); then
        clone="${dir}/st"
        printf "%s\\n" "Cloning \"git://git.suckless.org/st\" to ${clone}"
    else
        printf -v clone "%s%(%d-%m-%Y-%T)T" "${dir}/st-"
        printf "%s\\n" "Directory is not empty, using ${clone}"
    fi

    git clone git://git.suckless.org/st "${clone}"

    printf "%s\\n" "Copying config"
    cp "${BASH_SOURCE%/*}/config.h" "${clone}"
}

apply_patches()
{
    urls=(
        "https://st.suckless.org/patches/alpha/st-alpha-0.8.1.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-0.8.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.8.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-altscreen-0.8.diff"
    )

    cd "${clone}" || exit 1

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
    clone
    apply_patches
}

main "$@"
