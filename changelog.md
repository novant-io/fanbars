# Changelog

## Version 0.10 (working)
* Update `pod.fandoc` for `{{#gen}}` and `{{#partial}}` updates

## Version 0.9 (26-Jan-2022)
* Add support for `#gen` generator funcs
* Add support for new `{{#partial}}` syntax (deprecate `{{> }}` syntax)
* Update copyright to Novant LLC

## Version 0.8 (28-Oct-2020)
* Formalize support for leading/trailing whitespace inside `{{ }}`
* Fix var leakage from `#each` loops
* Add support for nested comments

## Version 0.7 (26-Oct-2020)
* Add support for `{{> partials}}`

## Version 0.6 (21-Aug-2020)
* Fix `resolveVar` behavoir with `#each` and `Map[]` lists

## Version 0.5 (19-Aug-2020)
* Add support for `{{!-- comments --}}`

## Version 0.4 (6-Aug-2020)
* Add support for `#ifnot` keyword
* Tweak Renderer to render invalid slot paths as `null`

## Version 0.3 (5-Aug-2020)
* Split into separate compile+render steps so we can cache compiled instances
* Add `pod.fandoc`

## Version 0.2 (4-Aug-2020)
* Fix var substitution to escape text by default
* Add support for unescaped var substitution using `{{{`

## Version 0.1 (3-Aug-2020)
* Initial MVP