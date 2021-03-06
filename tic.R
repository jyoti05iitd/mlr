get_stage("script") %>%
  add_code_step(RWeka::WPM("refresh-cache")) %>%
  add_code_step(RWeka::WPM('install-package', 'XMeans'))

# R CMD Check
do_package_checks(args = "--as-cran", error_on = "error",
  repos = c(getOption("repos"), remotes::bioc_install_repos()),
  codecov = FALSE)

# pkgdown
if (ci_is_env("FULL", "true")) {
  do_pkgdown(commit_paths = "docs/*", document = FALSE)
}

# only deploy man files in in master branch
if (ci_get_branch() == "master" && ci_is_env("FULL", "true")) {

  get_stage("deploy") %>%
    add_code_step(pkgbuild::compile_dll()) %>%
    add_code_step(devtools::document()) %>%
    add_step(step_push_deploy(commit_paths = c("man/", "DESCRIPTION", "NAMESPACE")))
}
