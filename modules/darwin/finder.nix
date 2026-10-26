{ username, ... }:
let
  # Sort by Date Modified (newest first) in every view: column view's "Sort
  # By" (StandardViewOptions, four-letter code "modd"), list views'
  # sortColumn, icon and gallery views' arrangeBy, and the toolbar's sort
  # when grouping. Finder keeps these inside nested dicts that also hold
  # column widths and preview settings, and a CustomUserPreferences entry
  # would replace each dict whole, so only these leaves are written.
  # Folders with their own saved view (a .DS_Store from "View Options" in
  # that folder) keep it until it is reset there or removed.
  sortKeys = [
    ":StandardViewOptions:ColumnViewOptions:ArrangeBy string modd"
    ":StandardViewSettings:ListViewSettings:sortColumn string dateModified"
    ":StandardViewSettings:ExtendedListViewSettingsV2:sortColumn string dateModified"
    ":StandardViewSettings:IconViewSettings:arrangeBy string dateModified"
    ":StandardViewSettings:GalleryViewSettings:arrangeBy string dateModified"
    ":FXArrangeGroupViewBy string Date\\ Modified"
  ];
  setSort = builtins.concatStringsSep "\n" (map (k: "set_key ${k}") sortKeys);
in
{
  system.defaults.finder = {
    ShowPathbar = true;
    ShowStatusBar = true;
    FXDefaultSearchScope = "SCcf";
    FXPreferredViewStyle = "clmv";
  };

  # Runs as the user on the exported preferences, so cfprefsd sees the
  # change; Finder restarts only when a value actually changed.
  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- /bin/bash -s <<'EOF' || true
    set -u
    pb=/usr/libexec/PlistBuddy
    dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
    defaults export com.apple.finder "$dir/before.plist"
    cp "$dir/before.plist" "$dir/after.plist"
    set_key() {
      local path=$1 type=$2 value=$3 parent=""
      local IFS=:
      for part in ''${path#:}; do
        [ "$parent:$part" = "$path" ] && break
        parent="$parent:$part"
        $pb -c "Add $parent dict" "$dir/after.plist" 2>/dev/null || true
      done
      $pb -c "Set $path $value" "$dir/after.plist" 2>/dev/null \
        || $pb -c "Add $path $type $value" "$dir/after.plist"
    }
    ${setSort}
    if ! cmp -s <(plutil -convert xml1 -o - "$dir/before.plist") <(plutil -convert xml1 -o - "$dir/after.plist"); then
      defaults import com.apple.finder "$dir/after.plist"
      killall Finder 2>/dev/null || true
    fi
    EOF
  '';
}
