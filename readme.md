# Fanbars

"Semi" logic-less templates for Fantom inspired by
[Mustache](http://mustache.github.io).

Fanbars can be used for HTML, config files, source code - anything. It works
by expanding tags in a template using values provided in a `Map`.

    {{#if isLoggedIn}}
      Hello, {{username}}!
      <ul>
      {{#each item in cart}}
        <li>{{item.name}} ${{item.price}}</li>
      {{/each}}
      </ul>
    {{/if}}

We call it "semi" logic-less because there are some basic control structures
for `if/else` and `each` blocks.  Technically Mustache has these as well, but
its a bit opaque (and confusing) how they get exposed.  So Fanbars goes ahead
and makes them explicit.  This seemed like a good middle ground for what you
need in real projects without adding any "real" logic to templates.

## API

Input can be a `Str` or `File` instance:

```fantom
Fanbars.render("Hello {{name}}!", ["name":"Bob"], out)
Fanbars.render(file, ["name":"Bob"], out)
```

Output can be streamed to an `OutStream` instance, or return a fully rendered
`Str`:

```fantom
// stream to out
Fanbars.render(template, map, out)

// return as Str
s := Fanbars.renderStr(template, map)
```

## Syntax

Variable substitution uses the `{{var}}` syntax:

    template:
      Hello {{name}}!

    map:
      ["name":"Bob"]

    output:
      Hello Bob!

If blocks use the `{{#if var}}` syntax, where the value of `var` is considered
`false` if its `null` or `false`, everything else is `true`:

    template:
      {{#if isLoggedIn}}
        Hello {{name}}!
      {{/if}}

    map:
      ["isLoggedIn":true, "name":"Bob"]

    output:
      Hello Bob!

Each blocks use the `{{#each v in var}}` syntax, where the value of `v` is
replace with each element in `var`:

    template:
      {{#each v in items}}
        Item #{{v}}
      {{/if}}

    map:
      ["items":[1,2,3]]

    output:
      Item #1
      Item #2
      Item #3