#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "fanbars"
    summary = "Semi-logic-less templates"
    version = Version("0.1")
    meta = [
      "license.name": "MIT",
      "vcs.name":     "Git",
      "vcs.uri":      "https://github.com/afrankvt/fanbars",
      "repo.public":  "true",
      "repo.tags":    "web",
    ]
    depends = ["sys 1.0"]
    srcDirs = [`fan/`, `test/`]
    resDirs = [`doc/`]
    docApi  = true
    docSrc  = true
  }
}
