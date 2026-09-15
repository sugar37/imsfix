#!/system/bin/sh
# These are the exact overrides used in the upstream commit
# (yumeerin/device_samsung_sm8250-common @ 012117e) to force VoLTE/WFC
# availability independent of carrier provisioning checks.
MODDIR=${0%/*}

resetprop -n persist.dbg.volte_avail_ovr 1
resetprop -n persist.dbg.wfc_avail_ovr 1
resetprop -n persist.dbg.allow_ims_off 1

# Optional: uncomment if VT (video calling) toggle is also desired
# resetprop -n persist.dbg.vt_avail_ovr 1
