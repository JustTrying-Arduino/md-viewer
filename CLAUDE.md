# CLAUDE.md

## Install after every change

After landing any user-facing change to MD Viewer, **always run** `scripts/install.sh` so the app in `/Applications/MD Viewer.app` reflects the latest code. Quit the running app first if needed — the script refuses to overwrite a live process.

```sh
scripts/install.sh
```

The script builds Release, ad-hoc signs, and replaces `/Applications/MD Viewer.app`. No sudo required (the user is in the `admin` group).
