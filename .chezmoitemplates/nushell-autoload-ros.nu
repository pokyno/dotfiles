# ROS 2 from nushell.
#
# ROS only ships setup.bash/.sh/.zsh. scripts/bash-env.nu sources such a file
# in bash and imports the resulting environment (needs only bash + nushell;
# design and tests in ~/Documents/notes/bash-env-nushell-spec.md).

use bash-env.nu

# Load a ROS 2 environment into this shell. A colcon workspace's
# install/setup.bash chains the underlay it was built against, so one call is
# enough; with no workspace the base /opt/ros install is loaded.
def --env source-ros [
    ws?: string  # colcon workspace root, e.g. ~/ros2_ws
    --distro: string = "jazzy"
] {
    let setup = if $ws != null {
        $ws | path expand | path join install setup.bash
    } else {
        $"/opt/ros/($distro)/setup.bash"
    }
    bash-env load $setup
}
