define sshd::sshd_settings ( $settings, $context=undef, $set_comment=true ) {
  include sshd

  validate_bool($set_comment)
  $file = $sshd::sshd_config
  $lens = $sshd::lens
  $joined_settings = join_keys_to_values($settings, ':')

  if ! $context {
    $bcontext="${file}"
  } else {
    $bcontext="${context}"
  }

  do_settings { $joined_settings:
    file        =>  $file,
    bcontext    =>  $bcontext,
    lens        =>  $lens,
    set_comment =>  $set_comment,
  }
}

define do_settings ($file, $bcontext, $lens, $set_comment=true ) {
  $opt_val=split($name,':')
  $option=$opt_val[0]
  $value=$opt_val[1]
  $path_comps=split($option,'/')
  $base_path=$path_comps[0]
  $msg="THIS OPTION ($base_path) IS MANAGED BY PUPPET - DO NOT MODIFY!!"

  if $value and $value != 'undef' {
    augeas { "Insert $option after existing comment":
      incl    =>  "$file",
      context =>  "/files/$bcontext",
      lens    =>  "$lens",
      changes =>  [
                  "defnode node1 #comment[.=~regexp(\"^[ \t]*$base_path.*\")] \"$base_path\"",
                  "ins $base_path after \$node1[1]",
                  "set $option $value",
                  ],
      onlyif  =>  "match $base_path size == 0",
    } ->
    augeas { "Set $option in $file":
      incl    =>  "$file",
      context =>  "/files/$bcontext",
      lens    =>  "$lens",
      changes =>  "set $option $value",
    } 

    if $set_comment {
      augeas { "Set comment for $option in $file":
        incl    =>  "$file",
        context =>  "/files/$bcontext",
        lens    =>  "$lens",
        changes =>  [
                    "ins #comment before $base_path",
                    "set #comment[following-sibling::*[1][label()=\"$base_path\"]] \"$msg\"",
                    ],
        onlyif  =>  "match #comment[.=\"$msg\"] size == 0",
        require =>  Augeas["Insert $option after existing comment"],
      }
    } else {
      augeas { "Remove comment for $option in $file":
        incl    =>  "$file",
        context =>  "/files/$bcontext",
        lens    =>  "$lens",
        changes =>  "rm #comment[.=\"$msg\"]",
      }
    }
  }
}
