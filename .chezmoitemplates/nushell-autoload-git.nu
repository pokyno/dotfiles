alias gs = git status
alias gd = git diff
alias gp = git pull

def gbc [] {
    let fzfResult = git branch --list --remote
        | parse "{branch}"
        | get branch
        | each { $in | str replace "origin/" "" }
        | where {|in| $in !~ "HEAD -> origin/master"}
        | str trim
        | to text
        | fzf
    if $fzfResult != "" {
        git checkout $fzfResult
    }
}

def git-cat-ref [ref, file = ""] {
    let ref_file = ($ref + ":" + $file)
    let gitResult = git cat-file --textconv $ref_file
    $gitResult | nvim -R
}

def gfs [] {
    let user_ref_input = (input -d "HEAD" "Input ref:")
    let git_ls_tree = git ls-tree -r --name-only $user_ref_input
    let fzf_result = $git_ls_tree | fzf
    git-cat-ref $user_ref_input $fzf_result
}

def --env gl [ref = "HEAD", num = 25] {
    git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD -n $num $ref
        | lines
        | split column "»¦«" commit subject name email date
        | upsert date {|d| $d.date | into datetime}
        | sort-by date
        | reverse
}

def --env gle [ref = "HEAD"] {
    git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD $ref
        | lines
        | split column "»¦«" commit subject name email date
        | upsert date {|d| $d.date | into datetime}
        | sort-by date
        | reverse
        | explore
}
