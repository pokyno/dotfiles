# Turn a list of relative paths into a nested record.
#
# Directories become records keyed by name; files are keys with a null value.
# Pipe to `table -e` to see the nested structure expanded.
#
# Usage:
#   glob **/*.py --exclude [build/** install/** log/**] | path relative-to $env.PWD | tree-view | table -e
#   ls **/*.py | get name | tree-view | table -e
#   ls **/*.py | get name | tree-view | get src.pkgs      # query a subtree
def tree-view []: list<string> -> record {
    def build [items: list<string>] {
        $items
            | group-by { |p| $p | path split | first }
            | transpose name entries
            | sort-by name
            | reduce --fold {} { |row, acc|
                let children = $row.entries
                    | each { |p| $p | path split | skip 1 | path join }
                    | where $it != ""
                let value = if ($children | is-empty) {
                    null
                } else {
                    build $children
                }
                $acc | insert $row.name $value
            }
    }
    build $in
}
