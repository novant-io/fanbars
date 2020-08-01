#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "fanbars"
    summary = "Description of this pod"
    version = Version("1.0")
    // These values are optional, but recommended
    // See: https://fantom.org/doc/docLang/Pods#meta
    // meta = [
    //   "org.name":     "My Org",
    //   "org.uri":      "http://myorg.org/",
    //   "proj.name":    "My Project",
    //   "proj.uri":     "http://myproj.org/",
    //   "license.name": "Apache License 2.0",
    //   "vcs.name":     "Git",
    //   "vcs.uri":      "https://github.com/myorg/myproj"
    // ]
    depends = ["sys 1.0"]
    srcDirs = [`fan/`, `test/`]
    // resDirs  = [,]
    // javaDirs = [,]
    // jsDirs   = [,]
    // docApi   = false   // defaults to 'true'
    // docSrc   = true    // defaults to 'false'
  }
}
