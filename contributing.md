# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

asdf plugin test templ https://github.com/tommyo/asdf-templ.git "templ version"
```

Tests are automatically run in GitHub Actions on push and PR.
