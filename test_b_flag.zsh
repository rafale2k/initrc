setopt EXTENDED_GLOB
var='*?[\]<>()|^~#'
echo "${var//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}"
echo "${(b)var}"
