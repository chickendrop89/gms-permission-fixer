#  GMS Permission fixer
#  Copyright (C) 2025 chickendrop89
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.

SDK_VERSION=$(getprop ro.build.version.sdk)

if [ -z "$SDK_VERSION" ]; 
    then SDK_VERSION=0
fi

ui_print "Fixing GApps permissions"
pm list packages -a | grep "google" | while read -r PKG_LINE; 
    do
        PKG_NAME=$(echo "$PKG_LINE" | cut -d ':' -f 2)
        echo "--- Processing: $PKG_NAME ---"

        if [ "$SDK_VERSION" -ge 34 ]; then
            if pm grant --all-permissions "$PKG_NAME" 2>/dev/null; 
                then ui_print "[SUCCESS] Bulk grant OK"
                else ui_print "[FAIL] Bulk grant failed"
            fi
        else
            PERMISSIONS=$(dumpsys package "$PKG_NAME" | grep "android.permission" | awk '{print $1}')

            if [ -z "$PERMISSIONS" ];
                then ui_print "No perms found"
                continue
            fi

            for PERM in $PERMISSIONS; do
                if echo "$PERM" | grep -q "^android.permission"; 
                    then
                        if pm grant "$PKG_NAME" "$PERM" 2>/dev/null;
                            then ui_print "[GRANTED] $PERM"
                            else ui_print "[SKIP/FAIL] $PERM"
                        fi
                fi
            done
        fi
done

ui_print "Restarting GMS"
am force-stop com.google.android.gms
sleep 5

ui_print "Finished processing all packages."
ui_print
abort "This script will now abort for a native cleanup."
