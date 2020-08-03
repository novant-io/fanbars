#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "fanbars"
    summary = "Description of this pod"
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
    docApi  = true
    docSrc  = true
  }
}
