#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "fanbars"
    summary = "Semi-logic-less templates"
    version = Version("0.12")
    meta = [
      "org.name":     "Novant",
      "org.uri":      "https://novant.io/",
      "license.name": "MIT",
      "vcs.name":     "Git",
      "vcs.uri":      "https://github.com/novant-io/fanbars",
      "repo.public":  "true",
      "repo.tags":    "web",
    ]
    depends = ["sys 1.0", "concurrent 1.0"]
    srcDirs = [`fan/`, `test/`]
    resDirs = [`doc/`]
    docApi  = true
    docSrc  = true
  }
}
