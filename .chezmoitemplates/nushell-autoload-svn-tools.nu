def runBranchUpdate [] {
    python build_git.py -c ./projects/mvn.xml --justupdate
}

def update3P [branch] {
    ls -f
        | get name
        | each {|x|
            if (git -C $x show-ref | find $branch | length | $in != 0) {
                git -C $x checkout $branch
            }
        }
}
