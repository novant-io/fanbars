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
    {{/if}

We call it "semi" logic-less because there are some basic control structures
for `if/else` and `each` blocks.  Technically Mustache has these as well, but
its a bit opaque (and confusing) how they get exposed.  So Fanbars goes ahead
and makes them explicit.  This seemed like a good middle ground for what you
need in real projects without adding any "real" logic to templates.

## Syntax

Variable substitution uses the `{{var}}` syntax:

    Hello {{name}}!

If blocks use the `{{#if name}}` syntax, where `name`

TODO: define what "truthy" means

    {{#if isLoggedIn}}
      Hello {{name}}!
    {{/if}}