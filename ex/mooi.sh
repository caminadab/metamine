vt -IBOKd a | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | pr -2 -w180 -e8
